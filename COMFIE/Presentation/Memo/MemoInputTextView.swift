//
//  MemoInputTextView.swift
//  COMFIE
//
//  Created by zaehorang on 4/14/25.
//

import SwiftUI

struct MemoInputTextView: View {
    let placeholder: String
    @Binding private var intent: MemoStore
    
    @State private var dynamicHeight: CGFloat = UIFont(name: ComfieFontType.body.fontName.rawValue, size: ComfieFontType.body.fontSize)!.lineHeight + 18
    
    init(_ placeholder: String = "",
         memoStore: Binding<MemoStore>
    ) {
        self.placeholder = placeholder
        self._intent = memoStore
    }
    
    var body: some View {
        MemoInputUITextView(
            placeholder,
            dynamicHeight: $dynamicHeight,
            intent: $intent)
        .frame(height: dynamicHeight)
    }
}

#Preview {
    MemoInputTextView(
        memoStore: .constant(
            MemoStore(
                router: Router(),
                memoRepository: MockMemoRepository()
            )
        )
    )
}

struct MemoInputUITextView: UIViewRepresentable {
    let placeholder: String
    
    private var text: String {
        intent.state.inputMemoText
    }
    
    @Binding private var dynamicHeight: CGFloat
    @Binding private var intent: MemoStore
    
    let comfieUIBodyFont = UIFont(
        name: ComfieFontType.body.fontName.rawValue,
        size: ComfieFontType.body.fontSize)!
    let maxLineCount: CGFloat = 4
    
    init(_ placeholder: String,
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
        
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        context.coordinator.placeholderLabel = placeholderLabel
        
        container.addSubview(textView)
        container.addSubview(placeholderLabel)
        
        // 최대 4줄 높이 제한
        let maxHeight = comfieUIBodyFont.lineHeight
        * maxLineCount
        + textView.textContainerInset.top
        + textView.textContainerInset.bottom
        
        let heightConstraint = textView.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight)
        
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        context.coordinator.heightConstraint = heightConstraint
        
