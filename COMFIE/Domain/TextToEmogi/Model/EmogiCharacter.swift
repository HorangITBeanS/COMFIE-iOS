//
//  EmogiCharacter.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//

/// 각 문자를 하나의 이모지와 매칭하는 구조입니다.
/// 예: 'a' → 🐯, '한' → 🐯
struct EmogiCharacter {
    var originalCharacter: Character
    var emogiCharacter: Character?
    
    mutating func setEmogiCharacter() {
        guard emogiCharacter == nil else { return }
        
        if originalCharacter == " "
            || originalCharacter == "\n"
            || isEmoji(originalCharacter) {
            emogiCharacter = originalCharacter
        } else {
            emogiCharacter = EmogiPool.getRandomEmoji()
        }
    }
    
    private func isEmoji(_ char: Character) -> Bool {
        char.unicodeScalars
            .contains(where: { $0.properties.isEmojiPresentation })
        && char.unicodeScalars
            .contains(where: { $0.properties.isEmoji })
    }
}
