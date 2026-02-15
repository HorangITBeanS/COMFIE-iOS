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
    let onDraftAvailabilityChanged: (Bool, Int) -> Void
    let onFinalSnapshotReady: (UUID, MemoInputSnapshot) -> Void
    let onFinalSnapshotFailed: (UUID) -> Void

    @State private var dynamicHeight: CGFloat = 40

    init(
        _ placeholder: String = "",
        inputSeed: MemoInputSeed,
        isEmojiPresentationEnabled: Bool,
        uiCommandEvent: MemoInputUIEvent?,
        onDraftAvailabilityChanged: @escaping (Bool, Int) -> Void,
        onFinalSnapshotReady: @escaping (UUID, MemoInputSnapshot) -> Void,
        onFinalSnapshotFailed: @escaping (UUID) -> Void
    ) {
        self.placeholder = placeholder
        self.inputSeed = inputSeed
        self.isEmojiPresentationEnabled = isEmojiPresentationEnabled
        self.uiCommandEvent = uiCommandEvent
        self.onDraftAvailabilityChanged = onDraftAvailabilityChanged
        self.onFinalSnapshotReady = onFinalSnapshotReady
        self.onFinalSnapshotFailed = onFinalSnapshotFailed
    }

    var body: some View {
        MemoInputUITextView(
            placeholder,
            dynamicHeight: $dynamicHeight,
            inputSeed: inputSeed,
            isEmojiPresentationEnabled: isEmojiPresentationEnabled,
            uiCommandEvent: uiCommandEvent,
            onDraftAvailabilityChanged: onDraftAvailabilityChanged,
            onFinalSnapshotReady: onFinalSnapshotReady,
            onFinalSnapshotFailed: onFinalSnapshotFailed
        )
        .frame(height: dynamicHeight)
    }
}
