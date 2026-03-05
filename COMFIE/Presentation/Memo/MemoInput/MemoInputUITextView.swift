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

    let inputSeed: MemoInputSeed
    let isEmojiPresentationEnabled: Bool
    let uiCommandEvent: MemoInputUIEvent?
    let onOutputEvent: ((MemoInputOutputEvent) -> Void)?

    @Binding var dynamicHeight: CGFloat

    let comfieUIBodyFont = UIFont(
        name: ComfieFontType.body.fontName.rawValue,
        size: ComfieFontType.body.fontSize)!
    let maxLineCount: CGFloat = 4

    init(
        _ placeholder: String,
        dynamicHeight: Binding<CGFloat>,
        inputSeed: MemoInputSeed,
        isEmojiPresentationEnabled: Bool,
        uiCommandEvent: MemoInputUIEvent?,
        onOutputEvent: ((MemoInputOutputEvent) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._dynamicHeight = dynamicHeight
        self.inputSeed = inputSeed
        self.isEmojiPresentationEnabled = isEmojiPresentationEnabled
        self.uiCommandEvent = uiCommandEvent
        self.onOutputEvent = onOutputEvent
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {

        let container = UIView()
        let textView = createTextView()
        let placeholderLabel = createPlaceholderLabel()

        let heightConstraint = createMaxHeightConstraint(for: textView)

        textView.delegate = context.coordinator
        // delegate만으로 놓치기 쉬운 IME 조합 시작/종료 경계를 직접 받아 Coordinator에 전달합니다.
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
        context.coordinator.applyStateToTextView(force: true)

        container.addSubview(textView)
        container.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 9),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 17)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {

        context.coordinator.parent = self
        context.coordinator.applyStateToTextView(force: false)
    }

    private func createTextView() -> MemoIMETrackingTextView {
        #if DEBUG
        // Debug UITest 세션에서만 테스트 전용 TextView 서브클래스를 주입합니다.
        if let uiTestTextView = createUITestTextViewIfNeeded() {
            return uiTestTextView
        }
        #endif

        return createReleaseTextView()
    }

    func createReleaseTextView() -> MemoIMETrackingTextView {
        let textView = MemoIMETrackingTextView()
        configureBaseTextView(textView)
        return textView
    }

    func configureBaseTextView(_ textView: MemoIMETrackingTextView) {
        textView.font = comfieUIBodyFont
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.keyBackground
        textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 8)
        textView.layer.cornerRadius = 12
        textView.clipsToBounds = true
        textView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func createPlaceholderLabel() -> UILabel {
        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholder
        placeholderLabel.font = comfieUIBodyFont
        placeholderLabel.textColor = UIColor.textGray
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        return placeholderLabel
    }

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

    func emitOutputEvent(_ event: MemoInputOutputEvent) {
        onOutputEvent?(event)
    }
}
