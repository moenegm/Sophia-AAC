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
        XCTAssertEqual(PictureLibrary.search("apple juice").first?.name, "Juice")
        XCTAssertFalse(PictureLibrary.search("apple juice").contains { $0.name == "Apple" })
    }
    func testEmptyAndUnknownSearches() {
        XCTAssertEqual(PictureLibrary.search("").count, PictureLibrary.pictures.count)
        XCTAssertTrue(PictureLibrary.search("unicornspaceship").isEmpty)
        XCTAssertTrue(PictureLibrary.search("I would like").isEmpty)
    }
    func testEveryCatalogEntryHasAUniqueIDAndBundledImage() {
        XCTAssertEqual(Set(PictureLibrary.pictures.map(\.id)).count, PictureLibrary.pictures.count)
        for picture in PictureLibrary.pictures {
            XCTAssertNotNil(UIImage(named: picture.assetName), "Missing asset for \(picture.name)")
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
