import SwiftUI
import SwiftData
import CloudKit
import UniformTypeIdentifiers

struct ParentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
    @Binding var selectedProfileID: String
    @AppStorage("speechRate") private var speechRate = 0.45
    @AppStorage("speechVoiceIdentifier") private var speechVoiceIdentifier = ""
    @AppStorage("speechLanguage") private var speechLanguage = "en-US"
    @State private var newProfile = false
    @State private var editedProfile: ChildProfile?
    @State private var deletedProfile: ChildProfile?
    @State private var exportDocument: BackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var error: String?
    @State private var cloudStatus = "Checking iCloud…"
    @State private var speech = SpeechController()

    private var cloudEnabled: Bool { Bundle.main.object(forInfoDictionaryKey: "SophiaCloudSyncEnabled") as? String == "YES" }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(profiles) { profile in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(profile.name).font(.headline)
                                Text("\(profile.cards.count) words · \(profile.sortedCategories.count) categories")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedProfileID == profile.id.uuidString || (selectedProfileID.isEmpty && profile.id == profiles.first?.id) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.sophiaTeal)
                            }
                            Menu {
                                Button("Use this board", systemImage: "person.crop.circle") { selectedProfileID = profile.id.uuidString }
                                Button("Edit profile", systemImage: "pencil") { editedProfile = profile }
                                Button("Export backup", systemImage: "square.and.arrow.up") { export(profile) }
                                Button("Delete profile", systemImage: "trash", role: .destructive) { deletedProfile = profile }
                            } label: { Image(systemName: "ellipsis.circle").padding(12) }
                            .accessibilityLabel("Options for \(profile.name)")
                        }
                        NavigationLink("Edit \(profile.name)’s words") { CategoryManager(profile: profile) }
                    }
                    Button("Add a child profile", systemImage: "plus") { newProfile = true }
                        .accessibilityIdentifier("addProfile")
                } header: { Text("Profiles & boards") } footer: {
                    Text("Choose a board in its options menu. Each child has their own words, photos, and favorites.")
                }

                voiceSettings

                Section("Storage & backup") {
                    Label(cloudEnabled ? cloudStatus : "Saved on this iPad", systemImage: cloudEnabled ? "icloud" : "ipad")
                    Text(cloudEnabled
                         ? "Boards are configured to sync privately through the same Apple Account. Changes may take time to appear. Account availability doesn’t confirm that every change has synced."
                         : "iCloud sync isn’t enabled in this development build. Boards are saved locally; a developer needs to configure the Apple team and CloudKit container before sync can be tested.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Restore a board backup", systemImage: "square.and.arrow.down") { importing = true }
                    Text("iCloud sync carries deletions between devices. Export a separate backup from a profile’s options menu. Backup files include photos and names; keep them somewhere private. Restoring adds a new profile.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                pictureCredits

                Section("About Sophia") {
                    Text("An iPad communication board. No Sophia login, ads, or third-party speech service.")
                    Text("For a focused session, you can enable Guided Access in iPad Settings. The parent check only discourages accidental editing; it is not a password lock.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Parent space")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { speech.stop(); dismiss() } } }
            .sheet(isPresented: $newProfile) {
                ProfileEditor { selectedProfileID = $0.id.uuidString }
            }
            .sheet(item: $editedProfile) { ProfileEditor(profile: $0) }
            .confirmationDialog("Delete this profile and all of its words and photos?", isPresented: Binding(
                get: { deletedProfile != nil }, set: { if !$0 { deletedProfile = nil } }), titleVisibility: .visible) {
                    Button("Delete profile", role: .destructive) {
                        guard let profile = deletedProfile else { return }
                        context.delete(profile)
                        do { try context.save(); selectedProfileID = "" }
                        catch { context.rollback(); self.error = "Couldn’t delete this profile." }
                        deletedProfile = nil
                    }
            } message: { Text("If iCloud sync is enabled, this deletion also syncs to your other devices.") }
            .fileExporter(isPresented: $exporting, document: exportDocument, contentType: .json, defaultFilename: "Sophia-board-backup") { result in
                if case .failure = result { error = "The backup couldn’t be exported. Please try again." }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size <= 100_000_000 else { throw BoardBackup.BackupError.tooLarge }
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    guard data.count <= 100_000_000 else { throw BoardBackup.BackupError.tooLarge }
                    let backup = try JSONDecoder().decode(BoardBackup.self, from: data)
                    let profile = try backup.restore(in: context)
                    selectedProfileID = profile.id.uuidString
                } catch { self.error = "Couldn’t restore this backup. \(error.localizedDescription)" }
            }
            .alert("Something needs attention", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
            .task {
                guard cloudEnabled else { return }
                do {
                    switch try await CKContainer.default().accountStatus() {
                    case .available: cloudStatus = "iCloud account available"
                    case .noAccount: cloudStatus = "Sign in to iCloud in iPad Settings"
                    case .restricted: cloudStatus = "iCloud is restricted on this iPad"
                    default: cloudStatus = "iCloud is temporarily unavailable"
                    }
                } catch { cloudStatus = "Couldn’t check iCloud. Local boards remain available." }
            }
            .onChange(of: speechLanguage) { _, _ in speechVoiceIdentifier = ""; speech.stop() }
            .onDisappear { speech.stop() }
        }.tint(.sophiaTeal)
    }
    private var voiceSettings: some View {
        Section("Voice") {
                    Picker("Language", selection: $speechLanguage) {
                        Text("English (US)").tag("en-US")
                        Text("English (UK)").tag("en-GB")
                        Text("Arabic").tag("ar-SA")
                    }
                    NavigationLink {
                        VoicePicker(identifier: $speechVoiceIdentifier, language: speechLanguage, rate: speechRate)
                    } label: {
                        LabeledContent("Voice", value: VoiceOptions.resolve(identifier: speechVoiceIdentifier, language: speechLanguage)?.name ?? "System default")
                    }.accessibilityIdentifier("chooseVoice")
                    HStack {
                        Text("Slower").font(.caption)
                        Slider(value: $speechRate, in: 0.3...0.6, step: 0.025).accessibilityLabel("Speaking speed")
                        Text("Faster").font(.caption)
                    }
                    Button("Try voice", systemImage: "speaker.wave.2") {
                        speech.speak(speechLanguage == "ar-SA" ? "مرحباً" : "Hello. This is my voice.", rate: speechRate, language: speechLanguage, voiceIdentifier: speechVoiceIdentifier)
                    }
                    Text("Open Voice to preview installed voices or find instructions for downloading Enhanced and Premium voices. Labels and spoken words are edited individually; changing the voice does not translate them.")
                        .font(.caption).foregroundStyle(.secondary)
                }
    }
    private var pictureCredits: some View {
        Section("Picture credits") {
                    Text("Mulberry Symbols by Steve Lee, CC BY-SA 4.0. Rendered as small PNG thumbnails for offline use.")
                    Link("Mulberry Symbols", destination: URL(string: "https://mulberrysymbols.org")!)
                    Link("Artwork license and source", destination: URL(string: "https://github.com/mulberrysymbols/mulberry-symbols")!)
                    Text("Custom chicken-wings artwork is included with Sophia. Parents choose which pictures to put on each child’s board.").font(.caption).foregroundStyle(.secondary)
                }
    }
    private func export(_ profile: ChildProfile) {
        do {
            exportDocument = BackupDocument(data: try JSONEncoder().encode(BoardBackup(profile: profile)))
            exporting = true
        } catch { self.error = "Couldn’t prepare the backup." }
    }
}

