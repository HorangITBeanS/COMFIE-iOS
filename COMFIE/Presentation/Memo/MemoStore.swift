//
//  MemoStore.swift
//  COMFIE
//
//  Created by zaehorang on 3/6/25.
//

import Combine
import SwiftUI

struct MemoInputSeed: Equatable {
    var token: Int
    var originalText: String
    var emojiText: String

    static let empty = MemoInputSeed(token: 0, originalText: "", emojiText: "")
}

struct MemoInputSnapshot: Equatable {
    let originalText: String
    let emojiText: String
    let revision: Int
}

enum MemoInputUICommand: Equatable {
    case resignWithSync
    case resignWithoutSync
    case requestFinalSyncAndResign(requestID: UUID)
    case setFocus
}

struct MemoInputUIEvent: Equatable {
    let id: UUID
    let command: MemoInputUICommand

    init(command: MemoInputUICommand) {
        self.id = UUID()
        self.command = command
    }
}

@Observable
class MemoStore: IntentStore {
    private(set) var state: State

    // MARK: State
    struct State {
        enum SavePhase: Equatable {
            case idle
            case awaitingFinalSync(requestID: UUID)
            case persisting
        }

        var memos: [Memo] = []
        var isInComfieZone: Bool = false

        var groupedMemos: [(date: String, memos: [Memo])] {
            let grouped = Dictionary(grouping: memos) { $0.createdAt.yyyyMMddString }

            return grouped
                .sorted { lhs, rhs in
                    lhs.value.first!.createdAt < rhs.value.first!.createdAt
                }
                .map { (date: $0.key, memos: $0.value) }
        }

        var isEmojiPresentationEnabled: Bool {
            !isInComfieZone
        }

        var inputSeed: MemoInputSeed = .empty

        var isInputEmpty: Bool = true
        var savePhase: SavePhase = .idle

        var editingMemo: Memo?
        var deletingMemo: Memo?

        func isEditingMemo(_ memo: Memo) -> Bool {
            editingMemo?.id == memo.id
        }

        mutating func setEditingMemo(_ memo: Memo) {
            editingMemo = memo
            inputSeed = MemoInputSeed(
                token: inputSeed.token + 1,
                originalText: memo.originalText,
                emojiText: memo.emojiText
            )
            isInputEmpty = memo.emojiText.isEmpty
        }

        private mutating func resetInputSeedToEmptyPreservingEditing() {
            inputSeed = MemoInputSeed(token: inputSeed.token + 1, originalText: "", emojiText: "")
            isInputEmpty = true
        }

        mutating func resetEditingMemo() {
            resetInputSeedToEmptyPreservingEditing()
            editingMemo = nil
        }

        mutating func resetInputSeedAfterSave() {
            resetInputSeedToEmptyPreservingEditing()
        }

        mutating func setDeletingMemo(_ memo: Memo) {
            deletingMemo = memo
        }

        mutating func resetDeletingMemo() {
            deletingMemo = nil
        }

        @AppStorage(UserDefaultsConstants.Keys.hasSeenTutorial.rawValue) var hasSeenTutorial: Bool = false
        var showTutorial: Bool = false
    }

    // MARK: Intent
    enum Intent {
        case deletePopup(PopupIntent)
        case memoInput(MemoInputIntent)
        case memoCell(MemoCellIntent)

        case onAppear
        case backgroundTapped
        case comfieZoneSettingButtonTapped
        case moreButtonTapped
        case tutorialTapped

        enum PopupIntent {
            case confirmDeleteButtonTapped
            case cancelDeleteButtonTapped
        }

        enum MemoInputIntent {
            case draftAvailabilityChangedWithRevision(isEmpty: Bool, revision: Int)
            case memoInputButtonTapped
            case finalSyncCompletedWithRevision(requestID: UUID, snapshot: MemoInputSnapshot)
            case finalSyncFailed(requestID: UUID)
        }

        enum MemoCellIntent {
            case editButtonTapped(Memo)
            case retrospectionButtonTapped(Memo)
            case deleteButtonTapped(Memo)
            case editingCancelButtonTapped
        }
    }

    // MARK: Action
    enum Action {
        case memo(MemoAction)
        case input(InputAction)
        case popup(PopupAction)
        case navigation(NavigationAction)
        case tutorial(TutorialAction)

