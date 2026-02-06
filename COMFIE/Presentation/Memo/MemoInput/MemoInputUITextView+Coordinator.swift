//
//  MemoInputUITextView+Coordinator.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import Combine
import SwiftUI
import UIKit

extension MemoInputUITextView {
    final class Coordinator: NSObject, UITextViewDelegate {
        // IME 조합 중 변경 범위를 추적하기 위한 구조체
        struct PendingChange {
            let range: NSRange
            let replacementLength: Int
        }

        private enum EndEditingSyncPolicy {
            case sync
            case skipOnce
        }

        var parent: MemoInputUITextView

        @Binding var intent: MemoStore

        weak var textView: UITextView!
        weak var placeholderLabel: UILabel!

        var textViewHeightConstraint: NSLayoutConstraint?

        private var cancellables = Set<AnyCancellable>()

        var isMutating = false
        // shouldChangeTextIn에서 잡은 변경을 textViewDidChange에서 처리한다.
        var pendingChange: PendingChange?
        // IME 조합 완료 시점까지 미뤄야 하는 변경을 보관한다.
        var deferredChange: PendingChange?
        var lastSelectionRange = NSRange(location: 0, length: 0)
        var lastTextChangeTime: TimeInterval = 0
        var lastTextLength = 0
        var lastEmojiMode: Bool?
        private var endEditingSyncPolicy: EndEditingSyncPolicy = .sync

        var isEmojiMode: Bool {
            !intent.state.isInComfieZone
        }

        init(parent: MemoInputUITextView, intent: Binding<MemoStore>) {
            self.parent = parent
            self._intent = intent
        }

        /// MemoStore에서 전달된 sideEffect를 감지하여 포커스를 제어하거나, 상태 기반으로 입력 뷰를 갱신합니다.
        func bindFocusControl() {
            intent.uiSideEffectPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sideEffect in
                    guard let self else { return }
                    switch sideEffect {
                    case .resignInputFocusWithSyncInput:
                        syncSnapshotToStoreIfPossible()
                        endEditingSyncPolicy = .sync
                        if let textView {
                            unfocusTextView(textView)
                        }
                    case .resignInputFocusWithoutSync:
                        endEditingSyncPolicy = .skipOnce
                        if let textView {
                            unfocusTextView(textView)
                        }
                    case .requestFinalSyncAndResign(let requestID):
                        endEditingSyncPolicy = .skipOnce
                        let currentSnapshot: (original: String, emoji: String)
                        if let textView {
                            currentSnapshot = snapshot(from: textView.textStorage)
                        } else {
                            let originalText = normalizedOriginalText()
                            let emojiText = normalizedEmojiText(with: originalText)
                            currentSnapshot = (original: originalText, emoji: emojiText)
                        }
                        let emojiText = isEmojiMode ? currentSnapshot.emoji : currentSnapshot.original

                        intent.handleIntent(
                            .memoInput(
                                .finalSyncCompleted(
                                    requestID: requestID,
                                    originalText: currentSnapshot.original,
                                    emojiText: emojiText
                                )
                            )
                        )
                        if let textView {
                            unfocusTextView(textView)
                        }
                    case .setMemoInputFocus:
                        endEditingSyncPolicy = .sync
                        if let textView {
                            focusTextView(textView)
                        }
                    }
                }
                .store(in: &cancellables)
        }

        func applyStateToTextView(force: Bool) {
            guard let textView else { return }

            let normalizedOriginal = normalizedOriginalText()
            let normalizedEmoji = normalizedEmojiText(with: normalizedOriginal)
            let currentSnapshot = snapshot(from: textView.textStorage)
            let modeChanged = lastEmojiMode != isEmojiMode

            // 스냅샷이 동일하면 렌더링을 건너뛰어 커서 튐을 줄인다.
            if !force, !modeChanged {
                let isSameSnapshot = currentSnapshot.original == normalizedOriginal
                    && (isEmojiMode ? currentSnapshot.emoji == normalizedEmoji : currentSnapshot.original == normalizedOriginal)
                if isSameSnapshot {
                    return
                }
            }

            let oldSelection = textView.selectedRange
            isMutating = true

            if isEmojiMode {
                // 이모지 모드에서는 토큰 attachment로 렌더링한다.
                textView.attributedText = attributedText(
                    originalText: normalizedOriginal,
                    emojiText: normalizedEmoji,
                    font: parent.comfieUIBodyFont
                )
            } else {
                textView.text = normalizedOriginal
            }

            textView.selectedRange = clampedSelection(oldSelection, maxLength: textView.textStorage.length)
            isMutating = false

            updatePlaceholderVisibility(textView)
            updateTextViewHeight(textView)
            lastTextLength = textView.textStorage.length
            lastSelectionRange = textView.selectedRange
            lastEmojiMode = isEmojiMode
        }

        // MARK: - UITextViewDelegate

        func textViewDidChange(_ textView: UITextView) {
            guard !isMutating else {
                pendingChange = nil
                return
            }

            updatePlaceholderVisibility(textView)
            updateTextViewHeight(textView)

            if lastEmojiMode == nil {
                lastEmojiMode = isEmojiMode
            } else if lastEmojiMode != isEmojiMode, textView.markedTextRange == nil {
                if isEmojiMode {
                    convertAllPlainToEmoji(in: textView)
                } else {
                    convertAllToPlain(in: textView)
                }
                lastEmojiMode = isEmojiMode
            }

            if isEmojiMode {
                // IME 조합 여부에 따라 변환 시점을 분리한다.
                let isComposing = (textView.markedTextRange != nil)
                if isComposing, let markedTextRange = textView.markedTextRange {
                    let marked = textView.memoIME_nsRange(from: markedTextRange)
                    handleMarkedRange(in: textView, marked: marked)
                    deferPendingChangeIfNeeded()
                } else {
                    if let change = pendingChange ?? deferredChange {
                        handleNonMarkedChange(in: textView, change: change)
                    } else {
                        handleFallbackInsertion(in: textView)
                    }
                    deferredChange = nil
                }
            }
            pendingChange = nil

            syncSnapshotToStore(textView)
            lastTextLength = textView.textStorage.length
            lastSelectionRange = textView.selectedRange
            lastTextChangeTime = Date().timeIntervalSinceReferenceDate
            lastEmojiMode = isEmojiMode
        }

        /// 편집 종료 시 최종 snapshot 동기화 수행
        func textViewDidEndEditing(_ textView: UITextView) {
            if endEditingSyncPolicy == .skipOnce {
                endEditingSyncPolicy = .sync
                return
            }
            syncSnapshotToStore(textView)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard isEmojiMode else {
                pendingChange = nil
                return true
            }

            pendingChange = PendingChange(
                range: range,
                replacementLength: (text as NSString).length
            )
            return true
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            defer { lastSelectionRange = textView.selectedRange }

            guard isEmojiMode else { return }
            guard !isMutating else { return }
            guard textView.markedTextRange == nil else { return }
            guard !NSEqualRanges(lastSelectionRange, textView.selectedRange) else { return }

            let now = Date().timeIntervalSinceReferenceDate
            guard now - lastTextChangeTime > 0.05 else { return }

            flushPendingConversionOnCursorMove(in: textView)
        }
    }
}
