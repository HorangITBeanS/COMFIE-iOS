@testable import COMFIE
import Testing

struct EmojiStringTests {

    @Test func snapshotInitPreservesOriginalAndEmojiView() {
        let emojiString = EmojiString(originalText: "ab!", emojiText: "😀b!")

        #expect(emojiString.getOriginalString() == "ab!")
        #expect(emojiString.getEmojiString() == "😀b!")
    }

    @Test func setUnassignedEmojisSkipsSpaceAndDigits() {
        var emojiString = EmojiString(originalText: "a 1!", emojiText: "a 1!")

        emojiString.setUnassignedEmojis()

        let result = Array(emojiString.getEmojiString())
        #expect(result.count == 4)
        #expect(result[0] != "a")
        #expect(result[1] == " ")
        #expect(result[2] == "1")
        #expect(result[3] != "!")
    }

    @Test func snapshotInitHandlesLengthMismatchWithoutCrash() {
        let emojiString = EmojiString(originalText: "abc", emojiText: "😀")

        #expect(emojiString.getOriginalString() == "abc")
        #expect(emojiString.getEmojiString().count == 3)
    }

    @Test func normalizedForPersistKeepsOriginalLengthOnMismatch() {
        var emojiString = EmojiString.normalizedForPersist(originalText: "ab1", preferredEmojiText: "😀")
        emojiString.setUnassignedEmojis()

        let emoji = Array(emojiString.getEmojiString())
        #expect(emojiString.getOriginalString() == "ab1")
        #expect(emoji.count == 3)
        #expect(emoji[2] == "1")
    }

    @Test func mergedEmojiTextPreservingUnchangedSupportsTailAppendFastPath() {
        let merged = EmojiString.mergedEmojiTextPreservingUnchanged(
            previousOriginalText: "ab",
            previousEmojiText: "😀😃",
            newOriginalText: "abc"
        )

        #expect(merged == "😀😃c")
    }

    @Test func mergedEmojiTextPreservingUnchangedSupportsMiddleInsert() {
        let merged = EmojiString.mergedEmojiTextPreservingUnchanged(
            previousOriginalText: "abc",
            previousEmojiText: "😀😃😄",
            newOriginalText: "abxc"
        )

        #expect(merged == "😀😃x😄")
    }
}
