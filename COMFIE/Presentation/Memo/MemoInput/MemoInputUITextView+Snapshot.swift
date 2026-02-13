//
//  MemoInputUITextView+Snapshot.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

extension MemoInputUITextView.Coordinator {
    // MARK: - Snapshot/Rendering

    func normalizedOriginalText() -> String {
        // Store seed에 원문이 있으면 이를 우선 사용한다.
        if !intent.state.inputOriginalText.isEmpty {
            return intent.state.inputOriginalText
        }
        return intent.state.inputMemoText
    }

    func normalizedEmojiText(with originalText: String) -> String {
        // Store seed에 emoji 스냅샷이 없으면 원문을 사용한다.
        if !intent.state.inputMemoText.isEmpty {
            return intent.state.inputMemoText
        }
        return originalText
    }

    func syncSnapshotToStoreIfPossible() {
        guard let textView else { return }
        syncSnapshotToStore(textView)
    }

    func syncSnapshotToStore(_ textView: UITextView) {
        let currentSnapshot = snapshot(from: textView.textStorage)
        let emojiTextCandidate = isEmojiMode ? currentSnapshot.emoji : currentSnapshot.original

        updateDraft(
            originalText: currentSnapshot.original,
            emojiTextCandidate: emojiTextCandidate
        )
        publishDraftAvailability()
    }

    func syncDraftFromFallbackIfNeeded() {
        guard draftOriginalText.isEmpty && draftEmojiText.isEmpty else { return }

        let originalText = normalizedOriginalText()
        let emojiText = normalizedEmojiText(with: originalText)
        syncDraftCache(
            originalText: originalText,
            emojiText: emojiText,
            revision: intent.state.inputSnapshotRevision
        )
    }

    func publishDraftAvailability() {
        intent.handleIntent(
            .memoInput(
                .draftAvailabilityChangedWithRevision(
                    isEmpty: draftEmojiText.isEmpty,
                    revision: draftRevision
                )
            )
        )
    }

    func snapshot(from storage: NSAttributedString) -> (original: String, emoji: String) {
        var original = ""
        var emoji = ""
        let fullRange = NSRange(location: 0, length: storage.length)

        // attachment 토큰은 원문/이모지를 각각 복원한다.
        storage.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            if let token = attributes[.attachment] as? MemoEmojiTokenAttachment {
                original.append(token.original)
                emoji.append(token.emoji)
            } else {
                let plain = storage.attributedSubstring(from: range).string
                original.append(plain)
                emoji.append(plain)
            }
        }

        return (original, emoji)
    }

    func render(_ textView: UITextView, originalText: String, emojiText: String) {
        let oldSelection = textView.selectedRange
        isMutating = true

        if isEmojiMode {
            textView.attributedText = attributedText(
                originalText: originalText,
                emojiText: emojiText,
                font: parent.comfieUIBodyFont
            )
        } else {
            textView.text = originalText
        }

        textView.selectedRange = clampedSelection(oldSelection, maxLength: textView.textStorage.length)
        isMutating = false

        updatePlaceholderVisibility(textView)
        updateTextViewHeight(textView)
        lastTextLength = textView.textStorage.length
        lastSelectionRange = textView.selectedRange
    }

    func attributedText(originalText: String, emojiText: String, font: UIFont) -> NSAttributedString {
        let originalCharacters = Array(originalText)
        let emojiCharacters = Array(emojiText)
        let count = min(originalCharacters.count, emojiCharacters.count)

        let result = NSMutableAttributedString()

        if count == 0 {
            return NSAttributedString(string: originalText, attributes: [.font: font])
        }

        // 원문과 이모지가 다른 지점만 토큰 attachment로 치환한다.
        for index in 0..<count {
            let originalCharacter = originalCharacters[index]
            let emojiCharacter = emojiCharacters[index]

            if originalCharacter == emojiCharacter {
                result.append(NSAttributedString(string: String(originalCharacter), attributes: [.font: font]))
            } else {
                result.append(
                    tokenAttributedString(
                        original: String(originalCharacter),
                        emoji: String(emojiCharacter),
                        font: font
                    )
                )
            }
        }

        if originalCharacters.count > count {
            for originalCharacter in originalCharacters[count...] {
                result.append(NSAttributedString(string: String(originalCharacter), attributes: [.font: font]))
            }
        }

        return result
    }

    func tokenAttributedString(original: String, emoji: String, font: UIFont) -> NSAttributedString {
        let attachment = MemoEmojiTokenAttachment(original: original, emoji: emoji, font: font)
        let token = NSMutableAttributedString(attachment: attachment)
        token.addAttribute(.font, value: font, range: NSRange(location: 0, length: token.length))
        return token
    }

    func clampedSelection(_ selection: NSRange, maxLength: Int) -> NSRange {
        let location = min(max(0, selection.location), maxLength)
        let maxAvailableLength = max(0, maxLength - location)
        let length = min(max(0, selection.length), maxAvailableLength)
        return NSRange(location: location, length: length)
    }

    func updateDraft(originalText: String, emojiTextCandidate: String) {
        let resolvedEmojiText: String
        if isEmojiMode {
            resolvedEmojiText = emojiTextCandidate
        } else {
            let seededPreviousEmojiText: String
            if draftOriginalText.isEmpty,
               draftEmojiText.isEmpty,
               emojiTextCandidate.count == originalText.count {
                seededPreviousEmojiText = emojiTextCandidate
            } else {
                seededPreviousEmojiText = draftEmojiText
            }

            resolvedEmojiText = EmojiString.mergedEmojiTextPreservingUnchanged(
                previousOriginalText: draftOriginalText,
                previousEmojiText: seededPreviousEmojiText,
                newOriginalText: originalText
            )
        }

        let hasDraftChanged = draftOriginalText != originalText || draftEmojiText != resolvedEmojiText
        if hasDraftChanged {
            draftRevision += 1
        }

        draftOriginalText = originalText
        draftEmojiText = resolvedEmojiText
    }

    func syncDraftCache(originalText: String, emojiText: String, revision: Int) {
        draftOriginalText = originalText
        draftEmojiText = emojiText
        draftRevision = max(draftRevision, revision)
    }
}
