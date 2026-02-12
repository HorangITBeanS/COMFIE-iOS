import Combine
@testable import COMFIE
import CoreLocation
import SwiftUI
import Testing
import UIKit

private enum MemoRepositorySpyError: Error {
    case forcedFailure
}

private final class MemoRepositorySpy: MemoRepositoryProtocol {
    var savedMemos: [Memo] = []
    var updatedMemos: [Memo] = []
    var memos: [Memo] = []
    var saveCallCount = 0
    var updateCallCount = 0
    var saveResult: Result<Void, Error> = .success(())
    var updateResult: Result<Void, Error> = .success(())

    func save(memo: Memo) -> Result<Void, Error> {
        saveCallCount += 1

        switch saveResult {
        case .success:
            savedMemos.append(memo)
            memos.append(memo)
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    func fetchAllMemos() -> Result<[Memo], Error> {
        .success(memos)
    }

    func update(memo: Memo) -> Result<Void, Error> {
        updateCallCount += 1

        switch updateResult {
        case .success:
            updatedMemos.append(memo)
            if let index = memos.firstIndex(where: { $0.id == memo.id }) {
                memos[index] = memo
            }
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    func delete(memo: Memo) -> Result<Void, Error> {
        memos.removeAll { $0.id == memo.id }
        return .success(())
    }

    func deleteAll() {
        memos.removeAll()
    }
}

private struct TestComfieZoneRepository: ComfieZoneRepositoryProtocol {
    func fetchComfieZone() -> ComfieZone? { nil }
    func saveComfieZone(_ comfieZone: ComfieZone) {}
    func deleteComfieZone() {}
}

private final class AlwaysInComfieZoneLocationUseCase: LocationUseCase {
    override func isInComfieZone(_ location: CLLocation?) -> Bool { true }
}

private final class ToggleComfieZoneLocationUseCase: LocationUseCase {
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private var isInZone: Bool

    override var currentLocationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    init(initialInComfieZone: Bool) {
        self.isInZone = initialInComfieZone
        super.init(
            locationService: LocationService(),
            comfiZoneRepository: TestComfieZoneRepository()
        )
    }

    override func isInComfieZone(_ location: CLLocation?) -> Bool {
        isInZone
    }

    func setInComfieZone(_ isInComfieZone: Bool) {
        isInZone = isInComfieZone
        locationSubject.send(CLLocation(latitude: 37.0, longitude: 127.0))
    }
}

@MainActor
private struct MemoInputCoordinatorHarness {
    let coordinator: MemoInputUITextView.Coordinator
    let textView: UITextView
    let placeholderLabel: UILabel
    let store: MemoStore
    let repository: MemoRepositorySpy
}

private func syncInputSnapshot(
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

private func publishDraftAvailability(
    _ store: MemoStore,
    isEmpty: Bool,
    revision: Int
) {
    store.handleIntent(
        .memoInput(
            .draftAvailabilityChangedWithRevision(
                isEmpty: isEmpty,
                revision: revision
            )
        )
    )
}

@MainActor
struct MemoStoreInputSnapshotTests {

    @Test func syncInputSnapshotUpdatesStateAndDomainSnapshot() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "ab", emojiText: "😀b")

        #expect(store.state.inputOriginalText == "ab")
        #expect(store.state.inputMemoText == "😀b")
        #expect(store.state.isInputEmpty == false)
        #expect(store.state.emojiString.getOriginalString() == "ab")
        #expect(store.state.emojiString.getEmojiString() == "😀b")
    }

    @Test func syncInputSnapshotWithRevisionUpdatesRevisionState() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        store.handleIntent(
            .memoInput(
                .syncInputSnapshotWithRevision(
                    .init(originalText: "ab", emojiText: "😀b", revision: 3)
                )
            )
        )

        #expect(store.state.inputOriginalText == "ab")
        #expect(store.state.inputMemoText == "😀b")
        #expect(store.state.inputSnapshotRevision == 3)
    }

    @Test func lowerRevisionSnapshotDoesNotRollbackRevisionState() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        store.handleIntent(
            .memoInput(
                .syncInputSnapshotWithRevision(
                    .init(originalText: "abc", emojiText: "😀😃😄", revision: 5)
                )
            )
        )
        store.handleIntent(
            .memoInput(
                .syncInputSnapshotWithRevision(
                    .init(originalText: "ab", emojiText: "😀😃", revision: 2)
                )
            )
        )

        #expect(store.state.inputOriginalText == "ab")
        #expect(store.state.inputMemoText == "😀😃")
        #expect(store.state.inputSnapshotRevision == 5)
    }

    @Test func draftAvailabilityEventUpdatesInputEmptyWithoutMutatingSnapshot() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "ab", emojiText: "😀b", revision: 3)

