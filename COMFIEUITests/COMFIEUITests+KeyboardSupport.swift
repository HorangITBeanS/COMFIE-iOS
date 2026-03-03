//
//  COMFIEUITests+KeyboardSupport.swift
//  COMFIEUITests
//
//  Created by zaehorang on 2/14/26.
//

import XCTest

extension COMFIEUITests {
    @MainActor
    func tapKeyboardKey(in app: XCUIApplication, key: String, timeout: TimeInterval = 3) {
        guard ensureKeyboardVisible(
            in: app,
            timeout: timeout,
            failureContext: "before-key-\(key)",
            failureAttachmentTag: "before-key-\(key)"
        ) else {
            return
        }

        // 시뮬레이터 실행마다 키보드 레이아웃이 달라질 수 있어 토글을 포함해 재시도한다.
        let keyboard = app.keyboards.firstMatch

        let normalizedKey: String
        if key.range(of: "^[a-z]$", options: .regularExpression) != nil {
            normalizedKey = key.lowercased()
            ensureLowercaseAlphabetModeIfNeeded(in: app, key: normalizedKey)
        } else if key.range(of: "^[A-Z]$", options: .regularExpression) != nil {
            normalizedKey = key.uppercased()
        } else {
            normalizedKey = key
        }

        let keyCandidates = [normalizedKey]
        for attempt in 0...4 {
            for candidate in keyCandidates {
                let keyQuery = keyboard.keys.matching(NSPredicate(format: "label == %@", candidate))
                if keyQuery.firstMatch.waitForExistence(timeout: min(timeout, 0.35)),
                   tapPreferredElement(in: app, query: keyQuery) {
                    return
                }
            }

            if attempt < 4 {
                guard switchKeyboardForKeyIfPossible(in: app, key: key) else { break }
                RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            }
        }

        XCTFail(
            "Keyboard key not found after layout switches: \(key). " +
                inputDebugSummary(in: app) + " " +
                keyboardDebugSummary(in: app) +
                " Hint: turn off Simulator > I/O > Keyboard > Connect Hardware Keyboard."
        )
    }

    @MainActor
    func tapDeleteKey(in app: XCUIApplication) {
        guard ensureKeyboardVisible(
            in: app,
            timeout: 3,
            failureContext: "before-delete-key",
            failureAttachmentTag: "before-delete-key"
        ) else {
            return
        }

        let keyboard = app.keyboards.firstMatch

        let candidateLabels = [
            XCUIKeyboardKey.delete.rawValue,
            "delete",
            "삭제",
            "지우기"
        ]

        for label in candidateLabels {
            let query = keyboard.keys.matching(NSPredicate(format: "label == %@", label))
            if tapPreferredElement(in: app, query: query) {
                return
            }
        }

        let fallbackQuery = keyboard.keys.matching(
            NSPredicate(format: "label CONTAINS[c] 'delete' OR label CONTAINS[c] '삭제'")
        )
        if tapPreferredElement(in: app, query: fallbackQuery) {
            return
        }
        XCTFail("Delete key not found on current keyboard. " + inputDebugSummary(in: app) + " " + keyboardDebugSummary(in: app))
    }

    @MainActor
    func tapSpaceKey(in app: XCUIApplication, input: XCUIElement? = nil, timeout: TimeInterval = 3) {
        guard ensureKeyboardVisible(
            in: app,
            input: input,
            timeout: timeout,
            failureContext: "before-space-key",
            failureAttachmentTag: "before-space-key"
        ) else {
            return
        }

        let keyboard = app.keyboards.firstMatch
        let candidateLabels = [
            XCUIKeyboardKey.space.rawValue,
            "space",
            "Space",
            "띄어쓰기",
            "공백"
        ]

        for label in candidateLabels {
            let keyQuery = keyboard.keys.matching(NSPredicate(format: "label == %@", label))
            if tapPreferredElement(in: app, query: keyQuery) {
                return
            }

            let buttonQuery = keyboard.buttons.matching(NSPredicate(format: "label == %@", label))
            if tapPreferredElement(in: app, query: buttonQuery) {
                return
            }
        }

        let targetInput = input ?? app.textViews[AccessibilityID.Memo.inputTextView]
        if targetInput.exists {
            targetInput.typeText(" ")
            return
        }

        XCTFail("Space key not found on current keyboard. " + inputDebugSummary(in: app, input: targetInput) + " " + keyboardDebugSummary(in: app))
    }

