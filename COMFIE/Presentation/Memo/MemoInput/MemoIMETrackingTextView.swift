//
//  MemoIMETrackingTextView.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

// IME(한글/중국어 조합 입력) 상태 변화를 콜백으로 전달하는 UITextView입니다.
class MemoIMETrackingTextView: UITextView {
    // 조합 입력 구간이 생겼을 때 호출할 콜백입니다.
    var onSetMarkedText: ((NSRange) -> Void)?
    // 조합 입력이 확정되어 marked 상태가 해제됐을 때 호출할 콜백입니다.
    var onUnmarkText: (() -> Void)?

    // 시스템이 marked text를 설정할 때 우리 로직도 함께 실행합니다.
    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        super.setMarkedText(markedText, selectedRange: selectedRange)
        // 현재 marked 범위가 있으면 NSRange로 변환해 상위 코디네이터로 보냅니다.
        if let range = markedTextRange {
            onSetMarkedText?(memoIME_nsRange(from: range))
        }
    }

    // 조합 입력이 끝날 때를 감지해 후처리를 트리거합니다.
    override func unmarkText() {
        super.unmarkText()
        onUnmarkText?()
    }
}

extension UITextView {
    // UITextRange를 NSRange로 변환해 배열/스토리지 인덱스 연산에 바로 쓰게 해줍니다.
    func memoIME_nsRange(from textRange: UITextRange) -> NSRange {
        // 문서 시작점부터 시작 위치까지의 오프셋이 NSRange.location입니다.
        let location = offset(from: beginningOfDocument, to: textRange.start)
        // 시작점부터 끝점까지의 오프셋이 NSRange.length입니다.
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
}