        publishDraftAvailability(store, isEmpty: true, revision: 4)

        #expect(store.state.isInputEmpty)
        #expect(store.state.inputSnapshotRevision == 4)
        #expect(store.state.inputOriginalText == "ab")
        #expect(store.state.inputMemoText == "😀b")

        publishDraftAvailability(store, isEmpty: false, revision: 5)

        #expect(store.state.isInputEmpty == false)
        #expect(store.state.inputSnapshotRevision == 5)
        #expect(store.state.inputOriginalText == "ab")
        #expect(store.state.inputMemoText == "😀b")
    }

    @Test func saveTappedRequestsFinalSyncAndDefersPersist() throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)
        var cancellables = Set<AnyCancellable>()
        var receivedRequestID: UUID?

        store.uiSideEffectPublisher
            .sink { sideEffect in
                if case .requestFinalSyncAndResign(let requestID) = sideEffect {
                    receivedRequestID = requestID
                }
            }
            .store(in: &cancellables)

        syncInputSnapshot(store, originalText: "a1", emojiText: "a1")
        store.handleIntent(.memoInput(.memoInputButtonTapped))

        let requestID = try #require(receivedRequestID)
        #expect(repository.saveCallCount == 0)
        #expect(repository.savedMemos.isEmpty)
        assertAwaitingFinalSync(store, requestID: requestID)
        _ = cancellables
    }

    @Test func saveTappedWithEmptyInputDoesNotStartFinalSync() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)
        var cancellables = Set<AnyCancellable>()
        var requestCount = 0

        store.uiSideEffectPublisher
            .sink { sideEffect in
                if case .requestFinalSyncAndResign = sideEffect {
                    requestCount += 1
                }
            }
            .store(in: &cancellables)

        store.handleIntent(.memoInput(.memoInputButtonTapped))

        #expect(requestCount == 0)
        #expect(repository.saveCallCount == 0)
        #expect(repository.updateCallCount == 0)
        #expect(store.state.savePhase == .idle)
        _ = cancellables
    }

    @Test func finalSyncCompletedWithMismatchedRequestIDDoesNotPersist() throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "a1", emojiText: "a1")
        let requestID = try #require(beginSaveRequestID(store))

        completeFinalSync(
            store,
            requestID: UUID(),
            originalText: "a1",
            emojiText: "a1"
        )

        #expect(repository.saveCallCount == 0)
        #expect(repository.savedMemos.isEmpty)
        assertAwaitingFinalSync(store, requestID: requestID)
    }

    @Test func saveFinalizesConvertibleCharactersFromSnapshot() async throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "a1", emojiText: "a1")
        let requestID = try #require(beginSaveRequestID(store))
        completeFinalSync(
            store,
            requestID: requestID,
            originalText: "a1",
            emojiText: "a1"
        )

        try await waitUntil(timeoutTick: 40) {
            repository.savedMemos.count == 1
        }

        let savedMemo = try #require(repository.savedMemos.first)
        let savedEmojiCharacters = Array(savedMemo.emojiText)

        #expect(savedMemo.originalText == "a1")
        #expect(savedEmojiCharacters.count == 2)
        #expect(savedEmojiCharacters[0] != "a")
        #expect(savedEmojiCharacters[1] != "1")
        #expect(store.state.inputMemoText.isEmpty)
        #expect(store.state.inputOriginalText.isEmpty)
        #expect(store.state.savePhase == .idle)
    }

    @Test func saveFailureReturnsToIdleAndKeepsInputSnapshot() throws {
        let repository = MemoRepositorySpy()
        repository.saveResult = .failure(MemoRepositorySpyError.forcedFailure)
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "a1", emojiText: "a1")
        let requestID = try #require(beginSaveRequestID(store))
        completeFinalSync(
            store,
            requestID: requestID,
            originalText: "a1",
            emojiText: "a1"
        )

        #expect(repository.saveCallCount == 1)
        #expect(repository.savedMemos.isEmpty)
        #expect(store.state.inputOriginalText == "a1")
        #expect(store.state.inputMemoText == "a1")
        #expect(store.state.savePhase == .idle)
    }

    @Test func saveTappedTwiceBeforeFinalSyncEmitsSingleRequest() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)
        var cancellables = Set<AnyCancellable>()
        var requestIDs: [UUID] = []

        store.uiSideEffectPublisher
            .sink { sideEffect in
                guard case .requestFinalSyncAndResign(let requestID) = sideEffect else { return }
                requestIDs.append(requestID)
            }
            .store(in: &cancellables)

        syncInputSnapshot(store, originalText: "ab", emojiText: "ab")
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        store.handleIntent(.memoInput(.memoInputButtonTapped))

        #expect(requestIDs.count == 1)
        #expect(repository.saveCallCount == 0)
        #expect(repository.updateCallCount == 0)
        #expect(store.state.savePhase != .idle)
        _ = cancellables
    }

    @Test func editingCancelResetsInputAndRequestsResignSideEffect() throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)
        let memo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "ab",
            emojiText: "😀😃"
        )

        var cancellables = Set<AnyCancellable>()
        var resignSideEffectCount = 0
        store.uiSideEffectPublisher
            .sink { sideEffect in
                if case .resignInputFocusWithoutSync = sideEffect {
                    resignSideEffectCount += 1
                }
            }
            .store(in: &cancellables)

        store.handleIntent(.memoCell(.editButtonTapped(memo)))
        #expect(store.state.editingMemo != nil)
        store.handleIntent(.memoCell(.editingCancelButtonTapped))

        #expect(store.state.editingMemo == nil)
        #expect(store.state.inputOriginalText.isEmpty)
        #expect(store.state.inputMemoText.isEmpty)
        #expect(store.state.savePhase == .idle)
        #expect(resignSideEffectCount == 1)
        _ = cancellables
    }

    @Test func coordinatorHarnessWiresTextViewDelegate() {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView

        #expect(textView.delegate === coordinator)
    }

    @Test func programmaticResignAfterSaveDoesNotRestoreClearedSnapshot() async throws {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        let store = harness.store
        let repository = harness.repository

        coordinator.bindFocusControl()
        textView.text = "a1"
        coordinator.syncSnapshotToStore(textView)

        store.handleIntent(.memoInput(.memoInputButtonTapped))

        try await waitUntil(timeoutTick: 40) {
            repository.savedMemos.count == 1
        }
        #expect(store.state.inputOriginalText.isEmpty)
        #expect(store.state.inputMemoText.isEmpty)

        textView.delegate?.textViewDidEndEditing?(textView)

        #expect(store.state.inputOriginalText.isEmpty)
        #expect(store.state.inputMemoText.isEmpty)
    }

    @Test func saveRequestRecoversToIdleWhenFinalSyncCallbackIsDropped() async throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "ab", emojiText: "ab")
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        #expect(store.state.savePhase != .idle)

        try await waitUntil(timeoutTick: 80) {
            store.state.savePhase == .idle
        }
        #expect(store.state.savePhase == .idle)
        #expect(repository.saveCallCount == 0)

        let requestID = try #require(beginSaveRequestID(store))
        completeFinalSync(
            store,
            requestID: requestID,
            originalText: "ab",
            emojiText: "ab"
        )

        try await waitUntil(timeoutTick: 40) {
            repository.savedMemos.count == 1
        }
        #expect(store.state.savePhase == .idle)
    }

    @Test func lateFinalSyncCompletionAfterTimeoutStillPersistsWithoutRetry() async throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "ab", emojiText: "ab")
        let timedOutRequestID = try #require(beginSaveRequestID(store))

        try await waitUntil(timeoutTick: 80) {
            store.state.savePhase == .idle
        }
        #expect(repository.saveCallCount == 0)

        completeFinalSync(
            store,
            requestID: timedOutRequestID,
            originalText: "ab",
            emojiText: "ab"
        )

        try await waitUntil(timeoutTick: 40) {
            repository.savedMemos.count == 1
        }
        let savedMemo = try #require(repository.savedMemos.first)
        #expect(savedMemo.originalText == "ab")
        #expect(store.state.savePhase == .idle)
    }

    @Test func lateFinalSyncCompletionAfterTimeoutIsIgnoredAfterInputChanges() async throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "ab", emojiText: "ab")
        let timedOutRequestID = try #require(beginSaveRequestID(store))

        try await waitUntil(timeoutTick: 80) {
            store.state.savePhase == .idle
        }
        #expect(repository.saveCallCount == 0)

        // timeout 이후 입력이 바뀌면 이전 요청의 늦은 callback은 무시되어야 한다.
        syncInputSnapshot(store, originalText: "abc", emojiText: "abc")
        completeFinalSync(
            store,
            requestID: timedOutRequestID,
            originalText: "ab",
            emojiText: "ab"
        )

        #expect(repository.saveCallCount == 0)
        #expect(repository.savedMemos.isEmpty)
        #expect(store.state.inputOriginalText == "abc")
        #expect(store.state.savePhase == .idle)
    }

    @Test func lateFinalSyncCompletionAfterTimeoutIsIgnoredAfterAvailabilityRevisionChange() async throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        syncInputSnapshot(store, originalText: "ab", emojiText: "ab", revision: 1)
        let timedOutRequestID = try #require(beginSaveRequestID(store))

        try await waitUntil(timeoutTick: 80) {
            store.state.savePhase == .idle
        }
        #expect(repository.saveCallCount == 0)

        publishDraftAvailability(store, isEmpty: false, revision: 2)
        completeFinalSync(
            store,
            requestID: timedOutRequestID,
            originalText: "ab",
            emojiText: "ab",
            revision: 1
        )

        #expect(repository.saveCallCount == 0)
        #expect(repository.savedMemos.isEmpty)
        #expect(store.state.inputSnapshotRevision == 2)
        #expect(store.state.savePhase == .idle)
    }

    @Test func requestFinalSyncWithNilTextViewUsesStateSnapshotFallback() async throws {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let store = harness.store
        let repository = harness.repository

        coordinator.bindFocusControl()
        coordinator.textView = nil

        syncInputSnapshot(store, originalText: "ab", emojiText: "ab")
        store.handleIntent(.memoInput(.memoInputButtonTapped))

        try await waitUntil(timeoutTick: 40) {
            repository.savedMemos.count == 1
        }
        let savedMemo = try #require(repository.savedMemos.first)
        #expect(savedMemo.originalText == "ab")
        #expect(savedMemo.emojiText.count == 2)
        #expect(store.state.savePhase == .idle)
    }

    @Test func backgroundTappedRequestsResignWithoutPersist() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)
        var cancellables = Set<AnyCancellable>()
        var resignSideEffectCount = 0

        store.uiSideEffectPublisher
            .sink { sideEffect in
                if case .resignInputFocusWithSyncInput = sideEffect {
                    resignSideEffectCount += 1
                }
            }
            .store(in: &cancellables)

        syncInputSnapshot(store, originalText: "ab", emojiText: "ab")
        store.handleIntent(.backgroundTapped)

        #expect(resignSideEffectCount == 1)
        #expect(repository.saveCallCount == 0)
        #expect(repository.updateCallCount == 0)
        #expect(store.state.savePhase == .idle)
        _ = cancellables
    }

    @Test func comfieZoneTogglePreservesInputSnapshot() async throws {
        let repository = MemoRepositorySpy()
        let locationUseCase = ToggleComfieZoneLocationUseCase(initialInComfieZone: false)
        let store = makeMemoStore(repository: repository, locationUseCase: locationUseCase)

        syncInputSnapshot(store, originalText: "ab", emojiText: "😀😃")

        locationUseCase.setInComfieZone(true)
        try await waitUntil(timeoutTick: 40) {
            store.state.isInComfieZone
        }
        #expect(store.state.inputOriginalText == "ab")
        #expect(store.state.inputMemoText == "😀😃")

        locationUseCase.setInComfieZone(false)
        try await waitUntil(timeoutTick: 40) {
            !store.state.isInComfieZone
        }
        #expect(store.state.inputOriginalText == "ab")
        #expect(store.state.inputMemoText == "😀😃")
    }

    @Test func plainModeSnapshotSyncKeepsExistingEmojiForUntouchedCharacters() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository, isInComfieZone: true)

        syncInputSnapshot(store, originalText: "ab!", emojiText: "😀😃😄")
        syncInputSnapshot(store, originalText: "ab!", emojiText: "ab!")

        #expect(store.state.inputOriginalText == "ab!")
        #expect(store.state.inputMemoText == "😀😃😄")
    }

    @Test func plainModeSnapshotSyncPreservesUntouchedEmojiWhenTextChanges() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository, isInComfieZone: true)

        syncInputSnapshot(store, originalText: "abc", emojiText: "😀😃😄")
        syncInputSnapshot(store, originalText: "abxc", emojiText: "abxc")

        #expect(store.state.inputOriginalText == "abxc")
        #expect(store.state.inputMemoText == "😀😃x😄")
    }

    @Test func updateLegacyMismatchMemoNormalizesLengthWithoutCorruptingOriginal() async throws {
        let repository = MemoRepositorySpy()
        let legacyMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "abcd",
            emojiText: "😀😃"
        )
        repository.memos = [legacyMemo]

        let store = makeMemoStore(repository: repository)
        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(legacyMemo)))
        let requestID = try #require(beginSaveRequestID(store))
        completeFinalSync(
            store,
            requestID: requestID,
            originalText: store.state.inputOriginalText,
            emojiText: store.state.inputMemoText
        )

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        #expect(updatedMemo.originalText == "abcd")
        #expect(updatedMemo.emojiText.count == 4)
    }

    @Test func updatedLegacyMemoRemainsNormalizedAfterRefetch() async throws {
        let repository = MemoRepositorySpy()
        let legacyMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "abcd",
            emojiText: "😀😃"
        )
        repository.memos = [legacyMemo]

        let editorStore = makeMemoStore(repository: repository)
        editorStore.handleIntent(.onAppear)
        editorStore.handleIntent(.memoCell(.editButtonTapped(legacyMemo)))
        let requestID = try #require(beginSaveRequestID(editorStore))
        completeFinalSync(
            editorStore,
            requestID: requestID,
            originalText: editorStore.state.inputOriginalText,
            emojiText: editorStore.state.inputMemoText
        )

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let refetchStore = makeMemoStore(repository: repository)
        refetchStore.handleIntent(.onAppear)
        let fetchedMemo = try #require(refetchStore.state.memos.first(where: { $0.id == legacyMemo.id }))

        #expect(fetchedMemo.originalText == "abcd")
        #expect(fetchedMemo.emojiText.count == 4)
        #expect(fetchedMemo.emojiText.hasPrefix("😀😃"))
    }

    @Test func plainModeEditingPreservesExistingEmojiMappingOnUpdate() async throws {
        let repository = MemoRepositorySpy()
        let existingMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "ab",
            emojiText: "😀😃"
        )
        repository.memos = [existingMemo]

        let store = makeMemoStore(repository: repository, isInComfieZone: true)
        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(existingMemo)))

        syncInputSnapshot(store, originalText: "abc", emojiText: "abc")
        let requestID = try #require(beginSaveRequestID(store))
        completeFinalSync(
            store,
            requestID: requestID,
            originalText: "abc",
            emojiText: "abc"
        )

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        let emojiCharacters = Array(updatedMemo.emojiText)

        #expect(updatedMemo.originalText == "abc")
        #expect(emojiCharacters.count == 3)
        #expect(emojiCharacters[0] == "😀")
        #expect(emojiCharacters[1] == "😃")
        #expect(emojiCharacters[2] != "c")
    }

    @Test func plainModeAppendingHangulCharacterPreservesExistingEmojiMappingOnUpdate() async throws {
        let repository = MemoRepositorySpy()
        let existingMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "가나",
            emojiText: "😀😃"
        )
        repository.memos = [existingMemo]

        let store = makeMemoStore(repository: repository, isInComfieZone: true)
        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(existingMemo)))

        syncInputSnapshot(store, originalText: "가나다", emojiText: "가나다")
        let requestID = try #require(beginSaveRequestID(store))
        completeFinalSync(
            store,
            requestID: requestID,
            originalText: "가나다",
            emojiText: "가나다"
        )

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        let emojiCharacters = Array(updatedMemo.emojiText)

        #expect(updatedMemo.originalText == "가나다")
        #expect(emojiCharacters.count == 3)
        #expect(emojiCharacters[0] == "😀")
        #expect(emojiCharacters[1] == "😃")
        #expect(emojiCharacters[2] != "다")
    }

    @Test func imeMarkedRangeConvertsOnlyBeforeComposingRange() {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        textView.attributedText = NSAttributedString(string: "가나")

        coordinator.handleMarkedRange(in: textView, marked: NSRange(location: 1, length: 1))

        let firstAttachment = textView.textStorage.attribute(.attachment, at: 0, effectiveRange: nil)
        let secondAttachment = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)

        #expect(firstAttachment is NSTextAttachment)
        #expect(secondAttachment == nil)
    }

    @Test func imeMultiCharacterInsertTokenizesInsertedRange() {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        textView.text = "ab"

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 2, length: 0),
            replacementText: "xy"
        )
        textView.text = "abxy"
        textView.selectedRange = NSRange(location: 4, length: 0)

        coordinator.textViewDidChange(textView)

        let secondAttachment = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        let thirdAttachment = textView.textStorage.attribute(.attachment, at: 2, effectiveRange: nil)
        let fourthAttachment = textView.textStorage.attribute(.attachment, at: 3, effectiveRange: nil)

        #expect(secondAttachment is NSTextAttachment)
        #expect(thirdAttachment is NSTextAttachment)
        #expect(fourthAttachment is NSTextAttachment)
        #expect(coordinator.draftOriginalText == "abxy")
    }

    @Test func imeCursorMoveFlushesPendingSingleInsertConversion() {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        textView.text = "ab"

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 2, length: 0),
            replacementText: "c"
        )
        textView.text = "abc"
        textView.selectedRange = NSRange(location: 3, length: 0)

        coordinator.textViewDidChangeSelection(textView)

        let secondAttachment = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)

        #expect(secondAttachment is NSTextAttachment)
        #expect(coordinator.draftOriginalText == "abc")
    }

    @Test func finalSyncSideEffectFromStoreIsHandledByCoordinator() async throws {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        let store = harness.store
        let repository = harness.repository

        coordinator.bindFocusControl()
        textView.text = "a1"
        coordinator.syncSnapshotToStore(textView)

        store.handleIntent(.memoInput(.memoInputButtonTapped))

        try await waitUntil(timeoutTick: 40) {
            repository.savedMemos.count == 1
        }

        let savedMemo = try #require(repository.savedMemos.first)
        let savedEmojiCharacters = Array(savedMemo.emojiText)

        #expect(savedMemo.originalText == "a1")
        #expect(savedEmojiCharacters.count == 2)
        #expect(savedEmojiCharacters[0] != "a")
        #expect(savedEmojiCharacters[1] != "1")
        #expect(store.state.savePhase == .idle)
    }

}