        enum MemoAction {
            case fetchAll
            case save(snapshot: MemoInputSnapshot)
            case update(memo: Memo, snapshot: MemoInputSnapshot)
            case delete
        }

        enum InputAction {
            case draftAvailabilityChangedWithRevision(isEmpty: Bool, revision: Int)
            case finalSyncCompleted(requestID: UUID, snapshot: MemoInputSnapshot)
            case finalSyncFailed(requestID: UUID)
            case startEditing(Memo)
            case cancelEditing
        }

        enum PopupAction {
            case showDeletePopup(Memo)
            case cancelDelete
        }

        enum NavigationAction {
            case toRetrospection(Memo)
            case toComfieZoneSetting
            case toMore
        }

        enum TutorialAction {
            case showTutorial
            case dismissTutorial
        }
    }

    // MARK: Side Effect
    enum SideEffect {
        case memoInput(MemoInput)
        case scroll(Scroll)

        enum MemoInput {
            case resignInputFocusWithSyncInput
            case resignInputFocusWithoutSync
            case requestFinalSyncAndResign(requestID: UUID)
            case setMemoInputFocus
        }

        enum Scroll {
            case toMemo(memo: Memo)
            case toBottom
        }
    }

    private let router: Router
    private let memoRepository: MemoRepositoryProtocol
    private let locationUseCase: LocationUseCase

    private(set) var uiSideEffectPublisher = PassthroughSubject<SideEffect.MemoInput, Never>()
    private(set) var scrollSideEffectPublisher = PassthroughSubject<SideEffect.Scroll, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init
    init(router: Router, memoRepository: MemoRepositoryProtocol, locationUseCase: LocationUseCase) {
        self.router = router
        self.memoRepository = memoRepository
        self.locationUseCase = locationUseCase

        self.state = .init(isInComfieZone: locationUseCase.isInComfieZone(locationUseCase.getCurrentLocation()))

        observeIsInComfieZone()
    }

    // MARK: Method
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .memoCell(let memoCellIntent):
            state = handleMemoCellIntent(memoCellIntent)
        case .memoInput(let memoInputIntent):
            state = handleMemoInputIntent(memoInputIntent)
        case .deletePopup(let popupIntent):
            state = handleDeletePopupIntent(popupIntent)

        case .onAppear:
            state = handleAction(state, .memo(.fetchAll))
            if !state.hasSeenTutorial {
                state = handleAction(state, .tutorial(.showTutorial))
            }
        case .backgroundTapped:
            guard canHandleIdleOnlyInteraction(state) else { return }
            performUISideEffect(for: .resignInputFocusWithSyncInput)
        case .comfieZoneSettingButtonTapped:
            guard canHandleIdleOnlyInteraction(state) else { return }
            state = handleAction(state, .navigation(.toComfieZoneSetting))
        case .moreButtonTapped:
            guard canHandleIdleOnlyInteraction(state) else { return }
            state = handleAction(state, .navigation(.toMore))
        case .tutorialTapped:
            state = handleAction(state, .tutorial(.dismissTutorial))
        }
    }

    private func handleAction(_ state: State, _ action: Action) -> State {
        switch action {
        case .memo(let action):
            return handleMemoAction(state, action)
        case .input(let action):
            return handleInputAction(state, action)
        case .popup(let action):
            return handlePopupAction(state, action)
        case .navigation(let action):
            return handleNavigationAction(state, action)
        case .tutorial(let action):
            return handleTutorialAction(state, action)
        }
    }
}

// MARK: - Handle Intent Methods
extension MemoStore {
    private func canHandleIdleOnlyInteraction(_ state: State) -> Bool {
        state.savePhase == .idle
    }

