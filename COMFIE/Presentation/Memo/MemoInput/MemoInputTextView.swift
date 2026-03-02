//
//  MemoInputTextView.swift
//  COMFIE
//
//  Created by zaehorang on 4/14/25.
//

import SwiftUI

struct MemoInputTextView: View {
    let placeholder: String
    let inputSeed: MemoInputSeed
    let isEmojiPresentationEnabled: Bool
    let uiCommandEvent: MemoInputUIEvent?
    let onOutputEvent: ((MemoInputOutputEvent) -> Void)?

    @State private var dynamicHeight: CGFloat = 40

    init(
        _ placeholder: String = "",
        inputSeed: MemoInputSeed,
        isEmojiPresentationEnabled: Bool,
        uiCommandEvent: MemoInputUIEvent?,
        onOutputEvent: ((MemoInputOutputEvent) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.inputSeed = inputSeed
        self.isEmojiPresentationEnabled = isEmojiPresentationEnabled
        self.uiCommandEvent = uiCommandEvent
        self.onOutputEvent = onOutputEvent
    }

    var body: some View {
        MemoInputUITextView(
            placeholder,
            dynamicHeight: $dynamicHeight,
            inputSeed: inputSeed,
            isEmojiPresentationEnabled: isEmojiPresentationEnabled,
            uiCommandEvent: uiCommandEvent,
            onOutputEvent: onOutputEvent
        )
        .frame(height: dynamicHeight)
    }
}
