//
//  MemoInputUITextView+UITest.swift
//  COMFIE
//
//  Created by zaehorang on 2/14/26.
//

import UIKit

#if DEBUG

extension MemoInputUITextView {
    func createUITestTextViewIfNeeded() -> MemoIMETrackingTextView? {
        guard UITestBootstrap.isUITesting() else { return nil }
        return createUITestTextView()
    }

    private func createUITestTextView() -> MemoIMETrackingTextView {
        let textView = MemoUITestIMETrackingTextView()
        configureBaseTextView(textView)
        textView.applyUITestAccessibilityIdentifier(AccessibilityID.Memo.inputTextView)
        applyUITestKeyboardOverrides(to: textView)
        return textView
    }

    private func applyUITestKeyboardOverrides(to textView: MemoUITestIMETrackingTextView) {
        // 시뮬레이터별 키보드 편차를 줄이기 위해 테스트 시 키보드 동작을 결정적으로 맞춘다.
        if UITestBootstrap.hasLaunchArgument(.forceKoreanKeyboard) {
            textView.uiTestPreferredPrimaryLanguage = "ko"
            applyDeterministicKeyboardTraits(to: textView)
            textView.keyboardType = .default
            return
        }

        guard UITestBootstrap.hasLaunchArgument(.forceASCIIKeyboard) else { return }
        applyDeterministicKeyboardTraits(to: textView)
        textView.keyboardType = .asciiCapable
    }

    private func applyDeterministicKeyboardTraits(to textView: UITextView) {
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
    }
}

#endif