    private func handleMemoCellIntent(_ intent: Intent.MemoCellIntent) -> State {
        switch intent {
        case .deleteButtonTapped(let memo):
            guard canHandleIdleOnlyInteraction(state) else { return state }
            return handleAction(state, .popup(.showDeletePopup(memo)))
        case .editButtonTapped(let memo):
            guard canHandleIdleOnlyInteraction(state) else { return state }
            let newState = handleAction(state, .input(.startEditing(memo)))
            performUISideEffect(for: .setMemoInputFocus)

            performScrollEffect(for: .toMemo(memo: memo))
            return newState
        case .editingCancelButtonTapped:
            guard canHandleIdleOnlyInteraction(state) else { return state }
            let newState = handleAction(state, .input(.cancelEditing))
            performUISideEffect(for: .resignInputFocusWithoutSync)
            return newState
        case .retrospectionButtonTapped(let memo):
            guard canHandleIdleOnlyInteraction(state) else { return state }
            let newState = handleNavigationAction(state, .toRetrospection(memo))
            return newState
        }
    }

    private func handleMemoInputIntent(_ intent: Intent.MemoInputIntent) -> State {
        switch intent {
        case .draftAvailabilityChangedWithRevision(let isEmpty, let revision):
            return handleAction(
                state,
                .input(
                    .draftAvailabilityChangedWithRevision(
                        isEmpty: isEmpty,
                        revision: revision
                    )
                )
            )
        case .memoInputButtonTapped:
            guard case .idle = state.savePhase, !state.isInputEmpty else { return state }

            let requestID = UUID()
            var newState = state
            newState.savePhase = .awaitingFinalSync(requestID: requestID)
            performUISideEffect(for: .requestFinalSyncAndResign(requestID: requestID))
            return newState
        case .finalSyncCompletedWithRevision(requestID: let requestID, snapshot: let snapshot):
            return handleAction(
                state,
                .input(
                    .finalSyncCompleted(
                        requestID: requestID,
                        snapshot: snapshot
                    )
                )
            )
        case .finalSyncFailed(let requestID):
            return handleAction(state, .input(.finalSyncFailed(requestID: requestID)))
        }
    }

    private func handleDeletePopupIntent(_ intent: Intent.PopupIntent) -> State {
        switch intent {
        case .cancelDeleteButtonTapped:
            return handleAction(state, .popup(.cancelDelete))
        case .confirmDeleteButtonTapped:
            guard canHandleIdleOnlyInteraction(state) else { return state }
            return handleAction(state, .memo(.delete))
        }
    }
}

// MARK: - Handle Action Methods
extension MemoStore {
    private func handleMemoAction(_ state: State, _ action: Action.MemoAction) -> State {
        switch action {
        case .fetchAll:
            return fetchMemos(state)
        case .save(let snapshot):
            return saveMemo(state, snapshot: snapshot)
        case .update(let memo, let snapshot):
            return updateMemo(state, memo, snapshot: snapshot)
        case .delete:
            if let memo = state.deletingMemo {
                return deleteMemo(state, memo)
            }
        }
        return state
    }

    private func handleInputAction(_ state: State, _ action: Action.InputAction) -> State {
        switch action {
        case .draftAvailabilityChangedWithRevision(let isEmpty, _):
            var newState = state
            newState.isInputEmpty = isEmpty
            return newState
        case .finalSyncCompleted(let requestID, let snapshot):
            return handleFinalSyncCompleted(state, requestID: requestID, snapshot: snapshot)
        case .finalSyncFailed(let requestID):
            return handleFinalSyncFailed(state, requestID: requestID)
        case .startEditing(let memo):
            var newState = state
            newState.setEditingMemo(memo)
            return newState
        case .cancelEditing:
            var newState = state
            newState.resetEditingMemo()
            return newState
        }
    }

    private func handleFinalSyncCompleted(_ state: State, requestID: UUID, snapshot: MemoInputSnapshot) -> State {
        var newState = state
        guard case .awaitingFinalSync(let currentRequestID) = newState.savePhase,
              currentRequestID == requestID else {
            return newState
        }

        guard !snapshot.originalText.isEmpty else {
            newState.savePhase = .idle
            newState.isInputEmpty = true
            return newState
        }

        newState.savePhase = .persisting

        if let editingMemo = newState.editingMemo {
            return handleAction(newState, .memo(.update(memo: editingMemo, snapshot: snapshot)))
        } else {
            let persistedState = handleAction(newState, .memo(.save(snapshot: snapshot)))
            if persistedState.savePhase == .idle {
                performScrollEffect(for: .toBottom)
            }
            return persistedState
        }
    }

