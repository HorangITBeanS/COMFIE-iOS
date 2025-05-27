//
//  EmojiCharacter.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//

/// 각 문자를 하나의 이모지와 매칭하는 구조입니다.
/// 예: 'a' → 🐯, '한' → 🐯
struct EmojiCharacter {
    var originalCharacter: Character
    var emojiCharacter: Character?
    
    mutating func setEmojiCharacter() {
        guard emojiCharacter == nil else { return }
        
        if originalCharacter == " "
            || originalCharacter == "\n"
            || isEmoji(originalCharacter) {
            emojiCharacter = originalCharacter
        } else {
            emojiCharacter = EmojiPool.getRandomEmoji()
        }
    }
    
    private func isEmoji(_ char: Character) -> Bool {
        char.unicodeScalars
            .contains(where: { $0.properties.isEmojiPresentation })
        && char.unicodeScalars
            .contains(where: { $0.properties.isEmoji })
    }
}