    @MainActor
    func ensureKeyboardVisible(
        in app: XCUIApplication,
        input: XCUIElement? = nil,
        timeout: TimeInterval = 3,
        refocusAttempts: Int = 3,
        failureContext: String,
        failureAttachmentTag: String
    ) -> Bool {
        let keyboard = app.keyboards.firstMatch
        if keyboard.waitForExistence(timeout: timeout) {
            return true
        }

        let targetInput = input ?? app.textViews[AccessibilityID.Memo.inputTextView]
        var attemptedRefocus = 0
        let retryWait = min(timeout, 0.6)
        for attempt in 1...refocusAttempts {
            attemptedRefocus = attempt
            refocusInputIfPossible(in: app, input: targetInput)
            RunLoop.current.run(until: Date().addingTimeInterval(0.12))

            if keyboard.waitForExistence(timeout: retryWait) {
                return true
            }
        }

        let details = """
        context=\(failureContext)
        attemptedRefocus=\(attemptedRefocus)
        \(inputDebugSummary(in: app, input: targetInput))
        \(keyboardDebugSummary(in: app))
        """
        attachKeyboardMissingDiagnostics(in: app, attachmentTag: failureAttachmentTag, details: details)

        XCTFail(
            "Keyboard does not exist after refocus retries. " +
                "context=\(failureContext), refocusAttempts=\(attemptedRefocus). " +
                details
        )
        return false
    }

    @MainActor
    private func ensureLowercaseAlphabetModeIfNeeded(in app: XCUIApplication, key: String) {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return }
        if doesKeyboardContainAnyKey(in: app, keyboard: keyboard, candidates: [key]) { return }

        let uppercase = key.uppercased()
        guard doesKeyboardContainAnyKey(in: app, keyboard: keyboard, candidates: [uppercase]) else { return }

