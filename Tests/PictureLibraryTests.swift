import XCTest
import SwiftData
import UIKit
@testable import SophiaAAC

@MainActor final class PictureLibraryTests: XCTestCase {
    func testSearchFindsLabelsTagsPrefixesAndPhrases() {
        XCTAssertEqual(PictureLibrary.search("APPLE").first?.name, "Apple")
        XCTAssertEqual(PictureLibrary.search("  I want an apple! ").first?.name, "Apple")
        XCTAssertEqual(PictureLibrary.search("appl").first?.name, "Apple")
        XCTAssertTrue(PictureLibrary.search("fruit").contains { $0.name == "Banana" })
        XCTAssertEqual(PictureLibrary.search("تفاح").first?.name, "Apple")
        XCTAssertEqual(PictureLibrary.search("stop").first?.name, "Stop")
        XCTAssertEqual(PictureLibrary.search("apple juice").first?.name, "apple juice")
        XCTAssertFalse(PictureLibrary.search("apple juice").contains { $0.name == "Apple" })
    }
    func testExpandedCatalogAndChickenWings() {
        XCTAssertEqual(PictureLibrary.pictures.count, 3557)
        XCTAssertEqual(PictureLibrary.search("chicken wings").first?.id, "sophia-chicken-wings")
        XCTAssertEqual(PictureLibrary.search("chicken nuggets").first?.name, "chicken nuggets")
        let queries = ["chicken wings", "apple", "I want water", "bathroom", "ball", "school", "please", "unknownword", "happy", "orange juice"]
        _ = PictureLibrary.search("warm up")
        let start = Date.timeIntervalSinceReferenceDate
        for _ in 0..<10 { for query in queries { _ = PictureLibrary.search(query) } }
        let elapsed = Date.timeIntervalSinceReferenceDate - start
        print("Search benchmark: \(elapsed * 10) ms/query averaged over 100 searches across \(PictureLibrary.pictures.count) pictures")
        XCTAssertLessThan(elapsed, 5, "100 indexed searches should remain responsive")
    }
    func testExpandedLibraryBackupAndLegacyCompatibility() throws {
        let db = try ModelContainer(for: ChildProfile.self, BoardCategory.self, CommunicationCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = db.mainContext
        let profile = ChildProfile(name: "Sample"); context.insert(profile)
        let category = BoardCategory(name: "Food", profile: profile); context.insert(category)
        let card = CommunicationCard(title: "Wings", spokenText: "Chicken wings please", category: category)
        card.libraryID = "sophia-chicken-wings"; context.insert(card); try context.save()
        let data = try JSONEncoder().encode(BoardBackup(profile: profile))
        let restored = try JSONDecoder().decode(BoardBackup.self, from: data).restore(in: context)
        XCTAssertEqual(restored.cards.first?.libraryID, card.libraryID)
        XCTAssertNil(restored.cards.first?.photo)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var groups = try XCTUnwrap(legacy["categories"] as? [[String: Any]])
        var cards = try XCTUnwrap(groups[0]["cards"] as? [[String: Any]])
        cards[0].removeValue(forKey: "libraryID"); groups[0]["cards"] = cards; legacy["categories"] = groups
        let old = try JSONDecoder().decode(BoardBackup.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertNil(old.categories.first?.cards.first?.libraryID)
    }
    func testEmptyAndUnknownSearches() {
        XCTAssertEqual(PictureLibrary.search("").count, PictureLibrary.pictures.count)
        XCTAssertTrue(PictureLibrary.search("unicornspaceship").isEmpty)
        XCTAssertTrue(PictureLibrary.search("I would like").isEmpty)
    }
    func testEveryCatalogEntryHasAUniqueIDAndBundledImage() {
        XCTAssertEqual(Set(PictureLibrary.pictures.map(\.id)).count, PictureLibrary.pictures.count)
        for picture in PictureLibrary.pictures {
            XCTAssertNotNil(PictureImageStore.image(for: picture), "Missing asset for \(picture.name)")
        }
    }
    func testLibraryIdentifierPersistsAndRestoresWithoutPhotoData() throws {
        let db = try ModelContainer(for: ChildProfile.self, BoardCategory.self, CommunicationCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = db.mainContext
        let profile = ChildProfile(name: "Sample")
        context.insert(profile)
        let category = BoardCategory(name: "Food", profile: profile)
        context.insert(category)
        let picture = try XCTUnwrap(PictureLibrary.search("carrot").first)
        let card = CommunicationCard(title: "My snack", spokenText: "I want a carrot", emoji: picture.id, category: category)
        context.insert(card)
        try context.save()
        let data = try JSONEncoder().encode(BoardBackup(profile: profile))
        let restored = try JSONDecoder().decode(BoardBackup.self, from: data).restore(in: context)
        let copy = try XCTUnwrap(restored.cards.first)
        XCTAssertEqual(copy.emoji, picture.id)
        XCTAssertNil(copy.photo)
        XCTAssertEqual(copy.phrase, "I want a carrot")
        XCTAssertEqual(PictureLibrary.picture(for: copy.emoji)?.name, "Carrot")
    }
}

@MainActor final class VoiceOptionsTests: XCTestCase {
    func testUnavailableVoiceFallsBackToLanguage() {
        let voice = VoiceOptions.resolve(identifier: "missing.voice", language: "en-US")
        XCTAssertEqual(voice?.language, "en-US")
    }
    func testAvailableVoicesStayWithinLanguageAndResolveByIdentifier() {
        XCTAssertTrue(VoiceOptions.isPreferredName("Samantha (Enhanced)"))
        XCTAssertTrue(VoiceOptions.isPreferredName("Eddy"))
        XCTAssertFalse(VoiceOptions.isPreferredName("Fred"))
        for voice in VoiceOptions.available(for: "en-US") {
            XCTAssertTrue(VoiceOptions.isPreferredName(voice.name))
            XCTAssertEqual(voice.language, "en-US")
            XCTAssertEqual(VoiceOptions.resolve(identifier: voice.identifier, language: "en-US")?.identifier, voice.identifier)
            XCTAssertFalse(VoiceOptions.quality(voice).isEmpty)
        }
    }
}
