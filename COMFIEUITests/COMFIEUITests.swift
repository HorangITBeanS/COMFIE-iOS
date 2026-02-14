//
//  COMFIEUITests.swift
//  COMFIEUITests
//
//  Created by Anjin on 3/5/25.
//

import XCTest

final class COMFIEUITests: XCTestCase {
    // MemoInputUITextView+Snapshot+UITest가 발행하는 JSON 스키마와 동일한 구조체다.
    struct DraftDebugSnapshot: Decodable {
        let original: String
        let emoji: String
        let revision: Int
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMemoInputSendCreatesNewMemoCell() throws {
        let app = launchAppForMemoScenario(forceEnglishLocale: true)
        let (input, sendButton) = memoComposerElements(in: app)
        let beforeCount = currentMemoCount(in: app)

        input.tap()
        let rawInput = "stepsendproofflow"
        var expectedOriginal = ""
        var previousRevision = readDraftDebug(from: input)?.revision ?? 0
        for (index, character) in rawInput.enumerated() {
            tapKeyboardKey(in: app, key: String(character))
            expectedOriginal.append(character)

            XCTAssertTrue(
                waitForDraftSnapshot(in: input) { snapshot in
                    snapshot.revision > previousRevision && snapshot.original == expectedOriginal
                }
            )
            previousRevision = readDraftDebug(from: input)?.revision ?? previousRevision
            attachScreenshot(app, named: "memo-send-typing-step-\(String(format: "%02d", index + 1))")
            RunLoop.current.run(until: Date().addingTimeInterval(0.22))
        }

        attachScreenshot(app, named: "memo-send-before-send")

        tapSendWhenEnabled(sendButton)
        XCTAssertTrue(waitForMemoCountAtLeast(in: app, minimumCount: beforeCount + 1))
        attachScreenshot(app, named: "memo-send-after-save")
    }

    @MainActor
    func testHangulJamoTypingShowsStepByStepProgress() throws {
        let app = launchAppForMemoScenario(forceOutsideComfieZone: true, forceKoreanLocale: true)
        let (input, sendButton) = memoComposerElements(in: app)
        let memoContentTexts = app.staticTexts.matching(identifier: AccessibilityID.Memo.cellContentText)
        let beforeCount = currentMemoCount(in: app)
        let rawInput = "가나다라마바사"

        resetMemoInputIfNeeded(in: app, input: input)
        attachScreenshot(app, named: "hangul-emoji-step-0-empty")

        let jamoKeys = ["ㄱ", "ㅏ", "ㄴ", "ㅏ", "ㄷ", "ㅏ", "ㄹ", "ㅏ", "ㅁ", "ㅏ", "ㅂ", "ㅏ", "ㅅ", "ㅏ"]
        let expectedAfterEachSyllable = ["가", "가나", "가나다", "가나다라", "가나다라마", "가나다라마바", "가나다라마바사"]
        typeHangulJamoSequence(
            in: app,
            input: input,
            jamoKeys: jamoKeys,
            expectedAfterEachSyllable: expectedAfterEachSyllable
        )

        XCTAssertTrue(
            waitForDraftSnapshot(in: input) { snapshot in
                snapshot.original == rawInput && snapshot.emoji != snapshot.original
            }
        )
        tapSendWhenEnabled(sendButton)
        XCTAssertTrue(waitForMemoCountAtLeast(in: app, minimumCount: beforeCount + 1))

        XCTAssertTrue(waitUntil { memoContentTexts.count > 0 })
        attachScreenshot(app, named: "hangul-emoji-after-save")

        let rawInputStillVisible = memoContentTexts.allElementsBoundByIndex
            .contains(where: { $0.label.contains(rawInput) })
        XCTAssertFalse(rawInputStillVisible)
    }

