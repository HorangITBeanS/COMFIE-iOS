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

private final class StuckMarkedTextView: UITextView {
    private final class StubTextPosition: UITextPosition {}
    private final class StubTextRange: UITextRange {
        private let startPosition = StubTextPosition()
        private let endPosition = StubTextPosition()
        override var start: UITextPosition { startPosition }
        override var end: UITextPosition { endPosition }
        override var isEmpty: Bool { false }
    }

    var keepsMarkedRange = false
    private let stubRange = StubTextRange()
    private(set) var unmarkCallCount = 0

    override var markedTextRange: UITextRange? {
        keepsMarkedRange ? stubRange : super.markedTextRange
    }

    override func unmarkText() {
        unmarkCallCount += 1
        super.unmarkText()
    }
}

@MainActor
private struct MemoInputCoordinatorHarness {
    let coordinator: MemoInputUITextView.Coordinator
    let textView: UITextView
    let placeholderLabel: UILabel
    let dynamicHeightBinding: Binding<CGFloat>
    let store: MemoStore
    let repository: MemoRepositorySpy
}

@MainActor
struct MemoStoreInputSnapshotTests {

    // 시나리오: saveTappedRequestsFinalSyncAndDefersPersist 동작을 검증합니다.
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

        publishDraftAvailability(store, isEmpty: false)
        store.handleIntent(.memoInput(.memoInputButtonTapped))

