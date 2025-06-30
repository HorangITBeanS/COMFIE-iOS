//
//  MemoInputUITextView.swift
//  COMFIE
//
//  Created by zaehorang on 5/29/25.
//

import Combine
import SwiftUI

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
        
        let heightConstraint = createMaxHeightConstraint(for: textView)
        
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        context.coordinator.placeholderLabel = placeholderLabel
        
        context.coordinator.textViewHeightConstraint = heightConstraint
        
        context.coordinator.bindFocusControl()
        
        container.addSubview(textView)
        container.addSubview(placeholderLabel)
        
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
            
            // textView의 커서 위치와 플레이스홀더의 정렬을 맞추기 위해 오른쪽으로 5pt 추가
            placeholderLabel.leadingAnchor
                .constraint(equalTo: textView.leadingAnchor, constant: 17)
        ])
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
    
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
    
    final class Coordinator: NSObject, UITextViewDelegate {
        private var parent: MemoInputUITextView
        
        @Binding private var intent: MemoStore
        
        private var emojiString: EmojiString {
            intent.state.emojiString
        }
        
        weak var textView: UITextView!
        weak var placeholderLabel: UILabel!
        
        var textViewHeightConstraint: NSLayoutConstraint?
        
        private var cancellables = Set<AnyCancellable>()
        
        init(parent: MemoInputUITextView, intent: Binding<MemoStore>) {
            self.parent = parent
            self._intent = intent
        }
        
        /// MemoStore에서 전달된 sideEffect를 감지하여 포커스를 제어하거나, 상태 기반으로 입력 뷰를 갱신합니다.
        func bindFocusControl() {
            intent.uiSideEffectPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sideEffect in
                    guard let self = self else { return }
                    switch sideEffect {
                    case .resignInputFocusWithSyncInput:
                        self.unfocusTextView(textView)
                    case .setMemoInputFocus:
                        self.focusTextView(textView)
                    case .updateInputViewWithState:
                        self.textView.text = intent.state.inputMemoText
                        
                        updatePlaceholderVisibility(textView)
                        updateTextViewHeight(textView)
                    }
                }
                .store(in: &cancellables)
        }
        
        // MARK: - UITextViewDelegate
        
        func textViewDidChange(_ textView: UITextView) {
            updatePlaceholderVisibility(textView)
        }
        
        /// 해담 메서드에서 최졷 동기화를 해야지 한글이 완전히 완성된 상태에서 동기화가 가능
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
            
            if !text.isEmpty { // 텍스트가 추가되는 경우
                if text == "\n" || text == " " {
                    handleEmojiTransformTrigger(textView, updatedText: updatedText)
                    
                    return false
                }
                
                intent.handleIntent(.memoInput(.updateNewMemo(updatedText)))
                updateTextViewHeight(textView)
                
                return true
            } else { // 텍스트가 삭제되는 경우
                // 한글 입력 시 뷰에 보이는 텍스트와 내부 데이터가 다를 수 있어
                // 편집 종료 시 최종 동기화 수행.
                intent.handleIntent(.memoInput(.updateNewMemo(textView.text)))
                handleTextDeletion(textView)
                
                return false
            }
        }
        
        // MARK: - TextView Handling
        
        private func handleEmojiTransformTrigger(_ textView: UITextView, updatedText: String) {
            let index = findEndCursorIndexInString(textView) + 1
            
            intent.handleIntent(.memoInput(.transformTriggerDetected(index: index, newMemoText: updatedText)))
            updateText(textView)
            updateTextViewHeight(textView)
            
            // 커서 위치 고정
            let leftText = emojiString.getEmojiString(to: index)
            moveCursor(toLeftText: leftText)
        }
        
        /// 삭제 로직을 처리하는  메서드
        private func handleTextDeletion(_ textView: UITextView) {
            intent.handleIntent(.memoInput(.updateNewMemo(textView.text)))
            
            let endIndex = findEndCursorIndexInString(textView)
            let startIndex = findStartCursorIndexInString(textView)
            
            if startIndex == endIndex { // 한 글자 삭제
                intent.handleIntent(.memoInput(.deleteTriggerDetected(start: startIndex, end: nil)))
            } else { // 범위 잡아서 삭제
                intent.handleIntent(.memoInput(
                    .deleteTriggerDetected(
                        start: startIndex + 1, end: endIndex
                    )
                ))
            }
            updateText(textView)
            updateTextViewHeight(textView)
            
            // 커서 위치 변경
            let leftText = emojiString.getEmojiString(to: startIndex - 1)
            moveCursor(toLeftText: leftText)
        }
        
        private func updateText(_ textView: UITextView) {
            let updatedText = emojiString.getEmojiString()
            
            textView.text = updatedText
            intent.handleIntent(.memoInput(.updateNewMemo(updatedText)))
        }
        
        private func updatePlaceholderVisibility(_ textView: UITextView) {
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
        
        /// 텍스트 내용에 따라 높이를 계산하고 제한된 높이까지 설정
        private func updateTextViewHeight(_ textView: UITextView) {
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
            
            parent.dynamicHeight = targetHeight
        }
        
        private func focusTextView(_ textView: UITextView) {
            textView.becomeFirstResponder()
        }
        
        private func unfocusTextView(_ textView: UITextView) {
            textView.resignFirstResponder()
        }
        
        // MARK: - Cursor Handling
        
        /// 커서를 leftText의 끝(UTF-16 기준 오프셋)으로 이동
        private func moveCursor(toLeftText leftText: String) {
            guard let textView = textView,
                  let position = textView.position(from: textView.beginningOfDocument, offset: leftText.utf16.count) else { return }
            textView.selectedTextRange = textView.textRange(from: position, to: position)
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
        /// - 커서가 문자열의 맨 앞(시작) 위치에 있으면 -1을 반환합니다.
        /// - 참고: 이 값은 삭제 로직에서 특별한 의미(삭제 안 함)로 사용됩니다.
        private func findEndCursorIndexInString(_ textView: UITextView) -> Int {
            guard let cursorIndex = getCursorEndIndex(textView),
                  let text = textView.text else {
                print("findEndCursorIndexInString Error")
                return 0
            }
            let leftText = String(text[..<cursorIndex])
            
            return leftText.count - 1
        }
        
        /// 커서 시작 위치까지 문자의 개수를 Int 인덱스로 반환
        /// - getCursorStartIndex로 구한 String.Index 기준으로 계산
        /// - 커서가 문자열의 맨 앞(시작) 위치에 있으면 -1을 반환합니다.
        /// - 참고: 이 값은 삭제 로직에서 특별한 의미(삭제 안 함)로 사용됩니다.
        private func findStartCursorIndexInString(_ textView: UITextView) -> Int {
            guard let cursorIndex = getCursorStartIndex(textView),
                  let text = textView.text else {
                print("findStartCursorIndexInString Error")
                return 0
            }
            let leftText = String(text[..<cursorIndex])
            
            return leftText.count - 1
        }
    }
}
