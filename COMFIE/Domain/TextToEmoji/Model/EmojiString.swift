//
//  EmojiString.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//

struct EmojiString {
    private var emojiCharacters: [EmojiCharacter]
    
    init() {
        self.emojiCharacters = []
    }

    init(originalText: String, emojiText: String) {
        let originalCharacters = Array(originalText)
        let emojiCharacters = Array(emojiText)

        if originalCharacters.count != emojiCharacters.count {
#if DEBUG
            print("EmojiString init length mismatch - original: \(originalCharacters.count), emoji: \(emojiCharacters.count)")
#endif
        }

        self.emojiCharacters = originalCharacters.enumerated().map { index, originalCharacter in
            let emojiCharacter: Character?
            if index < emojiCharacters.count {
                let candidate = emojiCharacters[index]
                emojiCharacter = candidate == originalCharacter ? nil : candidate
            } else {
                emojiCharacter = nil
            }

            return EmojiCharacter(originalCharacter: originalCharacter, emojiCharacter: emojiCharacter)
        }
    }

    mutating func syncWithSnapshot(originalText: String, emojiText: String) {
        self = EmojiString(originalText: originalText, emojiText: emojiText)
    }

    static func normalizedForPersist(originalText: String, preferredEmojiText: String) -> EmojiString {
        if originalText.count == preferredEmojiText.count {
            return EmojiString(originalText: originalText, emojiText: preferredEmojiText)
        }

        var normalized = EmojiString(originalText: originalText, emojiText: originalText)
        applyPreferredEmojiToConvertibleCommonRange(
            originalText: originalText,
            preferredEmojiText: preferredEmojiText,
            target: &normalized
        )

        return normalized
    }

    static func mergedEmojiTextPreservingUnchanged(
        previousOriginalText: String,
        previousEmojiText: String,
        newOriginalText: String
    ) -> String {
        let oldOriginal = Array(previousOriginalText)
        let oldEmoji = Array(previousEmojiText)
        let newOriginal = Array(newOriginalText)

        guard !newOriginal.isEmpty else { return "" }

        if let resolvedOnInitialSeed = resolveMergedEmojiForInitialSeed(
            oldOriginal: oldOriginal,
            oldEmoji: oldEmoji,
            newOriginal: newOriginal,
            previousEmojiText: previousEmojiText,
            newOriginalText: newOriginalText
        ) {
            return resolvedOnInitialSeed
        }

        let normalizedOldEmoji = normalizedOldEmojiCharacters(oldOriginal: oldOriginal, oldEmoji: oldEmoji)

        if previousOriginalText == newOriginalText {
            return String(normalizedOldEmoji)
        }

        if let mergedFastPath = mergedEmojiByTailFastPath(
            oldOriginal: oldOriginal,
            normalizedOldEmoji: normalizedOldEmoji,
            newOriginal: newOriginal
        ) {
            return mergedFastPath
        }

        return mergedEmojiByLCS(
            oldOriginal: oldOriginal,
            normalizedOldEmoji: normalizedOldEmoji,
            newOriginal: newOriginal
        )
    }
    
    func getEmojiString() -> String {
        emojiCharacters
            .map { String($0.emojiCharacter ?? $0.originalCharacter) }
            .joined()
    }
    
    func getOriginalString() -> String {
        emojiCharacters
            .map { String($0.originalCharacter) }
            .joined()
    }
    
    mutating func setUnassignedEmojis() {
        for i in emojiCharacters.indices {
            emojiCharacters[i].setEmojiCharacter()
        }
    }
    
    private mutating func setEmojiCharacter(_ emoji: Character, at index: Int) {
        guard emojiCharacters.indices.contains(index) else { return }
        emojiCharacters[index].emojiCharacter = emoji
    }

    private static func applyPreferredEmojiToConvertibleCommonRange(
        originalText: String,
        preferredEmojiText: String,
        target: inout EmojiString
    ) {
        let originalCharacters = Array(originalText)
        let preferredCharacters = Array(preferredEmojiText)
        let commonCount = min(originalCharacters.count, preferredCharacters.count)
        guard commonCount > 0 else { return }

        for index in 0..<commonCount {
            let originalCharacter = originalCharacters[index]
            let preferredCharacter = preferredCharacters[index]

            guard preferredCharacter != originalCharacter else { continue }
            guard EmojiCharacter.isEmojiConvertibleCharacter(originalCharacter) else { continue }

            target.setEmojiCharacter(preferredCharacter, at: index)
        }
    }

    private static func resolveMergedEmojiForInitialSeed(
        oldOriginal: [Character],
        oldEmoji: [Character],
        newOriginal: [Character],
        previousEmojiText: String,
        newOriginalText: String
    ) -> String? {
        guard oldOriginal.isEmpty else { return nil }

        if oldEmoji.count == newOriginal.count {
            return previousEmojiText
        }

        return newOriginalText
    }

    private static func normalizedOldEmojiCharacters(
        oldOriginal: [Character],
        oldEmoji: [Character]
    ) -> [Character] {
        oldOriginal.enumerated().map { index, originalCharacter in
            if index < oldEmoji.count {
                return oldEmoji[index]
            } else {
                return originalCharacter
            }
        }
    }

    private static func mergedEmojiByTailFastPath(
        oldOriginal: [Character],
        normalizedOldEmoji: [Character],
        newOriginal: [Character]
    ) -> String? {
        // Fast path: append at tail
        if newOriginal.count == oldOriginal.count + 1,
           oldOriginal.elementsEqual(newOriginal.dropLast()) {
            var merged = normalizedOldEmoji
            if let appended = newOriginal.last {
                merged.append(appended)
            }
            return String(merged)
        }

        // Fast path: delete from tail
        if oldOriginal.count == newOriginal.count + 1,
           newOriginal.elementsEqual(oldOriginal.dropLast()) {
            return String(normalizedOldEmoji.dropLast())
        }

        return nil
    }

    private static func mergedEmojiByLCS(
        oldOriginal: [Character],
        normalizedOldEmoji: [Character],
        newOriginal: [Character]
    ) -> String {
        var mergedEmoji = newOriginal
        let matchedIndexPairs = lcsMatchedIndexPairs(old: oldOriginal, new: newOriginal)

        for (oldIndex, newIndex) in matchedIndexPairs {
            guard oldIndex < normalizedOldEmoji.count, newIndex < mergedEmoji.count else { continue }
            mergedEmoji[newIndex] = normalizedOldEmoji[oldIndex]
        }

        return String(mergedEmoji)
    }

    private static func lcsMatchedIndexPairs(old: [Character], new: [Character]) -> [(Int, Int)] {
        guard !old.isEmpty, !new.isEmpty else { return [] }

        let oldCount = old.count
        let newCount = new.count
        var dp = Array(repeating: Array(repeating: 0, count: newCount + 1), count: oldCount + 1)

        for i in stride(from: oldCount - 1, through: 0, by: -1) {
            for j in stride(from: newCount - 1, through: 0, by: -1) {
                if old[i] == new[j] {
                    dp[i][j] = dp[i + 1][j + 1] + 1
                } else {
                    dp[i][j] = max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }

        var pairs: [(Int, Int)] = []
        var i = 0
        var j = 0

        while i < oldCount && j < newCount {
            if old[i] == new[j], dp[i][j] == dp[i + 1][j + 1] + 1 {
                pairs.append((i, j))
                i += 1
                j += 1
            } else if dp[i + 1][j] >= dp[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }

        return pairs
    }
}
