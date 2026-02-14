//
//  COMFIEUITests+Support.swift
//  COMFIEUITests
//
//  Created by zaehorang on 2/14/26.
//

import XCTest

@MainActor
func enforcePortraitOrientationForUITests() {
    XCUIDevice.shared.orientation = .portrait
    RunLoop.current.run(until: Date().addingTimeInterval(0.25))
}

extension COMFIEUITests {
    @MainActor
    func launchAppForMemoScenario(
        forceOutsideComfieZone: Bool = false,
        forceEnglishLocale: Bool = false,
        forceKoreanLocale: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        // 앱에서 draft 스냅샷을 accessibilityValue로 노출하도록 draftDebug 인자를 함께 준다.
        app.launchArguments += [UITestLaunchArgument.uiTesting.rawValue, UITestLaunchArgument.draftDebug.rawValue]
        precondition(!(forceEnglishLocale && forceKoreanLocale), "Only one locale override can be enabled.")
        if forceEnglishLocale {
            app.launchArguments += [
                "-AppleLanguages",
                "(en-US)",
                "-AppleLocale",
                "en_US",
                UITestLaunchArgument.forceASCIIKeyboard.rawValue
            ]
        } else if forceKoreanLocale {
            app.launchArguments += [
                "-AppleLanguages",
                "(ko-KR)",
                "-AppleLocale",
                "ko_KR",
                UITestLaunchArgument.forceKoreanKeyboard.rawValue
            ]
        }
        if forceOutsideComfieZone {
            app.launchArguments += [UITestLaunchArgument.forceOutsideComfieZone.rawValue]
        } else {
            app.launchArguments += [UITestLaunchArgument.forceInsideComfieZone.rawValue]
        }
        app.launch()
        enforcePortraitOrientation()
        return app
    }

    @MainActor
    func enforcePortraitOrientation() {
        enforcePortraitOrientationForUITests()
    }

    @MainActor
    func attachScreenshot(_ app: XCUIApplication, named name: String) {
        enforcePortraitOrientation()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func waitUntil(
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

    func readDraftDebug(from input: XCUIElement) -> DraftDebugSnapshot? {
        guard let rawValue = input.value as? String,
              let data = rawValue.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(DraftDebugSnapshot.self, from: data)
    }

    @MainActor
    func memoComposerElements(in app: XCUIApplication) -> (input: XCUIElement, sendButton: XCUIElement) {
        let input = app.textViews[AccessibilityID.Memo.inputTextView]
        let sendButton = app.buttons[AccessibilityID.Memo.sendButton]

        XCTAssertTrue(input.waitForExistence(timeout: 8))
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        return (input, sendButton)
    }

    func waitForDraftSnapshot(
        in input: XCUIElement,
        timeout: TimeInterval = 3,
        pollInterval: TimeInterval = 0.05,
        condition: @escaping (DraftDebugSnapshot) -> Bool
    ) -> Bool {
        waitUntil(timeout: timeout, pollInterval: pollInterval) {
            guard let snapshot = self.readDraftDebug(from: input) else { return false }
            return condition(snapshot)
        }
    }

    func currentMemoCount(in app: XCUIApplication) -> Int {
        app.buttons.matching(identifier: AccessibilityID.Memo.cellMenuButton).count
    }

    func waitForMemoCount(
        in app: XCUIApplication,
        expectedCount: Int,
        timeout: TimeInterval = 8
    ) -> Bool {
        waitUntil(timeout: timeout) {
            self.currentMemoCount(in: app) == expectedCount
        }
    }

    func waitForMemoCountAtLeast(
        in app: XCUIApplication,
        minimumCount: Int,
        timeout: TimeInterval = 8
    ) -> Bool {
        waitUntil(timeout: timeout) {
            self.currentMemoCount(in: app) >= minimumCount
        }
    }

    func assertSendButtonEnabled(_ sendButton: XCUIElement, timeout: TimeInterval = 8) {
        XCTAssertTrue(
            waitUntil(timeout: timeout) {
                sendButton.isEnabled
            }
        )
    }

    @MainActor
    func tapSendWhenEnabled(_ sendButton: XCUIElement, timeout: TimeInterval = 8) {
        assertSendButtonEnabled(sendButton, timeout: timeout)
        sendButton.tap()
    }

    @MainActor
    func openLatestMemoMenu(in app: XCUIApplication) {
        XCTAssertTrue(waitForMemoCountAtLeast(in: app, minimumCount: 1))
        let menuButtons = app.buttons.matching(identifier: AccessibilityID.Memo.cellMenuButton)
        let latestIndex = max(0, menuButtons.count - 1)
        let latestMenuButton = menuButtons.element(boundBy: latestIndex)
        XCTAssertTrue(latestMenuButton.exists)
        latestMenuButton.tap()
    }

    @MainActor
    func tapMenuAction(_ app: XCUIApplication, identifier: String) {
        let actionButton = app.buttons[identifier]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 3))
        actionButton.tap()
    }

