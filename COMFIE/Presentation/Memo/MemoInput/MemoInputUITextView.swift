//
//  MemoInputUITextView.swift
//  COMFIE
//
//  Created by zaehorang on 5/29/25.
//

import SwiftUI
import UIKit

struct MemoInputUITextView: UIViewRepresentable {
    let placeholder: String

    @Binding var dynamicHeight: CGFloat
    @Binding private var intent: MemoStore

    let comfieUIBodyFont = UIFont(
        name: ComfieFontType.body.fontName.rawValue,
        size: ComfieFontType.body.fontSize)!
    let maxLineCount: CGFloat = 4

    init(
        _ placeholder: String,
        dynamicHeight: Binding<CGFloat>,
        intent: Binding<MemoStore>
    ) {
        self.placeholder = placeholder
        self._dynamicHeight = dynamicHeight
        self._intent = intent
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, intent: $intent)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let textView = createTextView()
        let placeholderLabel = createPlaceholderLabel()

        let heightConstraint = createMaxHeightConstraint(for: textView)

        textView.delegate = context.coordinator
        textView.onSetMarkedText = { [weak textView, weak coordinator = context.coordinator] markedRange in
            guard let textView else { return }
            coordinator?.handleMarkedRange(in: textView, marked: markedRange)
        }
        textView.onUnmarkText = { [weak textView, weak coordinator = context.coordinator] in
            guard let textView else { return }
            coordinator?.handleUnmark(in: textView)
        }

        context.coordinator.textView = textView
        context.coordinator.placeholderLabel = placeholderLabel
        context.coordinator.textViewHeightConstraint = heightConstraint
        context.coordinator.bindFocusControl()
        context.coordinator.applyStateToTextView(force: true)

        container.addSubview(textView)
        container.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 9),
            // textView의 커서 위치와 플레이스홀더의 정렬을 맞추기 위해 오른쪽으로 5pt 추가
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 17)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.applyStateToTextView(force: false)
    }

    private func createTextView() -> MemoIMETrackingTextView {
        let textView = MemoIMETrackingTextView()
        textView.font = comfieUIBodyFont
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.keyBackground
        textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 8)
        textView.layer.cornerRadius = 12
        textView.clipsToBounds = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.accessibilityIdentifier = "memo.inputTextView"
        return textView
    }

    private func createPlaceholderLabel() -> UILabel {
        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholder
        placeholderLabel.font = comfieUIBodyFont
        placeholderLabel.textColor = UIColor.textGray
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        return placeholderLabel
    }

    /// 텍스트뷰의 최대 줄 수에 따른 높이 제한 제약 생성
    private func createMaxHeightConstraint(for textView: UITextView) -> NSLayoutConstraint {
        let maxHeight = comfieUIBodyFont.lineHeight
            * maxLineCount
            + textView.textContainerInset.top
            + textView.textContainerInset.bottom

        let heightConstraint = textView.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        return heightConstraint
    }
}
