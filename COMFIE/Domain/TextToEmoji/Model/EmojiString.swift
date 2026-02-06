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

    /// 저장 직전에 원문/이모지 길이를 정규화해 데이터 불일치를 방지합니다.
    static func normalizedForPersist(originalText: String, preferredEmojiText: String) -> EmojiString {
        if originalText.count == preferredEmojiText.count {
            return EmojiString(originalText: originalText, emojiText: preferredEmojiText)
        }

        // 길이 불일치 시 원문 기준으로 재구성하고, 변환 가능한 문자만 이모지로 유지한다.
        var normalized = EmojiString(originalText: originalText, emojiText: originalText)
        let originalCharacters = Array(originalText)
        let preferredCharacters = Array(preferredEmojiText)
        let commonCount = min(originalCharacters.count, preferredCharacters.count)

        guard commonCount > 0 else { return normalized }

        for index in 0..<commonCount {
            let originalCharacter = originalCharacters[index]
            let preferredCharacter = preferredCharacters[index]

            guard preferredCharacter != originalCharacter else { continue }
            guard EmojiCharacter.isEmojiConvertibleCharacter(originalCharacter) else { continue }

            normalized.setEmojiCharacter(preferredCharacter, at: index)
        }

        return normalized
    }

    /// 원문 모드에서 텍스트가 바뀌어도 기존 이모지 매핑을 최대한 유지합니다.
    static func mergedEmojiTextPreservingUnchanged(
        previousOriginalText: String,
        previousEmojiText: String,
        newOriginalText: String
    ) -> String {
        let oldOriginal = Array(previousOriginalText)
        let oldEmoji = Array(previousEmojiText)
        let newOriginal = Array(newOriginalText)

        guard !newOriginal.isEmpty else { return "" }

        // 원문 모드 초기 동기화에서는 이전 원문이 비어 있어도 전달된 이모지 스냅샷을 우선 유지한다.
        if oldOriginal.isEmpty {
            if oldEmoji.count == newOriginal.count {
                return previousEmojiText
            } else {
                return newOriginalText
            }
        }

        let normalizedOldEmoji: [Character] = oldOriginal.enumerated().map { index, originalCharacter in
            if index < oldEmoji.count {
                return oldEmoji[index]
            } else {
                return originalCharacter
            }
        }

        if previousOriginalText == newOriginalText {
            return String(normalizedOldEmoji)
        }

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

        // 공통 부분 수열(LCS)로 기존 매핑을 최대한 유지한다.
        var mergedEmoji = newOriginal
        let matchedIndexPairs = lcsMatchedIndexPairs(old: oldOriginal, new: newOriginal)
        for (oldIndex, newIndex) in matchedIndexPairs {
            guard oldIndex < normalizedOldEmoji.count, newIndex < mergedEmoji.count else { continue }
            mergedEmoji[newIndex] = normalizedOldEmoji[oldIndex]
        }

        return String(mergedEmoji)
    }
    
    /// 현재 이모지 적용 상태의 문자열을 반환합니다.
    func getEmojiString() -> String {
        emojiCharacters
            .map { String($0.emojiCharacter ?? $0.originalCharacter) }
            .joined()
    }
    
    /// 원본 문자열을 반환합니다.
    func getOriginalString() -> String {
        emojiCharacters
            .map { String($0.originalCharacter) }
            .joined()
    }
    
    /// 비워진 이모지를 전체 적용합니다.
    mutating func setUnassignedEmojis() {
        // 전체 채우기
        for i in emojiCharacters.indices {
            emojiCharacters[i].setEmojiCharacter()
        }
    }
    
    private mutating func setEmojiCharacter(_ emoji: Character, at index: Int) {
        guard emojiCharacters.indices.contains(index) else { return }
        emojiCharacters[index].emojiCharacter = emoji
    }

    /// LCS 기반으로 공통 문자 인덱스 쌍을 구합니다.
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