        let requestID = try #require(receivedRequestID)
        #expect(repository.saveCallCount == 0)
        #expect(repository.savedMemos.isEmpty)
        assertAwaitingFinalSync(store, requestID: requestID)
        _ = cancellables
    }

    // 시나리오: saveTappedWithEmptyInputDoesNotStartFinalSync 동작을 검증합니다.
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

    // 시나리오: finalSyncCompletedWithMismatchedRequestIDDoesNotPersist 동작을 검증합니다.
    @Test func finalSyncCompletedWithMismatchedRequestIDDoesNotPersist() throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        publishDraftAvailability(store, isEmpty: false)
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

    // 시나리오: finalSyncFailedMatchingRequestIDReturnsIdle 동작을 검증합니다.
    @Test func finalSyncFailedMatchingRequestIDReturnsIdle() throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        publishDraftAvailability(store, isEmpty: false)
        let requestID = try #require(beginSaveRequestID(store))
        store.handleIntent(.memoInput(.finalSyncFailed(requestID: requestID)))

        #expect(store.state.savePhase == .idle)
        #expect(repository.saveCallCount == 0)
    }

    // 시나리오: finalSyncFailedWithMismatchedRequestIDIsIgnored 동작을 검증합니다.
    @Test func finalSyncFailedWithMismatchedRequestIDIsIgnored() throws {
        let store = makeMemoStore(repository: MemoRepositorySpy())

        publishDraftAvailability(store, isEmpty: false)
        let requestID = try #require(beginSaveRequestID(store))
        store.handleIntent(.memoInput(.finalSyncFailed(requestID: UUID())))

        assertAwaitingFinalSync(store, requestID: requestID)
    }

    // 시나리오: emptyFinalSnapshotDoesNotPersist 동작을 검증합니다.
    @Test func emptyFinalSnapshotDoesNotPersist() throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        publishDraftAvailability(store, isEmpty: false)
        let requestID = try #require(beginSaveRequestID(store))
        completeFinalSync(store, requestID: requestID, originalText: "", emojiText: "")

        #expect(repository.saveCallCount == 0)
        #expect(repository.updateCallCount == 0)
        #expect(store.state.isInputEmpty)
        #expect(store.state.savePhase == .idle)
    }

    // 시나리오: saveFinalizesConvertibleCharactersFromSnapshot 동작을 검증합니다.
    @Test func saveFinalizesConvertibleCharactersFromSnapshot() async throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        publishDraftAvailability(store, isEmpty: false)
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
        #expect(store.state.inputSeed.originalText.isEmpty)
        #expect(store.state.inputSeed.emojiText.isEmpty)
        #expect(store.state.savePhase == .idle)
    }

    // 시나리오: updateFailureReturnsToIdleAndKeepsEditingContext 동작을 검증합니다.
    @Test func updateFailureReturnsToIdleAndKeepsEditingContext() throws {
        let repository = MemoRepositorySpy()
        repository.updateResult = .failure(MemoRepositorySpyError.forcedFailure)
        let existingMemo = Memo(id: UUID(), createdAt: .now, originalText: "ab", emojiText: "😀😃")
        repository.memos = [existingMemo]

        let store = makeMemoStore(repository: repository)
        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(existingMemo)))

        let requestID = try #require(beginSaveRequestID(store))
        completeFinalSync(store, requestID: requestID, originalText: "abc", emojiText: "abc")

        #expect(repository.updateCallCount == 1)
        #expect(store.state.savePhase == .idle)
        #expect(store.state.editingMemo?.id == existingMemo.id)
    }

    // 시나리오: saveTappedTwiceBeforeFinalSyncEmitsSingleRequest 동작을 검증합니다.
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

        publishDraftAvailability(store, isEmpty: false)
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        store.handleIntent(.memoInput(.memoInputButtonTapped))

        #expect(requestIDs.count == 1)
        #expect(repository.saveCallCount == 0)
        #expect(repository.updateCallCount == 0)
        #expect(store.state.savePhase != .idle)
        _ = cancellables
    }

    // 시나리오: editingCancelResetsInputSeedAndRequestsResignSideEffect 동작을 검증합니다.
    @Test func editingCancelResetsInputSeedAndRequestsResignSideEffect() {
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
        #expect(store.state.inputSeed.originalText.isEmpty)
        #expect(store.state.inputSeed.emojiText.isEmpty)
        #expect(store.state.savePhase == .idle)
        #expect(resignSideEffectCount == 1)
        _ = cancellables
    }

    // 시나리오: startEditingIncrementsInputSeedTokenOncePerEdit 동작을 검증합니다.
    @Test func startEditingIncrementsInputSeedTokenOncePerEdit() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)
        let firstMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "ab",
            emojiText: "😀😃"
        )
        let secondMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "cd",
            emojiText: "😄😁"
        )

        let initialToken = store.state.inputSeed.token

        store.handleIntent(.memoCell(.editButtonTapped(firstMemo)))
        #expect(store.state.inputSeed.token == initialToken + 1)
        #expect(store.state.editingMemo?.id == firstMemo.id)
        #expect(store.state.inputSeed.originalText == firstMemo.originalText)
        #expect(store.state.inputSeed.emojiText == firstMemo.emojiText)

        store.handleIntent(.memoCell(.editButtonTapped(secondMemo)))
        #expect(store.state.inputSeed.token == initialToken + 2)
        #expect(store.state.editingMemo?.id == secondMemo.id)
        #expect(store.state.inputSeed.originalText == secondMemo.originalText)
        #expect(store.state.inputSeed.emojiText == secondMemo.emojiText)
    }

    // 시나리오: setFocusWithSeedRefreshPlacesCursorAtTextEndWhenEditingMemo 동작을 검증합니다.
    @Test func setFocusWithSeedRefreshPlacesCursorAtTextEndWhenEditingMemo() throws {
        let repository = MemoRepositorySpy()
        let harness = makeMemoInputCoordinator(repository: repository)
        let store = harness.store
        let textView = harness.textView
        let memo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "ab",
            emojiText: "😀😃"
        )

        var cancellables = Set<AnyCancellable>()
        var latestCommand: MemoInputUICommand?
        store.uiSideEffectPublisher
            .sink { sideEffect in
                latestCommand = mapMemoInputCommand(sideEffect)
            }
            .store(in: &cancellables)

        textView.selectedRange = NSRange(location: 0, length: 0)
        store.handleIntent(.memoCell(.editButtonTapped(memo)))

        let command = try #require(latestCommand)
        #expect(command == .setFocus)

        applyMemoInputCommand(harness, command: command)

        #expect(textView.selectedRange.location == textView.textStorage.length)
        #expect(textView.selectedRange.length == 0)
        _ = cancellables
    }

    // 시나리오: requestFinalSyncWithNilTextViewUsesSeedFallback 동작을 검증합니다.
    @Test func requestFinalSyncWithNilTextViewUsesSeedFallback() async throws {
        let repository = MemoRepositorySpy()
        let existingMemo = Memo(id: UUID(), createdAt: .now, originalText: "ab", emojiText: "😀😃")
        repository.memos = [existingMemo]

        let harness = makeMemoInputCoordinator(repository: repository)
        let coordinator = harness.coordinator
        let store = harness.store

        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(existingMemo)))
        coordinator.textView = nil

        var cancellables = Set<AnyCancellable>()
        var latestCommand: MemoInputUICommand?
        store.uiSideEffectPublisher
            .sink { sideEffect in
                latestCommand = mapMemoInputCommand(sideEffect)
            }
            .store(in: &cancellables)

        let requestID = try #require(beginSaveRequestID(store))
        let command = try #require(latestCommand)
        if case .requestFinalSyncAndResign(let commandRequestID) = command {
            #expect(commandRequestID == requestID)
        } else {
            Issue.record("final sync command was not captured")
        }
        applyMemoInputCommand(harness, command: command)

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        #expect(updatedMemo.originalText == "ab")
        #expect(updatedMemo.emojiText == "😀😃")
        #expect(store.state.savePhase == .idle)
        _ = requestID
        _ = cancellables
    }

    // 시나리오: requestFinalSyncWithNilTextViewIgnoresStaleCoordinatorDraft 동작을 검증합니다.
    @Test func requestFinalSyncWithNilTextViewIgnoresStaleCoordinatorDraft() async throws {
        let repository = MemoRepositorySpy()
        let existingMemo = Memo(id: UUID(), createdAt: .now, originalText: "ab", emojiText: "😀😃")
        repository.memos = [existingMemo]

        let harness = makeMemoInputCoordinator(repository: repository)
        let coordinator = harness.coordinator
        let store = harness.store

        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(existingMemo)))
        coordinator.debugInjectDraftForTesting(original: "stale", emoji: "🙃🙃🙃🙃🙃")
        coordinator.textView = nil

        var cancellables = Set<AnyCancellable>()
        var latestCommand: MemoInputUICommand?
        store.uiSideEffectPublisher
            .sink { sideEffect in
                latestCommand = mapMemoInputCommand(sideEffect)
            }
            .store(in: &cancellables)
        _ = try #require(beginSaveRequestID(store))
        let command = try #require(latestCommand)
        applyMemoInputCommand(harness, command: command)

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        #expect(updatedMemo.originalText == "ab")
        #expect(updatedMemo.emojiText == "😀😃")
        #expect(store.state.savePhase == .idle)
        _ = cancellables
    }

    // 시나리오: requestFinalSyncFailsWhenMarkedTextCannotBeFinalized 동작을 검증합니다.
    @Test func requestFinalSyncFailsWhenMarkedTextCannotBeFinalized() {
        var dynamicHeight: CGFloat = 40
        let dynamicHeightBinding = Binding<CGFloat>(
            get: { dynamicHeight },
            set: { dynamicHeight = $0 }
        )
        let requestID = UUID()

        var outputEvents: [MemoInputOutputEvent] = []
        let parent = MemoInputUITextView(
            "placeholder",
            dynamicHeight: dynamicHeightBinding,
            inputSeed: MemoInputSeed(token: 1, originalText: "ab", emojiText: "😀😃"),
            isEmojiPresentationEnabled: true,
            uiCommandEvent: MemoInputUIEvent(command: .requestFinalSyncAndResign(requestID: requestID)),
            onOutputEvent: { outputEvents.append($0) }
        )
        let coordinator = MemoInputUITextView.Coordinator(parent: parent)
        let textView = StuckMarkedTextView()
        textView.font = parent.comfieUIBodyFont
        textView.text = "ab"
        textView.keepsMarkedRange = true
        coordinator.textView = textView

        coordinator.applyStateToTextView(force: false)

        let failedRequestIDs = outputEvents.compactMap { event -> UUID? in
            guard case .finalSnapshotFailed(let failedRequestID) = event else { return nil }
            return failedRequestID
        }
        let readyEventsCount = outputEvents.compactMap { event -> MemoInputSnapshot? in
            guard case .finalSnapshotReady(_, let snapshot) = event else { return nil }
            return snapshot
        }.count

        #expect(textView.unmarkCallCount == 1)
        #expect(failedRequestIDs == [requestID])
        #expect(readyEventsCount == 0)
    }

    // 시나리오: backgroundTappedRequestsResignWithoutPersist 동작을 검증합니다.
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

        publishDraftAvailability(store, isEmpty: false)
        store.handleIntent(.backgroundTapped)

        #expect(resignSideEffectCount == 1)
        #expect(repository.saveCallCount == 0)
        #expect(repository.updateCallCount == 0)
        #expect(store.state.savePhase == .idle)
        _ = cancellables
    }

    // 시나리오: comfieZoneTogglePreservesInputSeed 동작을 검증합니다.
    @Test func comfieZoneTogglePreservesInputSeed() async throws {
        let repository = MemoRepositorySpy()
        let locationUseCase = ToggleComfieZoneLocationUseCase(initialInComfieZone: false)
        let store = makeMemoStore(repository: repository, locationUseCase: locationUseCase)
        let memo = Memo(id: UUID(), createdAt: .now, originalText: "ab", emojiText: "😀😃")

        store.handleIntent(.memoCell(.editButtonTapped(memo)))
        let originalSeed = store.state.inputSeed

        locationUseCase.setInComfieZone(true)
        try await waitUntil(timeoutTick: 40) {
            store.state.isInComfieZone
        }
        #expect(store.state.inputSeed == originalSeed)

        locationUseCase.setInComfieZone(false)
        try await waitUntil(timeoutTick: 40) {
            !store.state.isInComfieZone
        }
        #expect(store.state.inputSeed == originalSeed)
    }

    // 시나리오: finalSyncSideEffectFromStoreIsHandledByCoordinator 동작을 검증합니다.
    @Test func finalSyncSideEffectFromStoreIsHandledByCoordinator() async throws {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        let store = harness.store
        let repository = harness.repository

        var cancellables = Set<AnyCancellable>()
        var latestCommand: MemoInputUICommand?
        store.uiSideEffectPublisher
            .sink { sideEffect in
                latestCommand = mapMemoInputCommand(sideEffect)
            }
            .store(in: &cancellables)

        textView.text = "a1"
        coordinator.syncSnapshotToStore(textView)

        store.handleIntent(.memoInput(.memoInputButtonTapped))
        let command = try #require(latestCommand)
        applyMemoInputCommand(harness, command: command)

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
        _ = cancellables
    }

    // 시나리오: finalSnapshotReadyUsesOnOutputEventAndPreservesRequestID 동작을 검증합니다.
    @Test func finalSnapshotReadyUsesOnOutputEventAndPreservesRequestID() {
        var dynamicHeight: CGFloat = 40
        let dynamicHeightBinding = Binding<CGFloat>(
            get: { dynamicHeight },
            set: { dynamicHeight = $0 }
        )
        let requestID = UUID()
        let seed = MemoInputSeed(token: 1, originalText: "ab", emojiText: "😀😃")

        var outputEvents: [MemoInputOutputEvent] = []
        let parent = MemoInputUITextView(
            "placeholder",
            dynamicHeight: dynamicHeightBinding,
            inputSeed: seed,
            isEmojiPresentationEnabled: true,
            uiCommandEvent: MemoInputUIEvent(command: .requestFinalSyncAndResign(requestID: requestID)),
            onOutputEvent: { outputEvents.append($0) }
        )
        let coordinator = MemoInputUITextView.Coordinator(parent: parent)
        coordinator.textView = nil

        coordinator.applyStateToTextView(force: false)

        let readyPayloads = outputEvents.compactMap { event -> (UUID, MemoInputSnapshot)? in
            guard case .finalSnapshotReady(let eventRequestID, let snapshot) = event else { return nil }
            return (eventRequestID, snapshot)
        }
        #expect(readyPayloads.count == 1)
        #expect(readyPayloads.first?.0 == requestID)
        #expect(readyPayloads.first?.1 == MemoInputSnapshot(originalText: "ab", emojiText: "😀😃"))
    }

    // 시나리오: finalSnapshotFailedUsesOnOutputEventAndPreservesRequestID 동작을 검증합니다.
    @Test func finalSnapshotFailedUsesOnOutputEventAndPreservesRequestID() {
        var dynamicHeight: CGFloat = 40
        let dynamicHeightBinding = Binding<CGFloat>(
            get: { dynamicHeight },
            set: { dynamicHeight = $0 }
        )
        let requestID = UUID()

        var outputEvents: [MemoInputOutputEvent] = []
        let parent = MemoInputUITextView(
            "placeholder",
            dynamicHeight: dynamicHeightBinding,
            inputSeed: .empty,
            isEmojiPresentationEnabled: true,
            uiCommandEvent: MemoInputUIEvent(command: .requestFinalSyncAndResign(requestID: requestID)),
            onOutputEvent: { outputEvents.append($0) }
        )
        let coordinator = MemoInputUITextView.Coordinator(parent: parent)
        coordinator.textView = nil

        coordinator.applyStateToTextView(force: false)

        let failedRequestIDs = outputEvents.compactMap { event -> UUID? in
            guard case .finalSnapshotFailed(let failedRequestID) = event else { return nil }
            return failedRequestID
        }
        #expect(failedRequestIDs == [requestID])
    }
}

