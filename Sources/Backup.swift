import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BoardBackup: Codable {
    var version = 1
    var name: String
    var photo: Data?
    var sentenceBuilderEnabled: Bool?
    var categories: [Category]
    struct Category: Codable {
        var name: String
        var symbol: String
        var colorIndex: Int
        var photo: Data?
        var cards: [Card]
    }
    struct Card: Codable {
        var title: String
        var spokenText: String
        var libraryID: String?
        var emoji: String
        var isFavorite: Bool
        var photo: Data?
    }
    @MainActor init(profile: ChildProfile) {
        name = profile.name; photo = profile.photo
        sentenceBuilderEnabled = profile.sentenceBuilderEnabled
        categories = profile.sortedCategories.map { category in
            Category(name: category.name, symbol: category.symbol, colorIndex: category.colorIndex,
                     photo: category.photo, cards: category.sortedCards.map {
                Card(title: $0.title, spokenText: $0.spokenText, libraryID: $0.libraryID, emoji: $0.emoji, isFavorite: $0.isFavorite, photo: $0.photo)
            })
        }
    }
    func validate() throws {
        guard version == 1, !name.trimmed.isEmpty, name.count <= 60, categories.count <= 100 else { throw BackupError.invalid }
        let photos = [photo] + categories.flatMap { [$0.photo] + $0.cards.map(\.photo) }
        guard photos.allSatisfy({ ($0?.count ?? 0) <= 5_000_000 }) else { throw BackupError.invalid }
        guard categories.allSatisfy({ !$0.name.trimmed.isEmpty && $0.name.count <= 60 && $0.cards.count <= 500 &&
            $0.cards.allSatisfy { !$0.title.trimmed.isEmpty && $0.title.count <= 60 && $0.spokenText.count <= 200 && $0.emoji.count <= 2 && ($0.libraryID?.count ?? 0) <= 100 }
        }) else { throw BackupError.invalid }
    }
    @MainActor func restore(in context: ModelContext) throws -> ChildProfile {
        try validate()
        // Restore as a new profile. Never overwrite an existing child's board.
        let child = ChildProfile(name: String(name.prefix(49)) + " (restored)", photo: photo)
        child.sentenceBuilderEnabled = sentenceBuilderEnabled ?? true
        context.insert(child)
        for (position, category) in categories.enumerated() {
            let group = BoardCategory(name: category.name, symbol: category.symbol, colorIndex: category.colorIndex,
                                      position: position, profile: child)
            group.photo = category.photo
            context.insert(group)
            for (index, card) in category.cards.enumerated() {
                let item = CommunicationCard(title: card.title, spokenText: card.spokenText, emoji: card.emoji,
                                             position: index, category: group)
                item.libraryID = card.libraryID; item.photo = card.photo; item.isFavorite = card.isFavorite
                context.insert(item)
            }
        }
        do { try context.save(); return child }
        catch { context.rollback(); throw error }
    }
    enum BackupError: LocalizedError {
        case invalid, tooLarge
        var errorDescription: String? {
            switch self {
            case .invalid: return "This isn’t a supported Sophia board backup."
            case .tooLarge: return "This backup is too large to open (maximum 100 MB)."
            }
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
