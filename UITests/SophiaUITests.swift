import XCTest

final class SophiaUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        return app
    }
    func testBoardCategoryAndSentence() {
        let app = launch()
        XCTAssertTrue(app.buttons["word-Yes"].waitForExistence(timeout: 15))
        let preview = XCTAttachment(screenshot: app.screenshot())
        preview.name = "Sophia-iPad-landscape"
        preview.lifetime = .keepAlways
        add(preview)
        app.buttons["word-Yes"].tap()
        XCTAssertTrue(app.buttons["speakSentence"].isEnabled)
        app.buttons["Clear"].tap()
        XCTAssertFalse(app.buttons["speakSentence"].isEnabled)
        app.buttons["Food"].tap()
        XCTAssertTrue(app.buttons["word-Apple"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["word-Yes"].exists)
    }
    func testParentGateAndCreateWord() {
        let app = launch()
        app.buttons["parentSpace"].tap()
        let question = app.staticTexts.matching(NSPredicate(format: "label CONTAINS ' + ' AND label CONTAINS ' = ?'")).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        let numbers = question.label.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
        XCTAssertEqual(numbers.count, 2)
        let answer = app.textFields["parentAnswer"]
        answer.tap(); answer.typeText(String(numbers.reduce(0,+)))
        app.buttons["unlockParent"].tap()
        XCTAssertTrue(app.navigationBars["Parent space"].waitForExistence(timeout: 5))
        app.buttons["Edit Alex’s words"].tap()
        app.buttons["Everyday · 6"].tap()
        app.buttons["addWord"].tap()
        let title = app.textFields["cardTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Please")
        app.buttons["saveCard"].tap()
        XCTAssertTrue(app.staticTexts["Please"].waitForExistence(timeout: 5))
    }
}
