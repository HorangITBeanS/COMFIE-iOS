//
//  EmojiCharacter.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//
import Foundation

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
        if isWhitespaceOrNewline(char) || isEmoji(char) {
            return false
        }

        let scalars = char.unicodeScalars
        if isLetterCharacter(scalars) {
            return true
        }

        return isNumberPunctuationOrSymbolCharacter(scalars)
    }

    private static func isWhitespaceOrNewline(_ char: Character) -> Bool {
        char == " " || char == "\n"
    }

    private static func isLetterCharacter(_ scalars: String.UnicodeScalarView) -> Bool {
        guard !scalars.isEmpty else { return false }

        var hasLetterCore = false
        for scalar in scalars {
            switch scalar.properties.generalCategory {
            case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter:
                hasLetterCore = true
            case .nonspacingMark, .spacingMark, .enclosingMark, .format:
                continue
            default:
                return false
            }
        }
        return hasLetterCore
    }

    private static func isNumberPunctuationOrSymbolCharacter(_ scalars: String.UnicodeScalarView) -> Bool {
        guard !scalars.isEmpty else { return false }

        var hasCoreCategory = false
        for scalar in scalars {
            switch scalar.properties.generalCategory {
            case .decimalNumber, .letterNumber, .otherNumber,
                .connectorPunctuation, .dashPunctuation, .openPunctuation, .closePunctuation,
                .initialPunctuation, .finalPunctuation, .otherPunctuation,
                .mathSymbol, .currencySymbol, .modifierSymbol, .otherSymbol:
                hasCoreCategory = true
            case .nonspacingMark, .spacingMark, .enclosingMark, .format:
                continue
            default:
                return false
            }
        }
        return hasCoreCategory
    }

    private static func isEmoji(_ char: Character) -> Bool {
        char.unicodeScalars
            .contains(where: { $0.properties.isEmojiPresentation })
        && char.unicodeScalars
            .contains(where: { $0.properties.isEmoji })
    }
}
