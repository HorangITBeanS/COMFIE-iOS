//
//  MemoInputUITextView+TextViewLayout.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

extension MemoInputUITextView.Coordinator {
    // MARK: - TextView Handling

    func updatePlaceholderVisibility(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.textStorage.string.isEmpty
    }

    /// 텍스트 내용에 따라 높이를 계산하고 제한된 높이까지 설정
    func updateTextViewHeight(_ textView: UITextView) {
        let width = textView.bounds.width
        guard width > 0 else { return }

        updatePlaceholderVisibility(textView)

        let fittingSize = CGSize(
            width: width,
            height: .greatestFiniteMagnitude
        )
        let estimatedSize = textView.sizeThatFits(fittingSize)

        let maxHeight = parent.comfieUIBodyFont.lineHeight
            * parent.maxLineCount
            + textView.textContainerInset.top
            + textView.textContainerInset.bottom

        let targetHeight = min(estimatedSize.height, maxHeight)
        textViewHeightConstraint?.constant = targetHeight
        textView.isScrollEnabled = estimatedSize.height >= maxHeight
        if parent.dynamicHeight != targetHeight {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.parent.dynamicHeight = targetHeight
            }
        }
    }

    func focusTextView(_ textView: UITextView) {
        textView.becomeFirstResponder()
    }

    func unfocusTextView(_ textView: UITextView) {
        textView.resignFirstResponder()
    }
}