struct CategoryManager: View {
    @Environment(\.modelContext) private var context
    let profile: ChildProfile
    @State private var adding = false
    @State private var editing: BoardCategory?
    @State private var deleting: BoardCategory?
    @State private var error: String?
    var body: some View {
        List {
            ForEach(profile.sortedCategories) { category in
                NavigationLink { CardManager(category: category) } label: {
                    Label("\(category.name) · \(category.sortedCards.count)", systemImage: category.symbol)
                }
                .swipeActions {
                    Button("Delete", role: .destructive) { deleting = category }
                    Button("Edit") { editing = category }.tint(.sophiaTeal)
                }
                .contextMenu {
                    Button("Edit category") { editing = category }
                    Button("Delete category", role: .destructive) { deleting = category }
                }
            }.onMove { source, destination in
                var categories = profile.sortedCategories
                categories.move(fromOffsets: source, toOffset: destination)
                for (index, category) in categories.enumerated() { category.position = index }
                save()
            }
            Button("Add category", systemImage: "plus") { adding = true }
        }.navigationTitle(profile.name + "’s categories")
            .toolbar { EditButton() }
            .sheet(isPresented: $adding) { CategoryEditor(profile: profile) }
            .sheet(item: $editing) { CategoryEditor(profile: profile, category: $0) }
            .confirmationDialog("Delete this category and its words?", isPresented: Binding(
                get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                    Button("Delete category", role: .destructive) {
                        if let deleting { context.delete(deleting); save() }
                        deleting = nil
                    }
            }
            .alert("Couldn’t save changes", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
    }
    private func save() {
        do { try context.save() } catch { context.rollback(); self.error = "Please try again." }
    }
}

struct CardManager: View {
    @Environment(\.modelContext) private var context
    let category: BoardCategory
    @State private var adding = false
    @State private var editing: CommunicationCard?
    @State private var deleting: CommunicationCard?
    @State private var error = false
    var body: some View {
        List {
            ForEach(category.sortedCards) { card in
                Button { editing = card } label: {
                    HStack {
                        Picture(data: card.photo, emoji: card.emoji, libraryID: card.libraryID).frame(width: 50, height: 50).clipped()
                        VStack(alignment: .leading) {
                            Text(card.title).font(.headline)
                            Text(card.phrase).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if card.isFavorite { Image(systemName: "star.fill") }
                        Image(systemName: "pencil").foregroundStyle(.secondary)
                    }
                }.tint(.primary)
                    .swipeActions { Button("Delete", role: .destructive) { deleting = card } }
                    .contextMenu { Button("Delete word", role: .destructive) { deleting = card } }
            }.onMove { source, destination in
                var cards = category.sortedCards
                cards.move(fromOffsets: source, toOffset: destination)
                for (index, card) in cards.enumerated() { card.position = index }
                save()
            }
            Button("Add word", systemImage: "plus") { adding = true }.accessibilityIdentifier("addWord")
        }.navigationTitle(category.name)
            .toolbar { EditButton() }
            .sheet(isPresented: $adding) { CardEditor(category: category) }
            .sheet(item: $editing) { CardEditor(category: category, card: $0) }
            .confirmationDialog("Delete this word?", isPresented: Binding(
                get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                    Button("Delete word", role: .destructive) {
                        if let deleting { context.delete(deleting); save() }
                        deleting = nil
                    }
            }
            .alert("Couldn’t save changes", isPresented: $error) { Button("OK", role: .cancel) {} }
    }
    private func save() {
        do { try context.save() } catch { context.rollback(); self.error = true }
    }
}
