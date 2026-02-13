@testable import COMFIE
import Foundation
import Testing

private final class RetrospectionRepositorySpy: RetrospectionRepositoryProtocol {
    var savedMemos: [Memo] = []
    var deletedMemos: [Memo] = []

    func save(memo: Memo) -> Result<Void, Error> {
        savedMemos.append(memo)
        return .success(())
    }

    func delete(memo: Memo) -> Result<Void, Error> {
        deletedMemos.append(memo)
        return .success(())
    }
}

@MainActor
struct RetrospectionEmojiMappingTests {

    @Test func savePreservesEmojiOnAppend() throws {
        let repository = RetrospectionRepositorySpy()
        let memo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "",
            emojiText: "",
            originalRetrospectionText: "ab",
            emojiRetrospectionText: "😀😃"
        )
        let store = RetrospectionStore(router: Router(), repository: repository, memo: memo)

        store.handleIntent(.onAppear)
        store.handleIntent(.updateRetrospection("abc"))
        store.handleIntent(.completeButtonTapped)

        let saved = try #require(repository.savedMemos.last)
        let emoji = saved.emojiRetrospectionText ?? ""

        #expect(saved.originalRetrospectionText == "abc")
        #expect(emoji.count == 3)
        #expect(emoji.hasPrefix("😀😃"))
        #expect(Array(emoji)[2] != "c")
    }

    @Test func savePreservesEmojiOnDelete() throws {
        let repository = RetrospectionRepositorySpy()
        let memo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "",
            emojiText: "",
            originalRetrospectionText: "abc",
            emojiRetrospectionText: "😀😃😄"
        )
        let store = RetrospectionStore(router: Router(), repository: repository, memo: memo)

        store.handleIntent(.onAppear)
        store.handleIntent(.updateRetrospection("ac"))
        store.handleIntent(.completeButtonTapped)

        let saved = try #require(repository.savedMemos.last)
        let emoji = saved.emojiRetrospectionText ?? ""

        #expect(saved.originalRetrospectionText == "ac")
        #expect(emoji == "😀😄")
    }

    @Test func saveKeepsEmojiWhenUnchanged() throws {
        let repository = RetrospectionRepositorySpy()
        let memo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "",
            emojiText: "",
            originalRetrospectionText: "ab",
            emojiRetrospectionText: "😀😃"
        )
        let store = RetrospectionStore(router: Router(), repository: repository, memo: memo)

        store.handleIntent(.onAppear)
        store.handleIntent(.updateRetrospection("ab"))
        store.handleIntent(.completeButtonTapped)

        let saved = try #require(repository.savedMemos.last)
        let emoji = saved.emojiRetrospectionText ?? ""

        #expect(saved.originalRetrospectionText == "ab")
        #expect(emoji == "😀😃")
    }

    @Test func saveNormalizesLengthMismatch() throws {
        let repository = RetrospectionRepositorySpy()
        let memo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "",
            emojiText: "",
            originalRetrospectionText: "abcd",
            emojiRetrospectionText: "😀😃"
        )
        let store = RetrospectionStore(router: Router(), repository: repository, memo: memo)

        store.handleIntent(.onAppear)
        store.handleIntent(.updateRetrospection("abcd"))
        store.handleIntent(.completeButtonTapped)

        let saved = try #require(repository.savedMemos.last)
        let emoji = saved.emojiRetrospectionText ?? ""

        #expect(saved.originalRetrospectionText == "abcd")
        #expect(emoji.count == 4)
        #expect(emoji.hasPrefix("😀😃"))
        #expect(Array(emoji)[2] != "c")
        #expect(Array(emoji)[3] != "d")
    }

    @Test func saveUsesLatestBaselineAcrossConsecutiveSaves() throws {
        let repository = RetrospectionRepositorySpy()
        let memo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "",
            emojiText: "",
            originalRetrospectionText: "ab",
            emojiRetrospectionText: "😀😃"
        )
        let store = RetrospectionStore(router: Router(), repository: repository, memo: memo)

        store.handleIntent(.onAppear)
        store.handleIntent(.updateRetrospection("abc"))
        store.handleIntent(.completeButtonTapped)

        let firstSaved = try #require(repository.savedMemos.last)
        let firstEmoji = firstSaved.emojiRetrospectionText ?? ""
        let savedCEmoji = Array(firstEmoji)[2]

        store.handleIntent(.updateRetrospection("abcd"))
        store.handleIntent(.completeButtonTapped)

        let secondSaved = try #require(repository.savedMemos.last)
        let secondEmoji = secondSaved.emojiRetrospectionText ?? ""

        #expect(secondSaved.originalRetrospectionText == "abcd")
        #expect(secondEmoji.count == 4)
        #expect(Array(secondEmoji)[2] == savedCEmoji)
    }
}