private func beginSaveRequestID(_ store: MemoStore) -> UUID? {
    store.handleIntent(.memoInput(.memoInputButtonTapped))
    guard case .awaitingFinalSync(let requestID) = store.state.savePhase else {
        return nil
    }
    return requestID
}

private func completeFinalSync(
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

private func assertAwaitingFinalSync(_ store: MemoStore, requestID: UUID) {
    guard case .awaitingFinalSync(let pendingRequestID) = store.state.savePhase else {
        Issue.record("savePhase가 awaitingFinalSync 상태가 아닙니다.")
        return
    }
    #expect(pendingRequestID == requestID)
}

private func makeMemoStore(
    repository: MemoRepositoryProtocol,
    isInComfieZone: Bool = false,
    locationUseCase: LocationUseCase? = nil
) -> MemoStore {
    let resolvedLocationUseCase: LocationUseCase
    if let locationUseCase {
        resolvedLocationUseCase = locationUseCase
    } else if isInComfieZone {
        resolvedLocationUseCase = AlwaysInComfieZoneLocationUseCase(
            locationService: LocationService(),
            comfiZoneRepository: TestComfieZoneRepository()
        )
    } else {
        resolvedLocationUseCase = LocationUseCase(
            locationService: LocationService(),
            comfiZoneRepository: TestComfieZoneRepository()
        )
    }

    return MemoStore(
        router: Router(),
        memoRepository: repository,
        locationUseCase: resolvedLocationUseCase
    )
}

private func makeMemoInputCoordinator(isInComfieZone: Bool = false) -> MemoInputCoordinatorHarness {
    let repository = MemoRepositorySpy()
    let store = makeMemoStore(repository: repository, isInComfieZone: isInComfieZone)

    var dynamicHeight: CGFloat = 40
    let dynamicHeightBinding = Binding<CGFloat>(
        get: { dynamicHeight },
        set: { dynamicHeight = $0 }
    )
    let intentBinding = Binding<MemoStore>(
        get: { store },
        set: { _ in }
    )

    let parent = MemoInputUITextView(
        "placeholder",
        dynamicHeight: dynamicHeightBinding,
        intent: intentBinding
    )
    let coordinator = MemoInputUITextView.Coordinator(parent: parent, intent: intentBinding)
    let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
    textView.font = parent.comfieUIBodyFont
    textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 8)
    textView.isScrollEnabled = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    let placeholderLabel = UILabel()
    coordinator.textView = textView
    textView.delegate = coordinator
    coordinator.placeholderLabel = placeholderLabel
    let heightConstraint = textView.heightAnchor.constraint(lessThanOrEqualToConstant: 120)
    heightConstraint.isActive = true
    coordinator.textViewHeightConstraint = heightConstraint

    return MemoInputCoordinatorHarness(
        coordinator: coordinator,
        textView: textView,
        placeholderLabel: placeholderLabel,
        store: store,
        repository: repository
    )
}

private func waitUntil(timeoutTick: Int, condition: @escaping () -> Bool) async throws {
    for _ in 0..<timeoutTick {
        if condition() { return }
        await Task.yield()
        try await Task.sleep(nanoseconds: 10_000_000)
    }
    Issue.record("Timed out waiting for async state update")
}
