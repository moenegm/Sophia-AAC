import SwiftUI
import SwiftData

private enum BoardFilter: Hashable { case all, favorites, category(UUID) }
private struct PhrasePart: Identifiable {
    let id = UUID()
    let text: String
    let label: String
}

struct BoardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
    @AppStorage("selectedProfile") private var selectedProfileID = ""
    @AppStorage("speechRate") private var speechRate = 0.45
    @AppStorage("speechVoiceIdentifier") private var speechVoiceIdentifier = ""
    @AppStorage("speechLanguage") private var speechLanguage = "en-US"
    @State private var filter: BoardFilter = .all
    @State private var speech = SpeechController()
    @State private var phrase: [PhrasePart] = []
    @State private var showGate = false
    @State private var parentUnlocked = false
    @State private var showFirstProfile = false
    @State private var highlighted: UUID?
    @State private var columns = NavigationSplitViewVisibility.all
    let isDemo: Bool

    private var profile: ChildProfile? {
        profiles.first { $0.id.uuidString == selectedProfileID } ?? profiles.first
    }
    private var visibleCards: [CommunicationCard] {
        guard let profile else { return [] }
        switch filter {
        case .all: return profile.cards
        case .favorites: return profile.cards.filter(\.isFavorite)
        case .category(let id): return profile.sortedCategories.first { $0.id == id }?.sortedCards ?? []
        }
    }
    private var heading: String {
        switch filter {
        case .all: return "My words"
        case .favorites: return "Favorites"
        case .category(let id): return profile?.sortedCategories.first { $0.id == id }?.name ?? "My words"
        }
    }

    var body: some View {
        Group {
            if let profile {
                NavigationSplitView(columnVisibility: $columns) {
                    sidebar(profile)
                        .navigationSplitViewColumnWidth(min: 235, ideal: 265, max: 300)
                } detail: {
                    board(profile)
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                welcome
            }
        }
        .tint(.sophiaTeal)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showGate, onDismiss: { parentUnlocked = false; resetBoard() }) {
            if parentUnlocked {
                ParentView(selectedProfileID: $selectedProfileID)
            } else {
                ParentGate { parentUnlocked = true }
            }
        }
        .sheet(isPresented: $showFirstProfile) {
            ProfileEditor { created in
                selectedProfileID = created.id.uuidString
                resetBoard()
            }
        }
        .alert("Audio", isPresented: Binding(get: { speech.error != nil }, set: { if !$0 { speech.error = nil } })) {
            Button("OK") { speech.error = nil }
        } message: { Text(speech.error ?? "") }
        .onChange(of: profile?.id) { _, _ in resetBoard() }
        .onChange(of: profile?.cards.map(\.id)) { _, _ in
            // Never retain phrases from cards removed by a parent or another iCloud device.
            phrase = []
            highlighted = nil
            if case .category(let id) = filter,
               !(profile?.sortedCategories.contains { $0.id == id } ?? false) { filter = .all }
        }
    }

    private var welcome: some View {
        ZStack {
            Color.sophiaCanvas.ignoresSafeArea()
            VStack(spacing: 24) {
                BrandMark().scaleEffect(1.5).padding(.bottom, 20)
                Text("A voice for every day.").font(.system(size: 42, weight: .bold, design: .rounded))
                Text("Welcome to Sophia").font(.title2.weight(.medium))
                Text("A picture board made personal. Choose familiar photos,\nadd the words that matter, and tap to speak.")
                    .font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button { showFirstProfile = true } label: {
                    Label("Create a child profile", systemImage: "plus")
                        .font(.headline).padding(.horizontal, 20).padding(.vertical, 12)
                }.buttonStyle(.borderedProminent).accessibilityIdentifier("createFirstProfile")
                Text("No Sophia account needed. Your board stays available offline.")
                    .font(.subheadline).foregroundStyle(.secondary)
                if Bundle.main.object(forInfoDictionaryKey: "SophiaCloudSyncEnabled") as? String == "YES" {
                    Text("Using iCloud already? Allow time for existing profiles to appear before creating another.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            }.padding(40).foregroundStyle(Color.sophiaInk)
        }
    }

    private func sidebar(_ profile: ChildProfile) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                BrandMark()
                VStack(alignment: .leading, spacing: 2) {
                    Text("sophia").font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("A space to be heard").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(.top, 12)
            HStack(spacing: 12) {
                Picture(data: profile.photo, emoji: "🌼")
                    .frame(width: 46, height: 46).background(.white, in: Circle()).clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name).font(.headline).lineLimit(2)
                    Text("My communication board").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.boardTint(0), in: RoundedRectangle(cornerRadius: 20))
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    navRow("All words", symbol: "square.grid.2x2.fill", destination: .all, color: .sophiaTeal)
                    navRow("Favorites", symbol: "star.fill", destination: .favorites, color: .sophiaTeal)
                    Text("CATEGORIES").font(.caption.weight(.semibold)).tracking(1.6)
                        .foregroundStyle(.secondary).padding(.top, 20).padding(.bottom, 4).padding(.leading, 14)
                    ForEach(profile.sortedCategories) { category in
                        navRow(category.name, symbol: category.symbol, destination: .category(category.id),
                               color: .sophiaTeal, photo: category.photo, colorIndex: category.colorIndex)
                    }
                }
            }
            Spacer(minLength: 0)
            if isDemo {
                Label("Preview · sample board", systemImage: "eye")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Button { showGate = true } label: {
                Label("Parent space", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }.accessibilityIdentifier("parentSpace")
        }
        .padding(20).foregroundStyle(Color.sophiaInk)
        .background(Color.sophiaCanvas)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func navRow(_ name: String, symbol: String, destination: BoardFilter,
                        color: Color, photo: Data? = nil, colorIndex: Int = 0) -> some View {
        Button { filter = destination; highlighted = nil } label: {
            HStack(spacing: 13) {
                if let photo, let image = UIImage(data: photo) {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 32, height: 32).clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Color.boardTint(colorIndex), in: RoundedRectangle(cornerRadius: 9))
                }
                Text(name).font(.body.weight(filter == destination ? .bold : .medium)).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if filter == destination { Circle().fill(color).frame(width: 6, height: 6) }
            }.padding(.horizontal, 12).padding(.vertical, 10)
                .background(filter == destination ? Color.white : .clear, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain).accessibilityAddTraits(filter == destination ? .isSelected : [])
    }

    private func board(_ profile: ChildProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("LET’S TALK").font(.caption.weight(.bold)).tracking(2).foregroundStyle(Color.sophiaTeal)
                    Text(heading).font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("Tap a picture to say it out loud.").font(.body).foregroundStyle(.secondary)
                }
                Spacer()
                Button { speech.stop() } label: {
                    Label("Stop voice", systemImage: "stop.circle")
                        .padding(12).background(.white, in: Capsule())
                }.disabled(!speech.isSpeaking).accessibilityIdentifier("stopVoice")
            }.padding(.horizontal, 28).padding(.top, 20).padding(.bottom, 24)

            if visibleCards.isEmpty {
                ContentUnavailableView(filter == .favorites ? "No favorites yet" : "No words here yet",
                    systemImage: filter == .favorites ? "star" : "bubble.left",
                    description: Text("A parent can add pictures and words in Parent space."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 165, maximum: 240), spacing: 18)], spacing: 18) {
                        ForEach(visibleCards) { card in
                            wordCard(card)
                        }
                    }.padding(.horizontal, 28).padding(.bottom, 24)
                }.accessibilityIdentifier("wordGrid")
            }
            phraseBar
        }
        .foregroundStyle(Color.sophiaInk).background(Color.sophiaCanvas)
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Text(profile.name + "’s board").font(.subheadline).foregroundStyle(.secondary)
        } }
    }

    private func wordCard(_ card: CommunicationCard) -> some View {
        Button {
            if phrase.count < 12 { phrase.append(PhrasePart(text: card.phrase, label: card.title)) }
            highlighted = card.id
            speech.speak(card.phrase, rate: speechRate, language: speechLanguage, voiceIdentifier: speechVoiceIdentifier)
        } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Picture(data: card.photo, emoji: card.emoji, libraryID: card.libraryID)
                        .frame(maxWidth: .infinity).frame(height: 133).clipped()
                        .background(Color.boardTint(card.category?.colorIndex ?? 0))
                    if card.isFavorite {
                        Image(systemName: "star.fill").font(.caption).padding(10).foregroundStyle(Color.sophiaTeal)
                    }
                }
                HStack(spacing: 4) {
                    Text(card.title).font(.title3.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.8)
                    Spacer(minLength: 2)
                    Image(systemName: "speaker.wave.2").font(.caption.weight(.medium)).foregroundStyle(Color.sophiaTeal)
                }.frame(minHeight: 58).padding(.horizontal, 16).padding(.vertical, 5).background(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 23))
            .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(highlighted == card.id ? Color.sophiaTeal : .clear, lineWidth: 3))
        }
        .buttonStyle(.plain).accessibilityLabel(card.title).accessibilityHint("Says: \(card.phrase)")
        .accessibilityIdentifier("word-\(card.title)")
    }

    private var phraseBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("My sentence", systemImage: "text.bubble").font(.subheadline.weight(.semibold))
                Spacer()
                Button("Undo", systemImage: "delete.left") { if !phrase.isEmpty { phrase.removeLast() } }
                    .disabled(phrase.isEmpty)
                Button("Clear") { phrase = []; speech.stop(); highlighted = nil }.disabled(phrase.isEmpty)
            }
            HStack(spacing: 16) {
                ScrollView(.horizontal) {
                    HStack {
                        if phrase.isEmpty { Text("Your words will appear here").foregroundStyle(.secondary).padding(.vertical, 12) }
                        ForEach(phrase) { part in
                            Text(part.label).font(.headline).padding(.horizontal, 14).padding(.vertical, 12)
                                .background(Color.sophiaCanvas, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                Button {
                    speech.speak(phrase.map(\.text).joined(separator: ". "), rate: speechRate, language: speechLanguage, voiceIdentifier: speechVoiceIdentifier)
                } label: {
                    Label("Speak", systemImage: "play.fill").font(.headline).padding(.horizontal, 20).padding(.vertical, 13)
                }.buttonStyle(.borderedProminent).disabled(phrase.isEmpty).accessibilityIdentifier("speakSentence")
            }
        }.padding(22).background(.white)
    }

    private func resetBoard() {
        speech.stop(); phrase = []; highlighted = nil; filter = .all
    }
}
