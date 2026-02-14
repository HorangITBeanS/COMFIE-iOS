//
//  MemoInputUITextView+Snapshot+UITest.swift
//  COMFIE
//
//  Created by zaehorang on 2/14/26.
//

import UIKit

#if DEBUG

extension MemoInputUITextView.Coordinator {
    private var shouldExposeUITestDraftDebug: Bool {
        UITestBootstrap.isUITesting()
            && UITestBootstrap.hasLaunchArgument(.draftDebug)
    }

    func publishDebugSnapshotIfNeeded(_ textView: UITextView) {
        // UITest 검증을 위해서만 draft 스냅샷을 accessibilityValue로 노출한다.
        guard shouldExposeUITestDraftDebug else { return }

        let payload: [String: Any] = [
            "original": draftOriginalText,
            "emoji": draftEmojiText,
            "revision": draftRevision
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        textView.accessibilityValue = json
    }
}

#else

extension MemoInputUITextView.Coordinator {
    func publishDebugSnapshotIfNeeded(_ textView: UITextView) {
        _ = textView
    }
}

#endif
