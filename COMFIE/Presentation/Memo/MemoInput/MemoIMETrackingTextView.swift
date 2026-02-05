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

    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        super.setMarkedText(markedText, selectedRange: selectedRange)
        if let range = markedTextRange {
            onSetMarkedText?(memoIME_nsRange(from: range))
        }
    }

    override func unmarkText() {
        super.unmarkText()
        onUnmarkText?()
    }
}

extension UITextView {
    func memoIME_nsRange(from textRange: UITextRange) -> NSRange {
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
}
