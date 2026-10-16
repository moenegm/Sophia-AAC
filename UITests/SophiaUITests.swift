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
        app.buttons["chooseVoice"].tap()
        XCTAssertTrue(app.navigationBars["Choose a voice"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["System default"].exists)
        let voice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'select-voice-'")).firstMatch
        if voice.exists {
            let voiceID = voice.identifier
            voice.tap()
            XCTAssertEqual(voice.value as? String, "Selected")
            app.navigationBars.buttons.firstMatch.tap()
            app.buttons["chooseVoice"].tap()
            XCTAssertEqual(app.buttons[voiceID].value as? String, "Selected")
        }
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Edit Alex’s words"].tap()
        app.buttons["Everyday · 6"].tap()
        app.buttons["addWord"].tap()
        let title = app.textFields["cardTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Apple")
        if app.buttons["Done typing"].exists { app.buttons["Done typing"].tap() }
        // Suggestions do not silently choose a picture or rewrite the label.
        XCTAssertEqual(app.staticTexts["selectedPictureName"].label, "Talk")
        let suggestedApple = app.buttons["library-picture-Apple"]
        if !suggestedApple.isHittable { app.collectionViews["cardEditorForm"].swipeUp() }
        suggestedApple.tap()
        XCTAssertEqual(app.staticTexts["selectedPictureName"].label, "Apple")
        let preview = XCTAttachment(screenshot: app.screenshot())
        preview.name = "Picture-library-suggestions"
        preview.lifetime = .keepAlways
        add(preview)
        let browse = app.buttons["browsePictureLibrary"]
        if !browse.isHittable { app.swipeDown() }
        browse.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        if let value = search.value as? String, !value.isEmpty {
            search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        search.typeText("chicken wings")
        let carrot = app.buttons["library-picture-Chicken wings"]
        XCTAssertTrue(carrot.waitForExistence(timeout: 5))
        carrot.tap()
        XCTAssertEqual(app.staticTexts["selectedPictureName"].label, "Chicken wings")
        let form = app.collectionViews["cardEditorForm"]
        for _ in 0..<3 {
            if title.exists { break }
            form.swipeDown()
        }
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.value as? String, "Apple")
        app.buttons["saveCard"].tap()
        XCTAssertTrue(app.staticTexts["Apple"].waitForExistence(timeout: 5))
    }
}
