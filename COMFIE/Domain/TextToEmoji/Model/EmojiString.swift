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
    
    init(memo: Memo) {
        self.init(originalText: memo.originalText, emojiText: memo.emojiText)
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

        var mergedEmoji = newOriginal
        let matchedIndexPairs = lcsMatchedIndexPairs(old: oldOriginal, new: newOriginal)
        for (oldIndex, newIndex) in matchedIndexPairs {
            guard oldIndex < normalizedOldEmoji.count, newIndex < mergedEmoji.count else { continue }
            mergedEmoji[newIndex] = normalizedOldEmoji[oldIndex]
        }

        return String(mergedEmoji)
    }
    
    /// index 위치까지 이모지를 적용한 문자열을 설정합니다.
    mutating func applyEmojiString(at index: Int, _ newString: String) {
        syncWithNewString(newString)
        changeEmoji(upTo: index)
    }
    
    /// 변경된 문자열과 emojiCharacters를 동기화합니다.
    /// - Note: newString에 문자가 **추가된 경우**에만 실행됩니다.
    mutating func syncWithNewString(_ newString: String) {
        let originalCharacters = Array(newString)
        var originalIndex = 0
        
        guard newString.count > emojiCharacters.count else { return}
        
        var newCharacters: [EmojiCharacter] = []

        for i in 0..<emojiCharacters.count {
            let emojiCharacter = emojiCharacters[i]
            let currentChar = emojiCharacter.emojiCharacter ?? emojiCharacter.originalCharacter
            let updatedChar = originalCharacters[originalIndex]
            
            if updatedChar != currentChar {
                while originalCharacters[originalIndex] != currentChar {
                    newCharacters.append(
                        EmojiCharacter(originalCharacter: originalCharacters[originalIndex])
                    )
                    originalIndex += 1
                }
            }
            
            newCharacters.append(emojiCharacter)
            originalIndex += 1
        }
        
        // 나머지 추가된 문자 반영
        if originalIndex < originalCharacters.count {
            originalCharacters[originalIndex...].forEach {
                    newCharacters.append(EmojiCharacter(originalCharacter: $0))
                }
        }

        emojiCharacters = newCharacters
    }
    
    /// index 위치까지 모든 character에 이모지를 적용합니다.
    mutating private func changeEmoji(upTo index: Int) {
        guard emojiCharacters.count > index && index > 0 else { return }
        (0...index).forEach { emojiCharacters[$0].setEmojiCharacter() }
    }
    
    /// 현재 이모지 적용 상태의 문자열을 반환합니다.
    func getEmojiString() -> String {
        emojiCharacters
            .map { String($0.emojiCharacter ?? $0.originalCharacter) }
            .joined()
    }
    
    /// index 위치까지의 이모지 적용 문자열을 반환합니다.
    func getEmojiString(to index: Int) -> String {
        var string = ""
        guard index >= 0 && index < emojiCharacters.count else {
            print("getEmojiString(to:) index out of range.: \(index)")
            return string
        }
        
        for i in 0...index {
            let chracter = emojiCharacters[i]
            
            string += String(chracter.emojiCharacter ?? chracter.originalCharacter)
        }
        return string
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
    
    /// 지정된 범위의 이모지 문자열을 삭제합니다.
    mutating func deleteEmojiString(from start: Int, to end: Int? = nil) {
        let toIndex = end ?? start
        
        // 삭제 범위가 유효한지 확인합니다.
        guard start >= 0, toIndex < emojiCharacters.count, start <= toIndex else {
            print("deleteEmojiString(start:end:) 인덱스 문제: \(start), \(String(describing: end))")
            return
        }

        emojiCharacters.removeSubrange(start...toIndex)
    }

    private mutating func setEmojiCharacter(_ emoji: Character, at index: Int) {
        guard emojiCharacters.indices.contains(index) else { return }
        emojiCharacters[index].emojiCharacter = emoji
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