    @MainActor
    func testEmojiInputConvertsPerCharacterRealtimeAndAttachesVisualProof() throws {
        let app = launchAppForMemoScenario(forceOutsideComfieZone: true, forceEnglishLocale: true)
        let (input, sendButton) = memoComposerElements(in: app)
        let memoContentTexts = app.staticTexts.matching(identifier: AccessibilityID.Memo.cellContentText)
        let beforeCount = currentMemoCount(in: app)
        let rawInput = "abcdefghij"

        input.tap()
        var typedOriginal = ""
        for (index, character) in rawInput.enumerated() {
            typedOriginal.append(character)
            tapKeyboardKey(in: app, key: String(character))

            let realtimeUpdated = waitForDraftSnapshot(in: input) { snapshot in
                guard snapshot.original == typedOriginal else { return false }

                let originalChars = Array(snapshot.original)
                let emojiChars = Array(snapshot.emoji)
                guard !originalChars.isEmpty, originalChars.count == emojiChars.count else { return false }

                if index == 0 {
                    return emojiChars[0] == originalChars[0]
                }

                let previousIndex = index - 1
                let previousConverted = emojiChars[previousIndex] != originalChars[previousIndex]
                let currentStillPlain = emojiChars[index] == originalChars[index]
                return previousConverted && currentStillPlain
            }
            XCTAssertTrue(realtimeUpdated)
            attachScreenshot(app, named: "emoji-proof-step-\(index + 1)")

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        tapSendWhenEnabled(sendButton)
        XCTAssertTrue(waitForMemoCountAtLeast(in: app, minimumCount: beforeCount + 1))

        XCTAssertTrue(waitUntil { memoContentTexts.count > 0 })
        attachScreenshot(app, named: "emoji-proof-after-save")

        let rawInputStillVisible = memoContentTexts.allElementsBoundByIndex
            .contains(where: { $0.label.contains(rawInput) })
        XCTAssertFalse(rawInputStillVisible)
    }

    @MainActor
    func testMemoComposeFlowCoversMultipleWritingPatterns() throws {
        let app = launchAppForMemoScenario()
        let (input, sendButton) = memoComposerElements(in: app)

        let beforeCount = currentMemoCount(in: app)

        input.tap()
        input.typeText(
            "STEP-COMPOSE-1 |\(Int(Date().timeIntervalSince1970))| " +
            "첫 작성: 한글/영문 혼합 텍스트 1234567890"
        )
        attachScreenshot(app, named: "memo-compose-step-1-first-typed")
        tapSendWhenEnabled(sendButton)

        XCTAssertTrue(waitForMemoCountAtLeast(in: app, minimumCount: beforeCount + 1))
        XCTAssertTrue(waitUntil { !sendButton.isEnabled })
        attachScreenshot(app, named: "memo-compose-step-2-first-sent")

        input.tap()
        input.typeText(
            "STEP-COMPOSE-2 line-1: 멀티라인 첫 줄\n" +
            "STEP-COMPOSE-2 line-2: second line 1234567890"
        )
        input.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)).tap()
        input.typeText(" + STEP-COMPOSE-2-Tail")
        attachScreenshot(app, named: "memo-compose-step-3-multiline-cursor")
        tapSendWhenEnabled(sendButton)

        XCTAssertTrue(waitForMemoCountAtLeast(in: app, minimumCount: beforeCount + 2))
        XCTAssertTrue(waitUntil { !sendButton.isEnabled })
        attachScreenshot(app, named: "memo-compose-step-4-second-sent")

        input.tap()
        input.typeText("STEP-COMPOSE-3: 마지막 입력. 한글 English 1234567890.")
        attachScreenshot(app, named: "memo-compose-step-5-mixed-typed")
        tapSendWhenEnabled(sendButton)

        XCTAssertTrue(waitForMemoCountAtLeast(in: app, minimumCount: beforeCount + 3))
        XCTAssertFalse(sendButton.isEnabled)
        attachScreenshot(app, named: "memo-compose-step-6-third-sent")
    }

