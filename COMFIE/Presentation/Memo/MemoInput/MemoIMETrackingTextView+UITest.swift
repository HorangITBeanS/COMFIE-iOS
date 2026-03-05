//
//  MemoIMETrackingTextView+UITest.swift
//  COMFIE
//
//  Created by zaehorang on 2/14/26.
//

import UIKit

#if DEBUG

final class MemoUITestIMETrackingTextView: MemoIMETrackingTextView {
    var uiTestPreferredPrimaryLanguage: String?

    override var textInputMode: UITextInputMode? {
        // 런치 인자로 요청된 경우 키보드 언어를 고정해 레이아웃 흔들림을 줄인다.
        guard UITestBootstrap.isUITesting(),
              let preferredLanguage = uiTestPreferredPrimaryLanguage else {
            return super.textInputMode
        }

        if let preferredMode = UITextInputMode.activeInputModes.first(where: { mode in
            guard let primaryLanguage = mode.primaryLanguage else { return false }
            return primaryLanguage.hasPrefix(preferredLanguage)
        }) {
            return preferredMode
        }

        return super.textInputMode
    }
}

#endif
