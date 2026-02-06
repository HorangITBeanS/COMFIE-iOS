//
//  EmojiCharacter.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//
import Foundation

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
    
    /// 이모지로 변환 가능한 입력 문자만 허용한다. (공백/줄바꿈/이미 이모지 제외)
    static func isEmojiConvertibleCharacter(_ char: Character) -> Bool {
        if char == " " || char == "\n" || isEmoji(char) {
            return false
        }

        let scalars = char.unicodeScalars
        if !scalars.isEmpty, scalars.allSatisfy({ CharacterSet.letters.contains($0) }) {
            return true
        }

        guard let scalar = scalars.first,
              scalars.count == 1 else {
            return false
        }

        let value = Int(scalar.value)
        let isASCIIDigit = (0x30...0x39).contains(value)
        let isASCIIPunctuation =
            (0x21...0x2F).contains(value)
            || (0x3A...0x40).contains(value)
            || (0x5B...0x60).contains(value)
            || (0x7B...0x7E).contains(value)

        return isASCIIDigit || isASCIIPunctuation
    }

    private static func isEmoji(_ char: Character) -> Bool {
        char.unicodeScalars
            .contains(where: { $0.properties.isEmojiPresentation })
        && char.unicodeScalars
            .contains(where: { $0.properties.isEmoji })
    }
}
