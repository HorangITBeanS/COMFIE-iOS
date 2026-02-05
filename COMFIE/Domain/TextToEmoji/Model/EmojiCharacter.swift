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

        if Self.isEmojiConvertibleCharacter(originalCharacter) {
            emojiCharacter = EmojiPool.getRandomEmoji()
        } else {
            emojiCharacter = originalCharacter
        }
    }
    
    static func isEmojiConvertibleCharacter(_ char: Character) -> Bool {
        if char == " " || char == "\n" || isEmoji(char) {
            return false
        }

        guard let scalar = char.unicodeScalars.first,
              char.unicodeScalars.count == 1 else {
            return false
        }

        let value = Int(scalar.value)
        let isHangulSyllable = (0xAC00...0xD7A3).contains(value)
        let isHangulJamo = (0x3131...0x318E).contains(value) || (0x1100...0x11FF).contains(value)
        let isLatinAlphabet = (0x41...0x5A).contains(value) || (0x61...0x7A).contains(value)
        let isASCIIPunctuation =
            (0x21...0x2F).contains(value)
            || (0x3A...0x40).contains(value)
            || (0x5B...0x60).contains(value)
            || (0x7B...0x7E).contains(value)

        return isHangulSyllable || isHangulJamo || isLatinAlphabet || isASCIIPunctuation
    }

    private static func isEmoji(_ char: Character) -> Bool {
        char.unicodeScalars
            .contains(where: { $0.properties.isEmojiPresentation })
        && char.unicodeScalars
            .contains(where: { $0.properties.isEmoji })
    }
}
