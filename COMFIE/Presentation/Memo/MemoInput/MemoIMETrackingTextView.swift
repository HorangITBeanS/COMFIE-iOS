//
//  MemoIMETrackingTextView.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

final class MemoIMETrackingTextView: UITextView {
    var onSetMarkedText: ((NSRange) -> Void)?
    var onUnmarkText: (() -> Void)?

    // IME 조합 중인 범위를 감지해 코디네이터로 전달한다.
    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        super.setMarkedText(markedText, selectedRange: selectedRange)
        if let range = markedTextRange {
            onSetMarkedText?(memoIME_nsRange(from: range))
        }
    }

    // 조합이 완료된 시점을 알려준다.
    override func unmarkText() {
        super.unmarkText()
        onUnmarkText?()
    }
}

extension UITextView {
    // UITextRange를 NSRange로 변환한다. (IME 조합 범위 처리용)
    func memoIME_nsRange(from textRange: UITextRange) -> NSRange {
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
}
