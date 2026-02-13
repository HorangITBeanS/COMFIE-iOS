@testable import COMFIE
import CoreLocation
import Testing

private final class MappingMemoRepositorySpy: MemoRepositoryProtocol {
    var savedMemos: [Memo] = []
    var updatedMemos: [Memo] = []
    var memos: [Memo] = []

    func save(memo: Memo) -> Result<Void, Error> {
        savedMemos.append(memo)
        memos.append(memo)
        return .success(())
    }

    func fetchAllMemos() -> Result<[Memo], Error> {
        .success(memos)
    }

    func update(memo: Memo) -> Result<Void, Error> {
        updatedMemos.append(memo)
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index] = memo
        }
        return .success(())
    }

    func delete(memo: Memo) -> Result<Void, Error> {
        memos.removeAll { $0.id == memo.id }
        return .success(())
    }

    func deleteAll() {
        memos.removeAll()
    }
}

private struct MappingComfieZoneRepository: ComfieZoneRepositoryProtocol {
    func fetchComfieZone() -> ComfieZone? { nil }
    func saveComfieZone(_ comfieZone: ComfieZone) {}
    func deleteComfieZone() {}
}

private final class AlwaysInComfieZoneLocationUseCaseForMapping: LocationUseCase {
    override func isInComfieZone(_ location: CLLocation?) -> Bool { true }
}

@MainActor
struct MemoStoreComfieZoneMappingTests {
    @Test func plainModeSnapshotSyncRemovesEmojiAtDeletedPosition() {
        let repository = MappingMemoRepositorySpy()
        let store = makeMemoStoreForComfieZoneMapping(repository: repository)

        syncInputSnapshotForComfieZoneMapping(store, originalText: "abc", emojiText: "😀😃😄")
        syncInputSnapshotForComfieZoneMapping(store, originalText: "ac", emojiText: "ac")

        #expect(store.state.inputOriginalText == "ac")
        #expect(store.state.inputMemoText == "😀😄")
    }

    @Test func plainModeSnapshotSyncReplacesEditedPositionMapping() {
        let repository = MappingMemoRepositorySpy()
        let store = makeMemoStoreForComfieZoneMapping(repository: repository)

        syncInputSnapshotForComfieZoneMapping(store, originalText: "abc", emojiText: "😀😃😄")
        syncInputSnapshotForComfieZoneMapping(store, originalText: "axc", emojiText: "axc")

        #expect(store.state.inputOriginalText == "axc")
        #expect(store.state.inputMemoText == "😀x😄")
    }

    @Test func plainModeDeletingCharacterRemovesEmojiAtSamePositionOnUpdate() async throws {
        let repository = MappingMemoRepositorySpy()
        let existingMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "abc",
            emojiText: "😀😃😄"
        )
        repository.memos = [existingMemo]

        let store = makeMemoStoreForComfieZoneMapping(repository: repository)
        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(existingMemo)))

        syncInputSnapshotForComfieZoneMapping(store, originalText: "ac", emojiText: "ac")
        let requestID = try #require(beginSaveRequestIDForComfieZoneMapping(store))
        completeFinalSyncForComfieZoneMapping(
            store,
            requestID: requestID,
            originalText: "ac",
            emojiText: "ac"
        )

        try await waitUntilForComfieZoneMapping(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        #expect(updatedMemo.originalText == "ac")
        #expect(updatedMemo.emojiText == "😀😄")
    }

    @Test func plainModeReplacingCharacterRemapsEmojiAtEditedPositionOnUpdate() async throws {
        let repository = MappingMemoRepositorySpy()
        let existingMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "abc",
            emojiText: "😀😃😄"
        )
        repository.memos = [existingMemo]

        let store = makeMemoStoreForComfieZoneMapping(repository: repository)
        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(existingMemo)))

        syncInputSnapshotForComfieZoneMapping(store, originalText: "axc", emojiText: "axc")
        let requestID = try #require(beginSaveRequestIDForComfieZoneMapping(store))
        completeFinalSyncForComfieZoneMapping(
            store,
            requestID: requestID,
            originalText: "axc",
            emojiText: "axc"
        )

        try await waitUntilForComfieZoneMapping(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        let emojiCharacters = Array(updatedMemo.emojiText)

        #expect(updatedMemo.originalText == "axc")
        #expect(emojiCharacters.count == 3)
        #expect(emojiCharacters[0] == "😀")
        #expect(emojiCharacters[2] == "😄")
        #expect(emojiCharacters[1] != "x")
    }
}

private func makeMemoStoreForComfieZoneMapping(repository: MemoRepositoryProtocol) -> MemoStore {
    let locationUseCase = AlwaysInComfieZoneLocationUseCaseForMapping(
        locationService: LocationService(),
        comfiZoneRepository: MappingComfieZoneRepository()
    )

    return MemoStore(
        router: Router(),
        memoRepository: repository,
        locationUseCase: locationUseCase
    )
}

private func syncInputSnapshotForComfieZoneMapping(
    _ store: MemoStore,
    originalText: String,
    emojiText: String,
    revision: Int? = nil
) {
    let nextRevision = revision ?? max(1, store.state.inputSnapshotRevision + 1)
    store.handleIntent(
        .memoInput(
            .syncInputSnapshotWithRevision(
                .init(
                    originalText: originalText,
                    emojiText: emojiText,
                    revision: nextRevision
                )
            )
        )
    )
}

private func beginSaveRequestIDForComfieZoneMapping(_ store: MemoStore) -> UUID? {
    store.handleIntent(.memoInput(.memoInputButtonTapped))
    guard case .awaitingFinalSync(let requestID) = store.state.savePhase else {
        return nil
    }
    return requestID
}

private func completeFinalSyncForComfieZoneMapping(
    _ store: MemoStore,
    requestID: UUID,
    originalText: String? = nil,
    emojiText: String? = nil,
    revision: Int? = nil
) {
    let resolvedOriginalText = originalText ?? store.state.inputOriginalText
    let resolvedEmojiText = emojiText ?? store.state.inputMemoText
    let resolvedRevision = revision ?? max(1, store.state.inputSnapshotRevision)

    store.handleIntent(
        .memoInput(
            .finalSyncCompletedWithRevision(
                requestID: requestID,
                snapshot: .init(
                    originalText: resolvedOriginalText,
                    emojiText: resolvedEmojiText,
                    revision: resolvedRevision
                )
            )
        )
    )
}

private func waitUntilForComfieZoneMapping(
    timeoutTick: Int,
    condition: @escaping () -> Bool
) async throws {
    for _ in 0..<timeoutTick {
        if condition() { return }
        await Task.yield()
        try await Task.sleep(nanoseconds: 10_000_000)
    }
    Issue.record("Timed out waiting for async state update")
}