    private func handleFinalSyncFailed(_ state: State, requestID: UUID) -> State {
        var newState = state
        guard case .awaitingFinalSync(let currentRequestID) = newState.savePhase,
              currentRequestID == requestID else {
            return newState
        }

        newState.savePhase = .idle
        return newState
    }

    private func handlePopupAction(_ state: State, _ action: Action.PopupAction) -> State {
        var newState = state
        switch action {
        case .showDeletePopup(let memo):
            newState.setDeletingMemo(memo)
        case .cancelDelete:
            newState.resetDeletingMemo()
        }
        return newState
    }

    private func handleNavigationAction(_ state: State, _ action: Action.NavigationAction) -> State {
        switch action {
        case .toRetrospection(let memo):
            router.push(.retrospection(memo: memo))
            return state
        case .toComfieZoneSetting:
            router.push(.comfieZoneSetting)
        case .toMore:
            router.push(.more)
        }
        return state
    }

    private func handleTutorialAction(_ state: State, _ action: Action.TutorialAction) -> State {
        var newState = state
        switch action {
        case .showTutorial:
            newState.showTutorial = true
        case .dismissTutorial:
            newState.showTutorial = false
            newState.hasSeenTutorial = true
        }
        return newState
    }
}

// MARK: - Side Effect Method
extension MemoStore {
    private func performUISideEffect(for action: SideEffect.MemoInput) {
        uiSideEffectPublisher.send(action)
    }

    private func performScrollEffect(for action: SideEffect.Scroll) {
        scrollSideEffectPublisher.send(action)
    }

    private func observeIsInComfieZone() {
        locationUseCase.currentLocationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                let isInComfieZone = self.locationUseCase.isInComfieZone(location)
                self.state.isInComfieZone = isInComfieZone
            }
            .store(in: &cancellables)
    }
}

// MARK: - Helper Methods
extension MemoStore {
    private func normalizedSnapshotForPersist(_ snapshot: MemoInputSnapshot) -> EmojiString {
        var emojiString = EmojiString.normalizedForPersist(
            originalText: snapshot.originalText,
            preferredEmojiText: snapshot.emojiText
        )
        emojiString.setUnassignedEmojis()
        return emojiString
    }

    private func fetchMemos(_ state: State) -> State {
        var newState = state
        switch memoRepository.fetchAllMemos() {
        case .success(let memos):
            newState.memos = memos
        case .failure(let error):
            print("메모 불러오기 실패: \(error)")
        }
        return newState
    }

    private func saveMemo(_ state: State, snapshot: MemoInputSnapshot) -> State {
        var newState = state
        let emojiString = normalizedSnapshotForPersist(snapshot)
        let newMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: emojiString.getOriginalString(),
            emojiText: emojiString.getEmojiString()
        )

        switch memoRepository.save(memo: newMemo) {
        case .success:
            newState.memos.append(newMemo)
            newState.resetInputSeedAfterSave()
        case .failure(let error):
            print("메모 저장 실패: \(error)")
        }
        newState.savePhase = .idle
        return newState
    }

    private func updateMemo(_ state: State, _ memo: Memo, snapshot: MemoInputSnapshot) -> State {
        var newState = state
        let emojiString = normalizedSnapshotForPersist(snapshot)
        var updatedMemo = memo

        updatedMemo.originalText = emojiString.getOriginalString()
        updatedMemo.emojiText = emojiString.getEmojiString()

        switch memoRepository.update(memo: updatedMemo) {
        case .success:
            if let index = newState.memos.firstIndex(where: { $0.id == memo.id }) {
                newState.memos[index] = updatedMemo
            }

            newState.resetEditingMemo()
        case .failure(let error):
            print("메모 업데이트 실패: \(error)")
        }
        newState.savePhase = .idle
        return newState
    }

    private func deleteMemo(_ state: State, _ memo: Memo) -> State {
        var newState = state
        switch memoRepository.delete(memo: memo) {
        case .success:
            if let index = newState.memos.firstIndex(where: { $0.id == memo.id }) {
                newState.memos.remove(at: index)
            }

            newState.resetDeletingMemo()
        case .failure(let error):
            print("메모 삭제 실패: \(error)")
        }
        return newState
    }
}
