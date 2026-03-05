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

    // 현재 textStorage를 draft로 동기화하고 Store에 입력 가능 상태를 알립니다.
    func syncSnapshotToStore(_ textView: UITextView) {
        let currentSnapshot = snapshot(from: textView.textStorage)
        let emojiTextCandidate = isEmojiMode ? currentSnapshot.emoji : currentSnapshot.original

        updateDraft(
            originalText: currentSnapshot.original,
            emojiTextCandidate: emojiTextCandidate
        )
        publishDraftAvailability()
        // +Snapshot+UITest 확장에서 실제 동작하며, 그 외 빌드에서는 no-op이다.
        publishDebugSnapshotIfNeeded(textView)
    }

    // textView가 없는 생명주기 경계에서도 seed 기반 draft를 복구해 savePhase 고착을 막습니다.
    func syncDraftFromFallbackIfNeeded() {
        let originalText = normalizedOriginalText()
        let emojiText = normalizedEmojiText(with: originalText)

        syncDraftCache(
            originalText: originalText,
            emojiText: emojiText
        )
        publishDraftAvailability()
    }

    func publishDraftAvailability() {
        parent.emitOutputEvent(.draftAvailabilityChanged(isEmpty: draftEmojiText.isEmpty))
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

    // 원문/이모지 스냅샷을 현재 모드(UIText/Attachment)에 맞춰 UITextView에 렌더링합니다.
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
        // +Snapshot+UITest 확장에서 실제 동작하며, 그 외 빌드에서는 no-op이다.
        publishDebugSnapshotIfNeeded(textView)
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

        replaceDraft(original: originalText, emoji: resolvedEmojiText)
    }

    func syncDraftCache(originalText: String, emojiText: String) {
        replaceDraft(original: originalText, emoji: emojiText)
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
}
