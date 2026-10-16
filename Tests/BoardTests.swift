import XCTest
import SwiftData
@testable import SophiaAAC

@MainActor final class BoardTests: XCTestCase {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: ChildProfile.self, BoardCategory.self, CommunicationCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }
    func testStarterBoardBelongsToOnlyItsProfile() throws {
        let db = try container(), context = db.mainContext
        let child = ChildProfile(name: "Sample"), other = ChildProfile(name: "Other")
        context.insert(child); context.insert(other)
        StarterBoard.add(to: child, in: context)
        try context.save()
        XCTAssertEqual(child.sortedCategories.count, 5)
        XCTAssertEqual(child.cards.count, 27)
        XCTAssertTrue(other.cards.isEmpty)
        XCTAssertTrue(child.cards.allSatisfy { $0.category?.profile?.id == child.id })
    }
    func testSpeechFallsBackToLabel() {
        let card = CommunicationCard(title: "Water", spokenText: "  ")
        XCTAssertEqual(card.phrase, "Water")
        card.spokenText = " I would like water "
        XCTAssertEqual(card.phrase, "I would like water")
    }
    func testBackupRoundTripPreservesPhotosFavoritesAndOrder() throws {
        let db = try container(), context = db.mainContext
        let child = ChildProfile(name: "Sample", photo: Data([1,2,3]))
        context.insert(child)
        StarterBoard.add(to: child, in: context)
        let first = try XCTUnwrap(child.cards.first)
        first.photo = Data([4,5,6]); first.isFavorite = true
        try context.save()
        let data = try JSONEncoder().encode(BoardBackup(profile: child))
        let restored = try JSONDecoder().decode(BoardBackup.self, from: data).restore(in: context)
        XCTAssertNotEqual(child.id, restored.id)
        XCTAssertEqual(restored.name, "Sample (restored)")
        XCTAssertEqual(restored.photo, child.photo)
        XCTAssertEqual(restored.cards.count, child.cards.count)
        XCTAssertEqual(restored.cards.first?.photo, first.photo)
        XCTAssertEqual(restored.cards.first?.isFavorite, true)
        XCTAssertEqual(restored.sortedCategories.map(\.name), child.sortedCategories.map(\.name))
    }
    func testDeletingProfileDoesNotDeleteAnotherBoard() throws {
        let db = try container(), context = db.mainContext
        let first = ChildProfile(name: "First"), second = ChildProfile(name: "Second")
        context.insert(first); context.insert(second)
        StarterBoard.add(to: first, in: context); StarterBoard.add(to: second, in: context)
        try context.save()
        context.delete(first); try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ChildProfile>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<BoardCategory>()), 5)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CommunicationCard>()), 27)
    }
    func testUnsupportedBackupRejectedWithoutInserting() throws {
        let db = try container(), context = db.mainContext
        var backup = BoardBackup(profile: ChildProfile(name: "Sample"))
        backup.version = 99
        XCTAssertThrowsError(try backup.restore(in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ChildProfile>()), 0)
    }
    func testPersistenceAcrossContainerReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let schema = Schema([ChildProfile.self, BoardCategory.self, CommunicationCard.self])
        do {
            let db = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
            let child = ChildProfile(name: "Saved")
            db.mainContext.insert(child)
            StarterBoard.add(to: child, in: db.mainContext)
            try db.mainContext.save()
        }
        let db = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
        let children = try db.mainContext.fetch(FetchDescriptor<ChildProfile>())
        XCTAssertEqual(children.first?.name, "Saved")
        XCTAssertEqual(children.first?.cards.count, 27)
    }
}
