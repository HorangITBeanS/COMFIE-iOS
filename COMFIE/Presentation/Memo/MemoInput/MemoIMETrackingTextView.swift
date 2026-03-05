//
//  MemoIMETrackingTextView.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

// IME(한글/중국어 조합 입력) 상태 변화를 콜백으로 전달하는 UITextView입니다.
final class MemoIMETrackingTextView: UITextView {
    var onSetMarkedText: ((NSRange) -> Void)?
    var onUnmarkText: (() -> Void)?

    // marked text가 생기는 즉시 범위를 Coordinator에 전달해 IME 경계를 추적합니다.
    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        super.setMarkedText(markedText, selectedRange: selectedRange)
        if let range = markedTextRange {
            onSetMarkedText?(memoIME_nsRange(from: range))
        }
    }

    // 조합 입력이 확정되는 시점에 후처리 콜백을 실행합니다.
    override func unmarkText() {
        super.unmarkText()
        onUnmarkText?()
    }
}

extension UITextView {
    // UITextRange를 NSRange로 변환해 textStorage 인덱스 연산에 사용합니다.
    func memoIME_nsRange(from textRange: UITextRange) -> NSRange {
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
}