    @MainActor
    func resetMemoInputIfNeeded(in app: XCUIApplication, input: XCUIElement) {
        input.tap()
        if let initialSnapshot = readDraftDebug(from: input), !initialSnapshot.original.isEmpty {
            for _ in 0..<(initialSnapshot.original.count + 4) {
                tapDeleteKey(in: app)
                RunLoop.current.run(until: Date().addingTimeInterval(0.03))
            }
            XCTAssertTrue(waitForDraftSnapshot(in: input) { $0.original.isEmpty })
        }
    }

    @MainActor
    func typeHangulJamoSequence(
        in app: XCUIApplication,
        input: XCUIElement,
        jamoKeys: [String],
        expectedAfterEachSyllable: [String]
    ) {
        var previousRevision = readDraftDebug(from: input)?.revision ?? 0
        for (index, key) in jamoKeys.enumerated() {
            tapKeyboardKey(in: app, key: key)
            XCTAssertTrue(
                waitForDraftSnapshot(in: input) { snapshot in
                    snapshot.revision > previousRevision
                }
            )
            previousRevision = readDraftDebug(from: input)?.revision ?? previousRevision
            attachScreenshot(app, named: "hangul-emoji-key-\(String(format: "%02d", index + 1))-\(key)")
            captureHangulSyllableProofIfNeeded(
                in: app,
                input: input,
                index: index,
                expectedAfterEachSyllable: expectedAfterEachSyllable
            )
        }
    }

    @MainActor
    private func captureHangulSyllableProofIfNeeded(
        in app: XCUIApplication,
        input: XCUIElement,
        index: Int,
        expectedAfterEachSyllable: [String]
    ) {
        guard index % 2 == 1 else { return }

        let syllableIndex = index / 2
        let expectedOriginal = expectedAfterEachSyllable[syllableIndex]
        XCTAssertTrue(
            waitForDraftSnapshot(in: input) { snapshot in
                self.hangulSyllableSnapshotMatches(snapshot, expectedOriginal: expectedOriginal)
            }
        )
        attachScreenshot(app, named: "hangul-emoji-syllable-\(syllableIndex + 1)-\(expectedOriginal)")
    }

    private func hangulSyllableSnapshotMatches(
        _ snapshot: DraftDebugSnapshot,
        expectedOriginal: String
    ) -> Bool {
        guard snapshot.original == expectedOriginal else { return false }

        let originalChars = Array(snapshot.original)
        let emojiChars = Array(snapshot.emoji)
        guard !originalChars.isEmpty, originalChars.count == emojiChars.count else {
            return false
        }

        let currentIndex = originalChars.count - 1
        guard emojiChars[currentIndex] == originalChars[currentIndex] else {
            return false
        }

        if currentIndex == 0 {
            return true
        }
        return (0..<currentIndex).allSatisfy { previousIndex in
            emojiChars[previousIndex] != originalChars[previousIndex]
        }
    }
}
