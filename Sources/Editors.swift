import SwiftUI
import SwiftData
import PhotosUI

struct PhotoField: View {
    @Binding var data: Data?
    @State private var selection: PhotosPickerItem?
    @State private var loading = false
    @State private var error: String?
    var body: some View {
        let hasPhoto = data != nil
        VStack(alignment: .leading, spacing: 12) {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Button("Remove photo", role: .destructive) { self.data = nil; selection = nil }
            }
            PhotosPicker(selection: $selection, matching: .images) {
                Label(hasPhoto ? "Change photo" : "Choose a photo", systemImage: "photo")
            }.disabled(loading)
            if loading { ProgressView("Preparing photo…") }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .task(id: selection) {
            guard let selection else { return }
            loading = true
            defer { loading = false }
            do {
                guard let raw = try await selection.loadTransferable(type: Data.self),
                      let original = UIImage(data: raw) else { throw PhotoError.invalid }
                try Task.checkCancellation()
                let size = original.size
                let scale = min(1, 1000 / max(size.width, size.height))
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let image = UIGraphicsImageRenderer(size: CGSize(width: size.width * scale, height: size.height * scale),
                                                     format: format).image { _ in
                    original.draw(in: CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
                }
                guard let compressed = image.jpegData(compressionQuality: 0.8) else { throw PhotoError.invalid }
                data = compressed
                error = nil
            } catch is CancellationError { } catch {
                self.error = "This photo couldn’t be opened. Please choose another."
            }
        }
    }
    private enum PhotoError: Error { case invalid }
}

struct ProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var profile: ChildProfile?
    var onSave: (ChildProfile) -> Void = { _ in }
    @State private var name = ""
    @State private var photo: Data?
    @State private var useStarter = true
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Child profile") {
                    TextField("Name or nickname", text: $name).accessibilityIdentifier("profileName")
                    Text("A nickname is fine. Only add details you want to store.").font(.caption).foregroundStyle(.secondary)
                    PhotoField(data: $photo)
                }
                if profile == nil {
                    Section {
                        Toggle("Include starter words", isOn: $useStarter)
                        Text("Everyday words, food, drinks, feelings, and activities. Customize them at any time.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle(profile == nil ? "New profile" : "Edit profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmed.isEmpty || name.trimmed.count > 60)
                        .accessibilityIdentifier("saveProfile")
                }
            }
        }.onAppear { name = profile?.name ?? ""; photo = profile?.photo }
    }
    private func save() {
        let child = profile ?? ChildProfile(name: name.trimmed)
        if profile == nil { context.insert(child) }
        child.name = name.trimmed
        child.photo = photo
        if profile == nil && useStarter { StarterBoard.add(to: child, in: context) }
        do { try context.save(); onSave(child); dismiss() }
        catch { context.rollback(); self.error = "Couldn’t save the profile. Please try again." }
    }
}

struct CategoryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let profile: ChildProfile
    var category: BoardCategory?
    @State private var name = ""
    @State private var symbol = "square.grid.2x2.fill"
    @State private var colorIndex = 0
    @State private var photo: Data?
    @State private var error: String?
    private let symbols = ["square.grid.2x2.fill", "hand.wave.fill", "fork.knife", "drop.fill", "heart.fill", "sun.max.fill", "house.fill", "leaf.fill", "figure.play", "book.fill"]
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("Name", text: $name)
                    Picker("Icon", selection: $symbol) {
                        ForEach(symbols, id: \.self) { Image(systemName: $0).tag($0) }
                    }
                    Picker("Color", selection: $colorIndex) {
                        ForEach(0..<5) { index in
                            Text(["Sage", "Peach", "Sky", "Rose", "Lavender"][index]).tag(index)
                        }
                    }
                    PhotoField(data: $photo)
                }
                if let error { Text(error).foregroundStyle(.red) }
            }.navigationTitle(category == nil ? "New category" : "Edit category")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let item = category ?? BoardCategory(name: name.trimmed, position: (profile.sortedCategories.map(\.position).max() ?? -1) + 1, profile: profile)
                            if category == nil { context.insert(item) }
                            item.name = name.trimmed; item.symbol = symbol; item.colorIndex = colorIndex; item.photo = photo
                            do { try context.save(); dismiss() }
                            catch { context.rollback(); self.error = "Couldn’t save this category." }
                        }.disabled(name.trimmed.isEmpty || name.trimmed.count > 60)
                    }
                }
        }.onAppear {
            name = category?.name ?? ""; symbol = category?.symbol ?? "square.grid.2x2.fill"
            colorIndex = category?.colorIndex ?? 0; photo = category?.photo
        }
    }
}

