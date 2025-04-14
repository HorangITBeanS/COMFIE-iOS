//
//  MemoInputTextView.swift
//  COMFIE
//
//  Created by zaehorang on 4/14/25.
//

import SwiftUI

struct MemoInputTextView: View {
    let placeholder: String
    
    @Binding private var text: String
    @Binding private var isTextViewFocused: Bool
    
    @State private var dynamicHeight: CGFloat = UIFont(name: ComfieFontType.body.fontName.rawValue, size: ComfieFontType.body.fontSize)!.lineHeight + 18
    
    init(_ placeholder: String = "",
         text: Binding<String>,
         isTextViewFocused: Binding<Bool>
    ) {
        self.placeholder = placeholder
        self._text = text
        self._isTextViewFocused = isTextViewFocused
    }
    
    var body: some View {
        MemoInputUITextView(
            placeholder,
            text: $text,
            isTextViewFocused: $isTextViewFocused,
            dynamicHeight: $dynamicHeight)
        .frame(height: dynamicHeight)
    }
}

#Preview {
    MemoInputTextView(
        text: .constant(""),
        isTextViewFocused: .constant(false)
    )
}

struct MemoInputUITextView: UIViewRepresentable {
    let placeholder: String
    
    @Binding var text: String
    @Binding var isTextViewFocused: Bool
    @Binding var dynamicHeight: CGFloat
    
    let comfieUIBodyFont = UIFont(
        name: ComfieFontType.body.fontName.rawValue,
        size: ComfieFontType.body.fontSize)!
    let maxLineCount: CGFloat = 4
    
    init(_ placeholder: String,
         text: Binding<String>,
         isTextViewFocused: Binding<Bool>,
         dynamicHeight: Binding<CGFloat>
    ) {
        self.placeholder = placeholder
        self._text = text
        self._isTextViewFocused = isTextViewFocused
        self._dynamicHeight = dynamicHeight
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
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

        // 바인딩된 text와 실제 textView의 값이 다르면 업데이트
        if textView.text != text {
            textView.text = text
            context.coordinator.updateHeight()
        }

        updatePlaceholderVisibility(textView: textView)
      
        if isTextViewFocused && !textView.isFirstResponder {
            textView.becomeFirstResponder()
        } else if !isTextViewFocused && textView.isFirstResponder {
            textView.resignFirstResponder()
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
        coordinator.placeholderLabel.isHidden = isTextViewFocused || !textView.text.isEmpty
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MemoInputUITextView
        
        weak var textView: UITextView!
        weak var placeholderLabel: UILabel!
        
        var heightConstraint: NSLayoutConstraint?
        
        init(parent: MemoInputUITextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            updateHeight()
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isTextViewFocused = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isTextViewFocused = false
        }
        
        // 텍스트 내용에 따라 높이를 계산하고 제한된 높이까지 설정
        func updateHeight() {
            guard let textView = textView else { return }
            
            let width = textView.bounds.width
            guard width > 0 else { return }
            
            parent.text = textView.text
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
    }
}
