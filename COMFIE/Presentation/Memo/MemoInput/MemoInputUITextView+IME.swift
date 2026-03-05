//
//  MemoInputUITextView+IME.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

extension MemoInputUITextView.Coordinator {
    // MARK: - IME Handling

    // marked 구간이 생겼을 때 조합 시작점 이전 글자만 안전하게 토큰화합니다.
    func handleMarkedRange(in textView: UITextView, marked: NSRange) {
        guard isEmojiMode else { return }
        tokenizeBeforeMarkedStart(textView, targetIndex: marked.location - 1, marked: marked)
    }

    // IME 조합이 확정(unmark)될 때 지연된 변경을 마무리합니다.
    func handleUnmark(in textView: UITextView) {
        guard isEmojiMode else { return }
        guard textView.markedTextRange == nil else { return }
        guard let change = pendingOrDeferredChange() else { return }

        handleNonMarkedChange(in: textView, change: change)
        clearPendingAndDeferredChanges()
        syncSnapshotToStore(textView)
        lastTextLength = textView.textStorage.length
        lastSelectionRange = textView.selectedRange
    }

    private func tokenizeBeforeMarkedStart(_ textView: UITextView, targetIndex: Int, marked: NSRange?) {
        guard targetIndex >= 0 else { return }

        let storage = textView.textStorage
        guard targetIndex < storage.length else { return }

        let composedRange = (storage.string as NSString).rangeOfComposedCharacterSequence(at: targetIndex)

        if let marked,
           NSIntersectionRange(composedRange, marked).length > 0 {
            return
        }

        if storage.attribute(.attachment, at: targetIndex, effectiveRange: nil) is NSTextAttachment {
            return
        }

        let original = storage.attributedSubstring(from: composedRange).string
        guard let character = original.first, original.count == 1 else { return }
        guard EmojiCharacter.isEmojiConvertibleCharacter(character) else { return }

        let font = textView.font ?? parent.comfieUIBodyFont
        let emoji = String(EmojiPool.getRandomEmoji())
        let token = tokenAttributedString(original: original, emoji: emoji, font: font)

        isMutating = true
        storage.beginEditing()
        storage.replaceCharacters(in: composedRange, with: token)
        storage.endEditing()
        isMutating = false
        lastTextLength = storage.length
    }

    // 조합이 끝난 실제 입력 범위를 찾아 attachment 토큰 변환을 적용합니다.
    func handleNonMarkedChange(in textView: UITextView, change: PendingChange) {
        guard change.replacementUTF16Length > 0 else { return }

        let storageLength = textView.textStorage.length
        guard storageLength > 0 else { return }

        let start = min(max(0, change.range.location), storageLength)
        let convertedLength = min(change.replacementUTF16Length, storageLength - start)
        guard convertedLength > 0 else { return }

        let insertedRange = NSRange(location: start, length: convertedLength)
        tokenizeBeforeMarkedStart(textView, targetIndex: insertedRange.location - 1, marked: nil)
        if change.replacementCharacterCount > 1 {
            tokenizeRange(textView, range: insertedRange)
        }
    }

    func deferPendingChangeIfNeeded() {
        guard let change = pendingChange else { return }
        if change.replacementCharacterCount > 1 {
            setDeferredChange(change)
        }
    }

    func flushPendingConversionOnCursorMove(in textView: UITextView) {
        applyPendingConversionIfNeeded(in: textView)
        syncSnapshotToStore(textView)
        lastTextLength = textView.textStorage.length
    }

    func flushPendingConversionBeforeSync(in textView: UITextView) {
        guard isEmojiMode else { return }
        guard textView.markedTextRange == nil else { return }
        applyPendingConversionIfNeeded(in: textView)
        lastTextLength = textView.textStorage.length
    }

    func handleFallbackInsertion(in textView: UITextView) {
        let currentLength = textView.textStorage.length
        guard currentLength > lastTextLength else { return }

        let insertedLength = currentLength - lastTextLength
        let start = max(0, textView.selectedRange.location - insertedLength)
        let safeLength = min(insertedLength, currentLength - start)
        guard safeLength > 0 else { return }

        let guessedRange = NSRange(location: start, length: safeLength)
        tokenizeBeforeMarkedStart(textView, targetIndex: guessedRange.location - 1, marked: nil)

        if guessedRange.length > 1 {
            tokenizeRange(textView, range: guessedRange)
        }
    }

    private func tokenizeRange(_ textView: UITextView, range: NSRange) {
        let storageLength = textView.textStorage.length
        guard storageLength > 0 else { return }

        let start = max(0, range.location)
        let end = min(range.location + range.length, storageLength)
        guard start < end else { return }

        for index in stride(from: end - 1, through: start, by: -1) {
            tokenizeBeforeMarkedStart(textView, targetIndex: index, marked: nil)
        }
    }

    private func applyPendingConversionIfNeeded(in textView: UITextView) {
        if let change = pendingOrDeferredChange() {
            handleNonMarkedChange(in: textView, change: change)
        } else if lastSelectionRange.location > 0 {
            tokenizeBeforeMarkedStart(textView, targetIndex: lastSelectionRange.location - 1, marked: nil)
        }

        clearPendingAndDeferredChanges()
    }

    // MARK: - Mode Conversion

    // 일반 텍스트 모드를 이모지 표시 모드로 일괄 변환합니다.
    func convertAllPlainToEmoji(in textView: UITextView) {
        let storage = textView.textStorage
        guard storage.length > 0 else { return }

        let font = textView.font ?? parent.comfieUIBodyFont
        let oldSelection = textView.selectedRange

        isMutating = true
        storage.beginEditing()
        for index in stride(from: storage.length - 1, through: 0, by: -1) {
            if storage.attribute(.attachment, at: index, effectiveRange: nil) is NSTextAttachment {
                continue
            }

            let range = NSRange(location: index, length: 1)
            let original = storage.attributedSubstring(from: range).string
            guard let character = original.first, original.count == 1 else { continue }
            guard EmojiCharacter.isEmojiConvertibleCharacter(character) else { continue }

            let emoji = String(EmojiPool.getRandomEmoji())
            storage.replaceCharacters(
                in: range,
                with: tokenAttributedString(original: original, emoji: emoji, font: font)
            )
        }
        storage.endEditing()
        textView.selectedRange = clampedSelection(oldSelection, maxLength: storage.length)
        isMutating = false
        lastTextLength = storage.length
    }

    // attachment 토큰을 원문 문자열로 되돌려 일반 텍스트 모드를 복원합니다.
    func convertAllToPlain(in textView: UITextView) {
        let currentSnapshot = snapshot(from: textView.textStorage)
        let oldSelection = textView.selectedRange

        isMutating = true
        textView.text = currentSnapshot.original
        textView.selectedRange = clampedSelection(oldSelection, maxLength: textView.textStorage.length)
        isMutating = false
        lastTextLength = textView.textStorage.length
    }
}