    @MainActor
    func testMemoEditUpdateAndDeleteLifecycle() throws {
        let app = launchAppForMemoScenario(forceOutsideComfieZone: true)
        let (input, sendButton) = memoComposerElements(in: app)
        let editingCancelButton = app.buttons[AccessibilityID.Memo.editingCancelButton]

        let beforeCount = currentMemoCount(in: app)

        input.tap()
        input.typeText(
            "수정흐름1 |\(Int(Date().timeIntervalSince1970))| " +
            "수정 대상 메모 생성 테스트"
        )
        tapSendWhenEnabled(sendButton)

        let createdCount = beforeCount + 1
        XCTAssertTrue(waitForMemoCount(in: app, expectedCount: createdCount))
        XCTAssertTrue(waitUntil { !sendButton.isEnabled })
        attachScreenshot(app, named: "memo-edit-delete-step-1-created")

        openLatestMemoMenu(in: app)
        attachScreenshot(app, named: "memo-edit-delete-step-2-menu-opened-for-edit")

        tapMenuAction(app, identifier: AccessibilityID.Memo.cellMenuEditButton)
        XCTAssertTrue(editingCancelButton.waitForExistence(timeout: 3))
        attachScreenshot(app, named: "memo-edit-delete-step-3-enter-edit")

        input.tap()
        input.typeText(" + 수정흐름2 최종수정")
        assertSendButtonEnabled(sendButton)
        attachScreenshot(app, named: "memo-edit-delete-step-4-edited-before-save")

        sendButton.tap()
        XCTAssertTrue(waitForMemoCount(in: app, expectedCount: createdCount))
        XCTAssertTrue(waitUntil { !editingCancelButton.exists })
        XCTAssertFalse(sendButton.isEnabled)
        attachScreenshot(app, named: "memo-edit-delete-step-5-updated")

        openLatestMemoMenu(in: app)
        attachScreenshot(app, named: "memo-edit-delete-step-6-menu-opened-for-delete")

        tapMenuAction(app, identifier: AccessibilityID.Memo.cellMenuDeleteButton)

        let popupDeleteButton = app.buttons[AccessibilityID.Popup.leftButton]
        XCTAssertTrue(popupDeleteButton.waitForExistence(timeout: 3))
        attachScreenshot(app, named: "memo-edit-delete-step-7-delete-popup-shown")
        popupDeleteButton.tap()

        XCTAssertTrue(waitForMemoCount(in: app, expectedCount: beforeCount))
        attachScreenshot(app, named: "memo-edit-delete-step-8-deleted")
    }

    @MainActor
    func testMemoEditingCancelInteractionFlow() throws {
        let app = launchAppForMemoScenario(forceOutsideComfieZone: true)
        let (input, sendButton) = memoComposerElements(in: app)

        let beforeCount = currentMemoCount(in: app)

        input.tap()
        input.typeText(
            "취소흐름1 |\(Int(Date().timeIntervalSince1970))| " +
            "취소 플로우용 원본 메모"
        )
        tapSendWhenEnabled(sendButton)

        let createdCount = beforeCount + 1
        XCTAssertTrue(waitForMemoCount(in: app, expectedCount: createdCount))
        attachScreenshot(app, named: "memo-cancel-flow-step-1-created")

        openLatestMemoMenu(in: app)
        attachScreenshot(app, named: "memo-cancel-flow-step-2-menu-opened")

        tapMenuAction(app, identifier: AccessibilityID.Memo.cellMenuDeleteButton)

        let popupDeleteButton = app.buttons[AccessibilityID.Popup.leftButton]
        let popupCancelButton = app.buttons[AccessibilityID.Popup.rightButton]
        XCTAssertTrue(popupDeleteButton.waitForExistence(timeout: 3))
        XCTAssertTrue(popupCancelButton.waitForExistence(timeout: 3))
        attachScreenshot(app, named: "memo-cancel-flow-step-3-delete-popup-shown")

        popupCancelButton.tap()
        XCTAssertTrue(input.exists)
        XCTAssertTrue(sendButton.exists)
        XCTAssertTrue(waitForMemoCount(in: app, expectedCount: createdCount))
        attachScreenshot(app, named: "memo-cancel-flow-step-4-after-delete-cancel")
    }
}
