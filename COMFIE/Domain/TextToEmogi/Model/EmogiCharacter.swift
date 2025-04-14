//
//  EmogiCharacter.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//

struct EmogiCharacter {
    var originalCharacter: Character
    var emogiCharacter: Character?
    
    mutating func setEmogiCharacter() {
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