private func publishDraftAvailability(
    _ store: MemoStore,
    isEmpty: Bool
) {
    store.handleIntent(
        .memoInput(
            .draftAvailabilityChanged(isEmpty: isEmpty)
        )
    )
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
    originalText: String,
    emojiText: String
) {
    store.handleIntent(
        .memoInput(
            .finalSyncCompleted(
                requestID: requestID,
                snapshot: .init(
                    originalText: originalText,
                    emojiText: emojiText
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

@MainActor
private func makeMemoInputCoordinator(
    repository: MemoRepositorySpy = MemoRepositorySpy(),
    isInComfieZone: Bool = false
) -> MemoInputCoordinatorHarness {
    let store = makeMemoStore(repository: repository, isInComfieZone: isInComfieZone)

    var dynamicHeight: CGFloat = 40
    let dynamicHeightBinding = Binding<CGFloat>(
        get: { dynamicHeight },
        set: { dynamicHeight = $0 }
    )

    let parent = makeMemoInputParent(
        store: store,
        dynamicHeightBinding: dynamicHeightBinding,
        uiCommandEvent: nil
    )
    let coordinator = MemoInputUITextView.Coordinator(parent: parent)

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
        dynamicHeightBinding: dynamicHeightBinding,
        store: store,
        repository: repository
    )
}

@MainActor
private func applyMemoInputCommand(
    _ harness: MemoInputCoordinatorHarness,
    command: MemoInputUICommand
) {
    harness.coordinator.parent = makeMemoInputParent(
        store: harness.store,
        dynamicHeightBinding: harness.dynamicHeightBinding,
        uiCommandEvent: MemoInputUIEvent(command: command)
    )
    harness.coordinator.applyStateToTextView(force: false)
}

private func mapMemoInputCommand(_ sideEffect: MemoStore.SideEffect.MemoInput) -> MemoInputUICommand {
    switch sideEffect {
    case .resignInputFocusWithSyncInput:
        return .resignWithSync
    case .resignInputFocusWithoutSync:
        return .resignWithoutSync
    case .requestFinalSyncAndResign(let requestID):
        return .requestFinalSyncAndResign(requestID: requestID)
    case .setMemoInputFocus:
        return .setFocus
    }
}

private func makeMemoInputParent(
    store: MemoStore,
    dynamicHeightBinding: Binding<CGFloat>,
    uiCommandEvent: MemoInputUIEvent?
    ) -> MemoInputUITextView {
    MemoInputUITextView(
        "placeholder",
        dynamicHeight: dynamicHeightBinding,
        inputSeed: store.state.inputSeed,
        isEmojiPresentationEnabled: store.state.isEmojiPresentationEnabled,
        uiCommandEvent: uiCommandEvent,
        onOutputEvent: { outputEvent in
            switch outputEvent {
            case .draftAvailabilityChanged(let isEmpty):
                store.handleIntent(
                    .memoInput(
                        .draftAvailabilityChanged(isEmpty: isEmpty)
                    )
                )
            case .finalSnapshotReady(let requestID, let snapshot):
                store.handleIntent(
                    .memoInput(
                        .finalSyncCompleted(
                            requestID: requestID,
                            snapshot: snapshot
                        )
                    )
                )
            case .finalSnapshotFailed(let requestID):
                store.handleIntent(.memoInput(.finalSyncFailed(requestID: requestID)))
            }
        }
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
