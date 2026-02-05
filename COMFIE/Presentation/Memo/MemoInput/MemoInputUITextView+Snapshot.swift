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
        if !intent.state.inputOriginalText.isEmpty {
            return intent.state.inputOriginalText
        }
        return intent.state.inputMemoText
    }

    func normalizedEmojiText(with originalText: String) -> String {
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
        let emojiText = isEmojiMode ? currentSnapshot.emoji : currentSnapshot.original
        intent.handleIntent(
            .memoInput(
                .syncInputSnapshot(
                    originalText: currentSnapshot.original,
                    emojiText: emojiText
                )
            )
        )
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
}
