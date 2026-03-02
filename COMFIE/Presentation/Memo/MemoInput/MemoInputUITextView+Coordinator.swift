//
//  MemoInputUITextView+Coordinator.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import SwiftUI
import UIKit

extension MemoInputUITextView {
    // IME 조합 입력 타이밍 이슈를 줄이기 위해 입력 상태 조율을 Coordinator에 모읍니다.
    final class Coordinator: NSObject, UITextViewDelegate {
        struct PendingChange {
            let range: NSRange
            let replacementUTF16Length: Int
            let replacementCharacterCount: Int
        }

        private enum EndEditingSyncPolicy {
            case sync
            case skipOnce
        }

        var parent: MemoInputUITextView

        weak var textView: UITextView!
        weak var placeholderLabel: UILabel!

        var textViewHeightConstraint: NSLayoutConstraint?

        var isMutating = false
        private(set) var pendingChange: PendingChange?
        private(set) var deferredChange: PendingChange?
        var lastSelectionRange = NSRange(location: 0, length: 0)
        var lastTextChangeTime: TimeInterval = 0
        var lastTextLength = 0
        var lastEmojiMode: Bool?
        var lastAppliedInputSeedToken = 0
        var lastHandledUICommandID: UUID?

        private var endEditingSyncPolicy: EndEditingSyncPolicy = .sync

        private(set) var draftOriginalText = ""
        private(set) var draftEmojiText = ""
        private(set) var draftRevision = 0

        var isEmojiMode: Bool {
            parent.isEmojiPresentationEnabled
        }

        init(parent: MemoInputUITextView) {
            self.parent = parent
            self.draftOriginalText = parent.inputSeed.originalText
            self.draftEmojiText = parent.inputSeed.emojiText
            self.lastAppliedInputSeedToken = parent.inputSeed.token
        }

        func replaceDraft(original: String, emoji: String) {
            let hasChanged = draftOriginalText != original || draftEmojiText != emoji
            if hasChanged {
                draftRevision += 1
            }
            draftOriginalText = original
            draftEmojiText = emoji
        }

        func setPendingChange(_ change: PendingChange?) {
            pendingChange = change
        }

        func setDeferredChange(_ change: PendingChange?) {
            deferredChange = change
        }

        func clearPendingAndDeferredChanges() {
            pendingChange = nil
            deferredChange = nil
        }

        func pendingOrDeferredChange() -> PendingChange? {
            pendingChange ?? deferredChange
        }

#if DEBUG
        // 테스트에서 stale draft 주입 시나리오를 재현하기 위한 훅입니다.
        func debugInjectDraftForTesting(original: String, emoji: String) {
            replaceDraft(original: original, emoji: emoji)
        }

        // 테스트에서 stale deferred/pending 시나리오를 재현하기 위한 훅입니다.
        func debugInjectChangeForTesting(range: NSRange, replacementLength: Int, asDeferred: Bool) {
            let change = PendingChange(
                range: range,
                replacementUTF16Length: replacementLength,
                replacementCharacterCount: replacementLength
            )
            if asDeferred {
                setDeferredChange(change)
            } else {
                setPendingChange(change)
            }
        }

        // 테스트에서 stale change 큐가 비워졌는지 확인하기 위한 훅입니다.
        func debugHasPendingOrDeferredChangeForTesting() -> Bool {
            pendingChange != nil || deferredChange != nil
        }
#endif

        // seed/모드/명령 이벤트를 합쳐 현재 UITextView 상태를 일관되게 재적용합니다.
        func applyStateToTextView(force: Bool) {
            handleUICommandIfNeeded()
            guard let textView else { return }

            let modeChanged = lastEmojiMode != isEmojiMode
            let seedTokenChanged = lastAppliedInputSeedToken != parent.inputSeed.token

            if force || seedTokenChanged {
                let seededOriginal = normalizedOriginalText()
                let seededEmoji = normalizedEmojiText(with: seededOriginal)
                render(
                    textView,
                    originalText: seededOriginal,
                    emojiText: seededEmoji
                )
                syncDraftCache(
                    originalText: seededOriginal,
                    emojiText: seededEmoji
                )
                publishDraftAvailability()
                clearPendingAndDeferredChanges()
                lastAppliedInputSeedToken = parent.inputSeed.token
                lastEmojiMode = isEmojiMode
            }

            guard modeChanged else {
                updateTextViewHeight(textView)
                return
            }
            // 조합 중에는 모드 강제 렌더를 미뤄 IME 입력이 깨지지 않게 보호합니다.
            guard textView.markedTextRange == nil else { return }

            clearPendingAndDeferredChanges()
            render(
                textView,
                originalText: draftOriginalText,
                emojiText: draftEmojiText
            )
            lastEmojiMode = isEmojiMode
            publishDraftAvailability()
        }

        private func flushAndSyncIfPossible(_ textView: UITextView?) {
            guard let textView else { return }
            flushPendingConversionBeforeSync(in: textView)
            syncSnapshotToStore(textView)
        }

        // MARK: - UITextViewDelegate