        NSLayoutConstraint.activate([
            textView.topAnchor
                .constraint(equalTo: container.topAnchor),
            textView.bottomAnchor
                .constraint(equalTo: container.bottomAnchor),
            textView.leadingAnchor
                .constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor
                .constraint(equalTo: container.trailingAnchor),
            
            placeholderLabel.topAnchor
                .constraint(equalTo: textView.topAnchor, constant: 9),
            placeholderLabel.leadingAnchor
                .constraint(equalTo: textView.leadingAnchor, constant: 12)
        ])
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        
        // 메모가 저장되어 비어지면 뷰 업데이트
        if intent.state.inputMemoText == "" {
            textView.text = intent.state.inputMemoText
            updatePlaceholderVisibility(textView: textView)
            
            Task { @MainActor in
                context.coordinator.updateHeight()
            }
        }
    }
    
    private func createTextView() -> UITextView {
        let textView = UITextView()
        
        textView.font = comfieUIBodyFont
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.keyBackground
        textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 8)
        textView.layer.cornerRadius = 12
        textView.clipsToBounds = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    private func updatePlaceholderVisibility(textView: UITextView) {
        guard let coordinator = textView.delegate as? Coordinator else { return }
        coordinator.placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        private var parent: MemoInputUITextView
        
        @Binding private var intent: MemoStore
        
        private var emogiString: EmogiString {
            intent.state.emogiString
        }
        
        weak var textView: UITextView!
        weak var placeholderLabel: UILabel!
        
        var heightConstraint: NSLayoutConstraint?
        
        init(parent: MemoInputUITextView, intent: Binding<MemoStore>) {
            self.parent = parent
            self._intent = intent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.updatePlaceholderVisibility(textView: textView)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // 한글 입력 시 뷰에 보이는 텍스트와 내부 데이터가 다를 수 있어
            // 편집 종료 시 최종 동기화 수행.
            intent.handleIntent(.memoInput(.updateNewMemo(textView.text)))
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let currentText = textView.text,
                  let textRange = Range(range, in: currentText) else {
                return true
            }
            
            let updatedText = currentText.replacingCharacters(in: textRange, with: text)
            print("🔍 변경 후 텍스트 예상: \(updatedText)")
            
            if !text.isEmpty { // 텍스트가 추가되는 경우
                if text == "\n" || text == " " {
                    let index = findEndCursorIndexInString(textView) + 1
                    intent.handleIntent(.memoInput(.transformTriggerDetected(index: index, newMemoText: updatedText)))
                    
                    updateText(textView)
                    
                    // 커서 위치 고정
                    let leftText = emogiString.getEmogiString(to: index)
                    if let position = textView.position(from: textView.beginningOfDocument, offset: leftText.utf16.count) {
                        textView.selectedTextRange = textView.textRange(from: position, to: position)
                    }
                    return false
                }
                
                intent.handleIntent(.memoInput(.updateNewMemo(updatedText)))
                updateHeight()
                return true
            } else { // 텍스트가 삭제되는 경우
                let endIndex = findEndCursorIndexInString(textView)
                let startIndex = findStartCursorIndexInString(textView)
                
                if startIndex == endIndex { // 한글자 삭제
                    intent.handleIntent(.memoInput(.deleteTriggerDetected(start: startIndex, end: nil)))
                    
                    updateText(textView)
                    
                    // 커서 위치 고정
                    let leftText = emogiString.getEmogiString(to: startIndex == 0 ? 0 : startIndex - 1)
                    if let position = textView.position(from: textView.beginningOfDocument, offset: leftText.utf16.count) {
                        print("leftText.utf16.count: \(leftText.utf16.count)")
                        textView.selectedTextRange = textView.textRange(from: position, to: position)
                    }
                } else { // 범위를 잡아서 삭제
                    intent.handleIntent(.memoInput(.deleteTriggerDetected(start: startIndex + 1, end: endIndex)))
                    
                    updateText(textView)
                    
                    // 커서 위치 고정
                    let leftText = emogiString.getEmogiString(to: startIndex - 1)
                    if let position = textView.position(from: textView.beginningOfDocument, offset: leftText.utf16.count) {
                        textView.selectedTextRange = textView.textRange(from: position, to: position)
                    }
                }
                return false
            }
        }
        
        private func updateText(_ textView: UITextView) {
            textView.text = emogiString.getEmogiString()
            intent.handleIntent(.memoInput(.updateNewMemo(textView.text)))
            updateHeight()
        }
        
        // 텍스트 내용에 따라 높이를 계산하고 제한된 높이까지 설정
        func updateHeight() {
            guard let textView = textView else { return }
            
            let width = textView.bounds.width
            guard width > 0 else { return }
            
            parent.updatePlaceholderVisibility(textView: textView)
            
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
            
            heightConstraint?.constant = targetHeight
            
            textView.isScrollEnabled = estimatedSize.height >= maxHeight
            
            parent.dynamicHeight = targetHeight
        }
        
        /// 커서 끝 위치를 String.Index로 반환
        /// - selectedRange는 UTF-16 기준으로, 복합 문자(이모지 등)와 문자 수(count)가 다를 수 있음
        private func getCursorEndIndex(_ textView: UITextView) -> String.Index? {
            guard let selectedRange = textView.selectedTextRange,
                  let text = textView.text else { return nil }
            
            let cursor = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
            let nsRange = NSRange(location: 0, length: cursor)
            return Range(nsRange, in: text)?.upperBound
        }
        
        /// 커서 시작 위치를 String.Index로 반환
        /// - selectedRange의 UTF-16 offset을 정확한 String.Index로 변환
        private func getCursorStartIndex(_ textView: UITextView) -> String.Index? {
            guard let selectedRange = textView.selectedTextRange,
                  let text = textView.text else { return nil }
            
            let cursor = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            let nsRange = NSRange(location: 0, length: cursor)
            return Range(nsRange, in: text)?.upperBound
        }
        
        /// 커서 끝 위치까지 문자의 개수를 Int 인덱스로 반환
        /// - getCursorEndIndex로 구한 String.Index 기준으로 계산
        private func findEndCursorIndexInString(_ textView: UITextView) -> Int {
            guard let cursorIndex = getCursorEndIndex(textView),
                  let text = textView.text else {
                print("findEndCursorIndexInString Error")
                return 0
            }
            let leftText = String(text[..<cursorIndex])
            
            return max(0, leftText.count - 1)
        }
        
        /// 커서 시작 위치까지 문자의 개수를 Int 인덱스로 반환
        /// - getCursorStartIndex로 구한 String.Index 기준으로 계산
        private func findStartCursorIndexInString(_ textView: UITextView) -> Int {
            guard let cursorIndex = getCursorStartIndex(textView),
                  let text = textView.text else {
                print("findStartCursorIndexInString Error")
                return 0
            }
            let leftText = String(text[..<cursorIndex])
            
            return max(0, leftText.count - 1)
        }
    }
}
