//
//  MemoInputUITextView+Coordinator.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import SwiftUI
import UIKit

extension MemoInputUITextView {
    final class Coordinator: NSObject, UITextViewDelegate {
        struct PendingChange {
            let range: NSRange
            let replacementLength: Int
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
        var pendingChange: PendingChange?
        var deferredChange: PendingChange?
        var lastSelectionRange = NSRange(location: 0, length: 0)
        var lastTextChangeTime: TimeInterval = 0
        var lastTextLength = 0
        var lastEmojiMode: Bool?
        var lastAppliedInputSeedToken = 0
        var lastHandledUICommandID: UUID?

        private var endEditingSyncPolicy: EndEditingSyncPolicy = .sync

        var draftOriginalText = ""
        var draftEmojiText = ""
        var draftRevision = 0

        var isEmojiMode: Bool {
            parent.isEmojiPresentationEnabled
        }

        init(parent: MemoInputUITextView) {
            self.parent = parent
            self.draftOriginalText = parent.inputSeed.originalText
            self.draftEmojiText = parent.inputSeed.emojiText
            self.lastAppliedInputSeedToken = parent.inputSeed.token
        }

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
                let isSeedChanged = draftOriginalText != seededOriginal || draftEmojiText != seededEmoji
                syncDraftCache(
                    originalText: seededOriginal,
                    emojiText: seededEmoji,
                    revision: isSeedChanged ? draftRevision + 1 : draftRevision
                )
                publishDraftAvailability()
                pendingChange = nil
                deferredChange = nil
                lastAppliedInputSeedToken = parent.inputSeed.token
                lastEmojiMode = isEmojiMode
            }

            guard modeChanged else {
                updateTextViewHeight(textView)
                return
            }
            guard textView.markedTextRange == nil else { return }

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

        func textViewDidEndEditing(_ textView: UITextView) {
            if endEditingSyncPolicy == .skipOnce {
                endEditingSyncPolicy = .sync
                return
            }
            flushAndSyncIfPossible(textView)
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

// MARK: - UI Command
extension MemoInputUITextView.Coordinator {
    private func handleUICommandIfNeeded() {
        guard let commandEvent = parent.uiCommandEvent else { return }
        guard commandEvent.id != lastHandledUICommandID else { return }
        lastHandledUICommandID = commandEvent.id
        handleUICommand(commandEvent.command)
    }

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
            endEditingSyncPolicy = .skipOnce
            if let textView {
                flushAndSyncIfPossible(textView)
            } else {
                syncDraftFromFallbackIfNeeded()
            }

            if draftOriginalText.isEmpty,
               draftEmojiText.isEmpty,
               parent.inputSeed.originalText.isEmpty,
               parent.inputSeed.emojiText.isEmpty {
                parent.onFinalSnapshotFailed(requestID)
                return
            }

            let inputSnapshot = MemoInputSnapshot(
                originalText: draftOriginalText,
                emojiText: draftEmojiText,
                revision: draftRevision
            )
            parent.onFinalSnapshotReady(requestID, inputSnapshot)

            if let textView {
                unfocusTextView(textView)
            }

        case .setFocus:
            endEditingSyncPolicy = .sync
            if let textView {
                focusTextView(textView)
            }
        }
    }
}