        func textViewDidChange(_ textView: UITextView) {
            guard !isMutating else {
                clearPendingAndDeferredChanges()
                return
            }

            updatePlaceholderVisibility(textView)
            updateTextViewHeight(textView)

            if lastEmojiMode == nil {
                lastEmojiMode = isEmojiMode
            } else if lastEmojiMode != isEmojiMode, textView.markedTextRange == nil {
                clearPendingAndDeferredChanges()
                if isEmojiMode {
                    convertAllPlainToEmoji(in: textView)
                } else {
                    convertAllToPlain(in: textView)
                }
                lastEmojiMode = isEmojiMode
            }

            if isEmojiMode {
                let isComposing = (textView.markedTextRange != nil)
                if isComposing {
                    deferPendingChangeIfNeeded()
                    setPendingChange(nil)
                } else {
                    if let change = pendingOrDeferredChange() {
                        handleNonMarkedChange(in: textView, change: change)
                    } else {
                        handleFallbackInsertion(in: textView)
                    }
                    clearPendingAndDeferredChanges()
                }
            } else {
                clearPendingAndDeferredChanges()
            }

            syncSnapshotToStore(textView)
            lastTextLength = textView.textStorage.length
            lastSelectionRange = textView.selectedRange
            lastTextChangeTime = Date().timeIntervalSinceReferenceDate
            lastEmojiMode = isEmojiMode
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if endEditingSyncPolicy == .skipOnce {
                endEditingSyncPolicy = .sync
                return
            }
            flushAndSyncIfPossible(textView)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard isEmojiMode else {
                clearPendingAndDeferredChanges()
                return true
            }

            setPendingChange(PendingChange(
                range: range,
                replacementUTF16Length: (text as NSString).length,
                replacementCharacterCount: text.count
            ))
            return true
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            defer { lastSelectionRange = textView.selectedRange }

            guard isEmojiMode else { return }
            guard !isMutating else { return }
            // 조합 중 커서 이동 이벤트는 flush 기준이 아니므로 건너뜁니다.
            guard textView.markedTextRange == nil else { return }
            guard !NSEqualRanges(lastSelectionRange, textView.selectedRange) else { return }

            let now = Date().timeIntervalSinceReferenceDate
            guard now - lastTextChangeTime > 0.05 else { return }

            flushPendingConversionOnCursorMove(in: textView)
        }
    }
}

// MARK: - UI Command
extension MemoInputUITextView.Coordinator {
    private func handleUICommandIfNeeded() {
        guard let commandEvent = parent.uiCommandEvent else { return }
        guard commandEvent.id != lastHandledUICommandID else { return }
        lastHandledUICommandID = commandEvent.id
        handleUICommand(commandEvent.command)
    }

    // Store에서 내려온 입력 명령을 한 번만 실행하고 sync 정책을 함께 조정합니다.
    private func handleUICommand(_ command: MemoInputUICommand) {
        switch command {
        case .resignWithSync:
            if let textView {
                flushAndSyncIfPossible(textView)
                unfocusTextView(textView)
            } else {
                syncDraftFromFallbackIfNeeded()
            }
            endEditingSyncPolicy = .sync

        case .resignWithoutSync:
            endEditingSyncPolicy = .skipOnce
            if let textView {
                unfocusTextView(textView)
            }

        case .requestFinalSyncAndResign(let requestID):
            // 조합 강제 확정 + flush/sync를 먼저 수행해 최종 스냅샷 기준을 고정합니다.
            guard prepareDraftForFinalSnapshot(textView) else {
                endEditingSyncPolicy = .sync
                parent.emitOutputEvent(.finalSnapshotFailed(requestID: requestID))
                if let textView {
                    endEditingSyncPolicy = .skipOnce
                    unfocusTextView(textView)
                }
                return
            }

            // 이 분기는 빈 스냅샷 저장을 막고 Store savePhase를 정상 복귀시키기 위한 안전장치입니다.
            if draftOriginalText.isEmpty,
               draftEmojiText.isEmpty,
               parent.inputSeed.originalText.isEmpty,
               parent.inputSeed.emojiText.isEmpty {
                endEditingSyncPolicy = .sync
                parent.emitOutputEvent(.finalSnapshotFailed(requestID: requestID))
                return
            }

            // requestID를 함께 보내 Store가 같은 저장 요청인지 검증할 수 있게 합니다.
            let inputSnapshot = MemoInputSnapshot(
                originalText: draftOriginalText,
                emojiText: draftEmojiText
            )
            parent.emitOutputEvent(
                .finalSnapshotReady(
                    requestID: requestID,
                    snapshot: inputSnapshot
                )
            )

            if let textView {
                endEditingSyncPolicy = .skipOnce
                unfocusTextView(textView)
            } else {
                endEditingSyncPolicy = .sync
            }

        case .setFocus:
            endEditingSyncPolicy = .sync
            if let textView {
                focusTextView(textView)
            }
        }
    }

    private func finalizeCompositionIfNeeded(_ textView: UITextView) -> Bool {
        guard textView.markedTextRange != nil else { return true }
        textView.unmarkText()
        return textView.markedTextRange == nil
    }

    private func prepareDraftForFinalSnapshot(_ textView: UITextView?) -> Bool {
        guard let textView else {
            syncDraftFromFallbackIfNeeded()
            return true
        }
        guard finalizeCompositionIfNeeded(textView) else { return false }
        flushAndSyncIfPossible(textView)
        return true
    }
}
