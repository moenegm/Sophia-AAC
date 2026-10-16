import Foundation
import SwiftData

// CloudKit requires defaults, optional relationships, and no unique constraints.
@Model final class ChildProfile {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    @Attribute(.externalStorage) var photo: Data?
    @Relationship(deleteRule: .cascade, inverse: \BoardCategory.profile)
    var categories: [BoardCategory]?

    init(name: String, photo: Data? = nil) {
        self.name = name
        self.photo = photo
    }
    var sortedCategories: [BoardCategory] {
        (categories ?? []).sorted { ($0.position, $0.name) < ($1.position, $1.name) }
    }
    var cards: [CommunicationCard] { sortedCategories.flatMap(\.sortedCards) }
}

@Model final class BoardCategory {
    var id: UUID = UUID()
    var name: String = ""
    var symbol: String = "square.grid.2x2.fill"
    var colorIndex: Int = 0
    var position: Int = 0
    @Attribute(.externalStorage) var photo: Data?
    var profile: ChildProfile?
    @Relationship(deleteRule: .cascade, inverse: \CommunicationCard.category)
    var cards: [CommunicationCard]?

    init(name: String, symbol: String = "square.grid.2x2.fill", colorIndex: Int = 0,
         position: Int = 0, profile: ChildProfile? = nil) {
        self.name = name
        self.symbol = symbol
        self.colorIndex = colorIndex
        self.position = position
        self.profile = profile
    }
    var sortedCards: [CommunicationCard] {
        (cards ?? []).sorted { ($0.position, $0.title) < ($1.position, $1.title) }
    }
}

@Model final class CommunicationCard {
    var id: UUID = UUID()
    var title: String = ""
    var spokenText: String = ""
    var emoji: String = "💬"
    var position: Int = 0
    var isFavorite: Bool = false
    @Attribute(.externalStorage) var photo: Data?
    var category: BoardCategory?

    init(title: String, spokenText: String = "", emoji: String = "💬",
         position: Int = 0, category: BoardCategory? = nil) {
        self.title = title
        self.spokenText = spokenText
        self.emoji = emoji
        self.position = position
        self.category = category
    }
    var phrase: String {
        let custom = spokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? title : custom
    }
}

struct StarterBoard {
    static let groups: [(String, String, [(String, String, String)])] = [
        ("Everyday", "hand.wave.fill", [("Yes", "Yes", "👍"), ("No", "No", "👎"),
            ("Help", "I need help", "🙋"), ("A break", "I need a break", "🌿"),
            ("More", "More, please", "➕"), ("All done", "I am all done", "✅")]),
        ("Food", "fork.knife", [("Apple", "I would like an apple", "🍎"),
            ("Banana", "I would like a banana", "🍌"), ("Toast", "I would like toast", "🍞"),
            ("Pasta", "I would like pasta", "🍝"), ("Snack", "I would like a snack", "🥨"),
            ("Hungry", "I am hungry", "🍽️")]),
        ("Drinks", "drop.fill", [("Water", "I would like water", "💧"),
            ("Milk", "I would like milk", "🥛"), ("Juice", "I would like juice", "🧃")]),
        ("Feelings", "heart.fill", [("Happy", "I feel happy", "😊"),
            ("Sad", "I feel sad", "😢"), ("Tired", "I feel tired", "😴"),
            ("Too loud", "It is too loud", "🎧"), ("Hurt", "Something hurts", "🩹"),
            ("A hug", "I would like a hug", "🫂")]),
        ("Activities", "sun.max.fill", [("Play", "I would like to play", "🧸"),
            ("Outside", "I would like to go outside", "🌳"), ("Read", "I would like to read", "📚"),
            ("Music", "I would like music", "🎵"), ("Draw", "I would like to draw", "🎨"),
            ("Bathroom", "I need the bathroom", "🚽")])
    ]

    @MainActor static func add(to profile: ChildProfile, in context: ModelContext) {
        // Only used on explicit profile creation; never seed automatically after a sync.
        for (index, group) in groups.enumerated() {
            let category = BoardCategory(name: group.0, symbol: group.1,
                                         colorIndex: index, position: index, profile: profile)
            context.insert(category)
            for (position, item) in group.2.enumerated() {
                context.insert(CommunicationCard(title: item.0, spokenText: item.1,
                                                  emoji: item.2, position: position, category: category))
            }
        }
    }
}
