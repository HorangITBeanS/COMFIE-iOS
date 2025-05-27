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
        let originalText = memo.originalText
        let emojiText = memo.emojiText
        
        precondition(originalText.count == emojiText.count, "originalText와 emojiText의 길이가 같아야 합니다.")
        
        self.emojiCharacters = zip(originalText, emojiText)
            .map {
                EmojiCharacter(originalCharacter: $0.0, emojiCharacter: $0.1)
            }
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
}