        for shiftLabel in ["shift", "Shift"] where tapKeyboardToggle(in: app, label: shiftLabel) {
            RunLoop.current.run(until: Date().addingTimeInterval(0.08))
            if doesKeyboardContainAnyKey(in: app, keyboard: keyboard, candidates: [key]) {
                return
            }
        }
    }

    @MainActor
    private func switchKeyboardForKeyIfPossible(in app: XCUIApplication, key: String) -> Bool {
        if switchAlphabetModeIfNeeded(in: app, key: key) {
            return true
        }
        if switchKoreanModeIfNeeded(in: app, key: key) {
            return true
        }
        return switchKeyboardLayoutIfPossible(in: app)
    }

    @MainActor
    private func switchAlphabetModeIfNeeded(in app: XCUIApplication, key: String) -> Bool {
        guard key.range(of: "^[A-Za-z]$", options: .regularExpression) != nil else {
            return false
        }

        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return false }

        let keyCandidates = [key, key.lowercased(), key.uppercased()]
        if doesKeyboardContainAnyKey(in: app, keyboard: keyboard, candidates: keyCandidates) {
            return true
        }

        let toggleAttempts = [
            ["영문", "English", "ABC", "abc", "한/영", "한영", "가나다", "한글", "문자", "123", "숫자"],
            ["숫자", "123", "문자", "ABC", "abc", "영문", "English", "한/영", "한영", "가나다", "한글"],
            ["ABC", "abc", "영문", "English", "가나다", "한글", "문자"]
        ]

        for labels in toggleAttempts {
            for label in labels where tapKeyboardToggle(in: app, label: label) {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
                let refreshedKeyboard = app.keyboards.firstMatch
                if doesKeyboardContainAnyKey(in: app, keyboard: refreshedKeyboard, candidates: keyCandidates) {
                    return true
                }
            }
        }

        return false
    }

    @MainActor
    private func switchKoreanModeIfNeeded(in app: XCUIApplication, key: String) -> Bool {
        guard key.range(of: "^[ㄱ-ㅎㅏ-ㅣ]$", options: .regularExpression) != nil else {
            return false
        }

        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return false }
        if doesKeyboardContainAnyKey(in: app, keyboard: keyboard, candidates: [key]) { return true }

        let toggleCandidates = [
            "한글", "가나다", "한/영", "한영", "한국어", "영문", "English", "ABC", "abc", "문자"
        ]

        for label in toggleCandidates where tapKeyboardToggle(in: app, label: label) {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            let refreshedKeyboard = app.keyboards.firstMatch
            if doesKeyboardContainAnyKey(in: app, keyboard: refreshedKeyboard, candidates: [key]) {
                return true
            }
        }

        return false
    }

    @MainActor
    private func switchKeyboardLayoutIfPossible(in app: XCUIApplication) -> Bool {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return false }

        let buttonLabels = [
            "Next keyboard",
            "next keyboard",
            "다음 키보드",
            "키보드 변경",
            "지구본"
        ]

        for label in buttonLabels {
            let query = keyboard.buttons.matching(NSPredicate(format: "label == %@", label))
            if tapPreferredElement(in: app, query: query) {
                return true
            }
        }

        for label in ["🌐", "🌍", "🌎", "🌏"] {
            let query = keyboard.keys.matching(NSPredicate(format: "label == %@", label))
            if tapPreferredElement(in: app, query: query) {
                return true
            }
        }

        let fallbackQuery = keyboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'next' OR label CONTAINS[c] '다음' OR label CONTAINS[c] '키보드'")
        )
        if tapPreferredElement(in: app, query: fallbackQuery) {
            return true
        }

        return false
    }

    @MainActor
    private func tapKeyboardToggle(in app: XCUIApplication, label: String) -> Bool {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return false }

        let keyQuery = keyboard.keys.matching(NSPredicate(format: "label == %@", label))
        if tapPreferredElement(in: app, query: keyQuery) {
            return true
        }

        let buttonQuery = keyboard.buttons.matching(NSPredicate(format: "label == %@", label))
        if tapPreferredElement(in: app, query: buttonQuery) {
            return true
        }

        return false
    }

    @MainActor
    private func doesKeyboardContainAnyKey(
        in app: XCUIApplication,
        keyboard: XCUIElement,
        candidates: [String]
    ) -> Bool {
        for candidate in candidates {
            let keyQuery = keyboard.keys.matching(NSPredicate(format: "label == %@", candidate))
            if preferredTapTarget(in: app, query: keyQuery) != nil {
                return true
            }
        }
        return false
    }

    @MainActor
    private func keyboardDebugSummary(in app: XCUIApplication) -> String {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else {
            return "Keyboard does not exist."
        }

        let keyLabels = keyboard.keys.allElementsBoundByIndex
            .map {
                let label = $0.label.isEmpty ? "<empty>" : $0.label
                let frame = $0.frame
                let hittable = $0.isHittable ? "hit" : "nohit"
                return "\(label)[\(hittable):\(Int(frame.minX)),\(Int(frame.minY)),\(Int(frame.width))x\(Int(frame.height))]"
            }
            .joined(separator: ",")
        let buttonLabels = keyboard.buttons.allElementsBoundByIndex
            .map {
                let label = $0.label.isEmpty ? "<empty>" : $0.label
                let frame = $0.frame
                let hittable = $0.isHittable ? "hit" : "nohit"
                return "\(label)[\(hittable):\(Int(frame.minX)),\(Int(frame.minY)),\(Int(frame.width))x\(Int(frame.height))]"
            }
            .joined(separator: ",")
        return "keys=[\(keyLabels)] buttons=[\(buttonLabels)]"
    }

    @MainActor
    private func inputDebugSummary(in app: XCUIApplication, input: XCUIElement? = nil) -> String {
        let targetInput = input ?? app.textViews[AccessibilityID.Memo.inputTextView]
        guard targetInput.exists else {
            return "input=[exists:false]"
        }

        let frame = targetInput.frame
        return "input=[exists:true,hittable:\(targetInput.isHittable),frame:\(Int(frame.minX)),\(Int(frame.minY)),\(Int(frame.width))x\(Int(frame.height))]"
    }

    @MainActor
    private func refocusInputIfPossible(in app: XCUIApplication, input: XCUIElement) {
        if input.exists {
            if input.isHittable {
                input.tap()
                return
            }

            if isElementWithinVisibleWindow(input, in: app) {
                input.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                return
            }
        }

        let inputQuery = app.textViews.matching(identifier: AccessibilityID.Memo.inputTextView)
        _ = tapPreferredElement(in: app, query: inputQuery)
    }

    @MainActor
    private func attachKeyboardMissingDiagnostics(in app: XCUIApplication, attachmentTag: String, details: String) {
        attachScreenshot(app, named: "keyboard-missing-\(attachmentTag)")

        let textAttachment = XCTAttachment(string: details)
        textAttachment.name = "keyboardDebugSummary-\(attachmentTag)"
        textAttachment.lifetime = .keepAlways
        add(textAttachment)
    }

    @MainActor
    private func isElementWithinVisibleWindow(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        let elementFrame = element.frame
        guard !elementFrame.isEmpty else { return false }

        let windowFrame = app.windows.firstMatch.frame
        guard !windowFrame.isEmpty else { return false }
        return windowFrame.intersects(elementFrame)
    }

    @MainActor
    private func preferredTapTarget(in app: XCUIApplication, query: XCUIElementQuery) -> XCUIElement? {
        let candidates = query.allElementsBoundByIndex.filter { $0.exists }
        if let hittable = candidates.first(where: { $0.isHittable }) {
            return hittable
        }
        if let visible = candidates.first(where: { isElementWithinVisibleWindow($0, in: app) }) {
            return visible
        }
        return candidates.first
    }

    @MainActor
    private func tapPreferredElement(in app: XCUIApplication, query: XCUIElementQuery) -> Bool {
        guard let element = preferredTapTarget(in: app, query: query) else { return false }
        if element.isHittable {
            element.tap()
            return true
        }
        guard isElementWithinVisibleWindow(element, in: app) else {
            return false
        }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return true
    }
}