struct CardEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let category: BoardCategory
    var card: CommunicationCard?
    @State private var title = ""
    @State private var spokenText = ""
    @State private var emoji = "💬"
    @State private var favorite = false
    @State private var photo: Data?
    @State private var error: String?
    @State private var showLibrary = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Picture card") {
                    TextField("Label", text: $title).accessibilityIdentifier("cardTitle")
                    TextField("Words to speak (optional)", text: $spokenText)
                    Text("Leave words to speak blank to say the label.").font(.caption).foregroundStyle(.secondary)
                    Toggle("Favorite", isOn: $favorite)
                }
                Section {
                    HStack(spacing: 16) {
                        Picture(data: photo, emoji: emoji)
                            .frame(width: 84, height: 84)
                            .background(Color.sophiaCanvas, in: RoundedRectangle(cornerRadius: 16)).clipped()
                            .accessibilityIdentifier("selectedCardPicture")
                        VStack(alignment: .leading, spacing: 5) {
                            Text(photo != nil ? "Your photo" : PictureLibrary.picture(for: emoji)?.name ?? "Custom symbol")
                                .font(.headline).accessibilityIdentifier("selectedPictureName")
                            Text("Changing the label won’t replace your chosen picture.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if !title.trimmed.isEmpty {
                        let suggestions = Array(PictureLibrary.search(title).prefix(6))
                        if !suggestions.isEmpty {
                            Text("Suggested pictures").font(.subheadline.weight(.semibold))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95, maximum: 140), spacing: 8)], spacing: 8) {
                                ForEach(suggestions) { picture in
                                    LibraryPictureButton(picture: picture, selected: photo == nil && emoji == picture.emoji) {
                                        choose(picture)
                                    }
                                }
                            }
                        } else {
                            Text("No matching pictures yet. Browse the library or choose your own photo.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Button("Browse picture library", systemImage: "photo.on.rectangle.angled") { showLibrary = true }
                        .accessibilityIdentifier("browsePictureLibrary")
                    PhotoField(data: $photo)
                    DisclosureGroup("Use another emoji") {
                        TextField("Custom emoji", text: $emoji)
                        Text("Your photo takes priority. Remove it to use the symbol instead.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Picture")
                } footer: {
                    Text("Pictures are included on the iPad and work offline. Suggestions never change the words the card speaks.")
                }
                if let error { Text(error).foregroundStyle(.red) }
            }.navigationTitle(card == nil ? "New word" : "Edit word")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let item = card ?? CommunicationCard(title: title.trimmed, position: (category.sortedCards.map(\.position).max() ?? -1) + 1, category: category)
                            if card == nil { context.insert(item) }
                            item.title = title.trimmed; item.spokenText = spokenText.trimmed
                            item.emoji = String(emoji.prefix(2)); item.photo = photo; item.isFavorite = favorite
                            do { try context.save(); dismiss() }
                            catch { context.rollback(); self.error = "Couldn’t save this word." }
                        }.disabled(title.trimmed.isEmpty || title.trimmed.count > 60 || spokenText.count > 200)
                            .accessibilityIdentifier("saveCard")
                    }
                }
        }.sheet(isPresented: $showLibrary) {
            PictureLibraryView(initialQuery: title.trimmed, selectedSymbol: photo == nil ? emoji : "", onSelect: choose)
        }.onAppear {
            title = card?.title ?? ""; spokenText = card?.spokenText ?? ""
            emoji = card?.emoji ?? "💬"; favorite = card?.isFavorite ?? false; photo = card?.photo
        }
    }
    private func choose(_ picture: LibraryPicture) {
        emoji = picture.emoji
        photo = nil
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
