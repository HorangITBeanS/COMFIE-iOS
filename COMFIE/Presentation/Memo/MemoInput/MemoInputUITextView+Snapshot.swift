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
        if !parent.inputSeed.originalText.isEmpty {
            return parent.inputSeed.originalText
        }
        return parent.inputSeed.emojiText
    }

    func normalizedEmojiText(with originalText: String) -> String {
        if !parent.inputSeed.emojiText.isEmpty {
            return parent.inputSeed.emojiText
        }
        return originalText
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
        let originalText = normalizedOriginalText()
        let emojiText = normalizedEmojiText(with: originalText)
        let revision = (draftOriginalText == originalText && draftEmojiText == emojiText)
            ? draftRevision
            : draftRevision + 1

        syncDraftCache(
            originalText: originalText,
            emojiText: emojiText,
            revision: revision
        )
        publishDraftAvailability()
    }

    func publishDraftAvailability() {
        parent.onDraftAvailabilityChanged(draftEmojiText.isEmpty, draftRevision)
    }

    func snapshot(from storage: NSAttributedString) -> (original: String, emoji: String) {
        var original = ""
        var emoji = ""
        let fullRange = NSRange(location: 0, length: storage.length)

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
        let resolvedEmojiText = resolveDraftEmojiText(
            originalText: originalText,
            emojiTextCandidate: emojiTextCandidate
        )
        bumpDraftRevisionIfNeeded(originalText: originalText, resolvedEmojiText: resolvedEmojiText)

        draftOriginalText = originalText
        draftEmojiText = resolvedEmojiText
    }

    func syncDraftCache(originalText: String, emojiText: String, revision: Int) {
        draftOriginalText = originalText
        draftEmojiText = emojiText
        draftRevision = max(draftRevision, revision)
    }

    private func resolveDraftEmojiText(originalText: String, emojiTextCandidate: String) -> String {
        if isEmojiMode {
            return emojiTextCandidate
        }

        let seededPreviousEmojiText = seededPreviousEmojiTextForPlainMode(
            originalText: originalText,
            emojiTextCandidate: emojiTextCandidate
        )
        return EmojiString.mergedEmojiTextPreservingUnchanged(
            previousOriginalText: draftOriginalText,
            previousEmojiText: seededPreviousEmojiText,
            newOriginalText: originalText
        )
    }

    private func seededPreviousEmojiTextForPlainMode(originalText: String, emojiTextCandidate: String) -> String {
        if draftOriginalText.isEmpty,
           draftEmojiText.isEmpty,
           emojiTextCandidate.count == originalText.count {
            return emojiTextCandidate
        }

        return draftEmojiText
    }

    private func bumpDraftRevisionIfNeeded(originalText: String, resolvedEmojiText: String) {
        let hasDraftChanged = draftOriginalText != originalText || draftEmojiText != resolvedEmojiText
        if hasDraftChanged {
            draftRevision += 1
        }
    }
}
