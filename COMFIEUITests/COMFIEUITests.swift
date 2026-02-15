//
//  COMFIEUITests.swift
//  COMFIEUITests
//
//  Created by Anjin on 3/5/25.
//

import XCTest

final class COMFIEUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchAppForMemoScenario() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        return app
    }

    private func waitUntil(
        timeout: TimeInterval = 8,
        pollInterval: TimeInterval = 0.1,
        condition: @escaping () -> Bool
    ) -> Bool {
        let endTime = Date().addingTimeInterval(timeout)
        while Date() < endTime {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
        }
        return condition()
    }

    @MainActor
    func testMemoInputSendCreatesNewMemoCell() throws {
        let app = launchAppForMemoScenario()
        let input = app.textViews["memo.inputTextView"]
        let sendButton = app.buttons["memo.sendButton"]

        XCTAssertTrue(input.waitForExistence(timeout: 8))
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))

        let beforeCount = app.buttons.matching(identifier: "memo.cell.menuButton").count

        input.tap()
        input.typeText("UITEST\(Int(Date().timeIntervalSince1970))")

        let becameEnabled = waitUntil {
            sendButton.isEnabled
        }
        XCTAssertTrue(becameEnabled)
        sendButton.tap()

        let countIncreased = waitUntil {
            app.buttons.matching(identifier: "memo.cell.menuButton").count >= beforeCount + 1
        }
        XCTAssertTrue(countIncreased)
    }

    @MainActor
    func testHangulTypingAndCursorTapKeepsInputInteractive() throws {
        let app = launchAppForMemoScenario()
        let input = app.textViews["memo.inputTextView"]
        let sendButton = app.buttons["memo.sendButton"]

        XCTAssertTrue(input.waitForExistence(timeout: 8))
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))

        input.tap()
        input.typeText("가나")

        let firstEnable = waitUntil {
            sendButton.isEnabled
        }
        XCTAssertTrue(firstEnable)

        input.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)).tap()
        input.typeText("다")

        let secondEnable = waitUntil {
            sendButton.isEnabled
        }
        XCTAssertTrue(secondEnable)
        XCTAssertTrue(input.exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let app = XCUIApplication()
                app.launchArguments += ["-ui-testing"]
                app.launch()
            }
        }
    }
}
