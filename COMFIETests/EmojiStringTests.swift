@testable import COMFIE
import Testing

struct EmojiStringTests {

    // 시나리오: snapshotInitPreservesOriginalAndEmojiView 동작을 검증합니다.
    @Test func snapshotInitPreservesOriginalAndEmojiView() {
        let emojiString = EmojiString(originalText: "ab!", emojiText: "😀b!")

        #expect(emojiString.getOriginalString() == "ab!")
        #expect(emojiString.getEmojiString() == "😀b!")
    }

    // 시나리오: setUnassignedEmojisSkipsSpaceAndConvertsDigits 동작을 검증합니다.
    @Test func setUnassignedEmojisSkipsSpaceAndConvertsDigits() {
        var emojiString = EmojiString(originalText: "a 1!", emojiText: "a 1!")

        emojiString.setUnassignedEmojis()

        let result = Array(emojiString.getEmojiString())
        #expect(result.count == 4)
        #expect(result[0] != "a")
        #expect(result[1] == " ")
        #expect(result[2] != "1")
        #expect(result[3] != "!")
    }

    // 시나리오: setUnassignedEmojisConvertsUnicodeLettersAcrossScripts 동작을 검증합니다.
    @Test func setUnassignedEmojisConvertsUnicodeLettersAcrossScripts() {
        let original = "éЖ中あ"
        var emojiString = EmojiString(originalText: original, emojiText: original)

        emojiString.setUnassignedEmojis()

        let result = Array(emojiString.getEmojiString())
        let expected = Array(original)
        #expect(result.count == expected.count)
        for index in expected.indices {
            #expect(result[index] != expected[index])
        }
    }

    // 시나리오: setUnassignedEmojisConvertsUnicodeDigitsAcrossScripts 동작을 검증합니다.
    @Test func setUnassignedEmojisConvertsUnicodeDigitsAcrossScripts() {
        let original = "١２3"
        var emojiString = EmojiString(originalText: original, emojiText: original)

        emojiString.setUnassignedEmojis()

        let result = Array(emojiString.getEmojiString())
        let expected = Array(original)
        #expect(result.count == expected.count)
        for index in expected.indices {
            #expect(result[index] != expected[index])
        }
    }

    // 시나리오: setUnassignedEmojisConvertsUnicodePunctuationAndSymbols 동작을 검증합니다.
    @Test func setUnassignedEmojisConvertsUnicodePunctuationAndSymbols() {
        let original = "。！∞₩"
        var emojiString = EmojiString(originalText: original, emojiText: original)

        emojiString.setUnassignedEmojis()

        let result = Array(emojiString.getEmojiString())
        let expected = Array(original)
        #expect(result.count == expected.count)
        for index in expected.indices {
            #expect(result[index] != expected[index])
        }
    }

    // 시나리오: setUnassignedEmojisConvertsDecomposedAccentAsSingleCharacter 동작을 검증합니다.
    @Test func setUnassignedEmojisConvertsDecomposedAccentAsSingleCharacter() {
        let decomposed = "e\u{0301}"
        var emojiString = EmojiString(originalText: decomposed, emojiText: decomposed)

        emojiString.setUnassignedEmojis()

        let converted = emojiString.getEmojiString()
        #expect(Array(decomposed).count == 1)
        #expect(Array(converted).count == 1)
        #expect(converted != decomposed)
    }

    // 시나리오: setUnassignedEmojisPreservesWhitespaceAndExistingEmoji 동작을 검증합니다.
    @Test func setUnassignedEmojisPreservesWhitespaceAndExistingEmoji() {
        let original = " \n😀"
        var emojiString = EmojiString(originalText: original, emojiText: original)

        emojiString.setUnassignedEmojis()

        #expect(emojiString.getEmojiString() == original)
    }

    // 시나리오: snapshotInitHandlesLengthMismatchWithoutCrash 동작을 검증합니다.
    @Test func snapshotInitHandlesLengthMismatchWithoutCrash() {
        let emojiString = EmojiString(originalText: "abc", emojiText: "😀")

        #expect(emojiString.getOriginalString() == "abc")
        #expect(emojiString.getEmojiString().count == 3)
    }

    // 시나리오: normalizedForPersistKeepsOriginalLengthOnMismatch 동작을 검증합니다.
    @Test func normalizedForPersistKeepsOriginalLengthOnMismatch() {
        var emojiString = EmojiString.normalizedForPersist(originalText: "ab1", preferredEmojiText: "😀")
        emojiString.setUnassignedEmojis()

        let emoji = Array(emojiString.getEmojiString())
        #expect(emojiString.getOriginalString() == "ab1")
        #expect(emoji.count == 3)
        #expect(emoji[2] != "1")
    }

    // 시나리오: mergedEmojiTextPreservingUnchangedSupportsTailAppendFastPath 동작을 검증합니다.
    @Test func mergedEmojiTextPreservingUnchangedSupportsTailAppendFastPath() {
        let merged = EmojiString.mergedEmojiTextPreservingUnchanged(
            previousOriginalText: "ab",
            previousEmojiText: "😀😃",
            newOriginalText: "abc"
        )

        #expect(merged == "😀😃c")
    }

    // 시나리오: mergedEmojiTextPreservingUnchangedSupportsMiddleInsert 동작을 검증합니다.
    @Test func mergedEmojiTextPreservingUnchangedSupportsMiddleInsert() {
        let merged = EmojiString.mergedEmojiTextPreservingUnchanged(
            previousOriginalText: "abc",
            previousEmojiText: "😀😃😄",
            newOriginalText: "abxc"
        )

        #expect(merged == "😀😃x😄")
    }

    // 시나리오: mergedEmojiTextPreservingUnchangedSupportsMiddleDelete 동작을 검증합니다.
    @Test func mergedEmojiTextPreservingUnchangedSupportsMiddleDelete() {
        let merged = EmojiString.mergedEmojiTextPreservingUnchanged(
            previousOriginalText: "abc",
            previousEmojiText: "😀😃😄",
            newOriginalText: "ac"
        )

        #expect(merged == "😀😄")
    }

    // 시나리오: mergedEmojiTextPreservingUnchangedSupportsMiddleReplace 동작을 검증합니다.
    @Test func mergedEmojiTextPreservingUnchangedSupportsMiddleReplace() {
        let merged = EmojiString.mergedEmojiTextPreservingUnchanged(
            previousOriginalText: "abc",
            previousEmojiText: "😀😃😄",
            newOriginalText: "axc"
        )

        #expect(merged == "😀x😄")
    }
}
