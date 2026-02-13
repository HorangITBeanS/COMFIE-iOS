//
//  MemoStore.swift
//  COMFIE
//
//  Created by zaehorang on 3/6/25.
//

import Combine
import SwiftUI

@Observable
class MemoStore: IntentStore {
    struct MemoInputSnapshot: Equatable {
        let originalText: String
        let emojiText: String
        let revision: Int
    }

    private static let finalSyncTimeoutNanoseconds: UInt64 = 300_000_000

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
        
        // createdAt 날짜 문자열(dotYMDFormat 기준)로 메모들을 그룹화하고 정렬한 결과
        var groupedMemos: [(date: String, memos: [Memo])] {
            let grouped = Dictionary(grouping: memos) { $0.createdAt.yyyyMMddString }
            
            return grouped
                .sorted {
                    $0.value.first!.createdAt < $1.value.first!.createdAt
                }
                .map { (key, value) in (date: key, memos: value) }
        }
        
        var emojiString: EmojiString = .init()
        
        // 사용자가 텍스트 필드에 입력하는 메모
        var inputMemoText: String = ""
        var inputOriginalText: String = ""
        var inputSnapshotRevision: Int = 0
        var inputSeedVersion: Int = 0
        var isInputEmpty: Bool = true
        var savePhase: SavePhase = .idle
        var editingMemo: Memo?
        var deletingMemo: Memo?
        
        func isEditingMemo(_ memo: Memo) -> Bool {
            editingMemo?.id == memo.id
        }
        
        mutating func setEditingMemo(_ memo: Memo) {
            editingMemo = memo
            inputMemoText = memo.emojiText
            inputOriginalText = memo.originalText
            inputSnapshotRevision += 1
            inputSeedVersion += 1
            isInputEmpty = memo.emojiText.isEmpty
            emojiString = EmojiString(originalText: memo.originalText, emojiText: memo.emojiText)
        }
        
        mutating func resetEditingMemo() {
            emojiString = .init()
            inputMemoText = ""
            inputOriginalText = ""
            inputSnapshotRevision += 1
            inputSeedVersion += 1
            isInputEmpty = true
            editingMemo = nil
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
            case syncInputSnapshotWithRevision(MemoInputSnapshot)
            case memoInputButtonTapped
            case finalSyncCompletedWithRevision(requestID: UUID, snapshot: MemoInputSnapshot)
            case finalSyncTimedOut(requestID: UUID)
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
            case save
            case update(Memo)
            case delete
        }
        
        enum InputAction {
            case draftAvailabilityChangedWithRevision(isEmpty: Bool, revision: Int)
            case syncInputSnapshot(snapshot: MemoInputSnapshot)
            case finalSyncCompleted(requestID: UUID, snapshot: MemoInputSnapshot)
            case finalSyncTimedOut(requestID: UUID)
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
    private var finalSyncTimeoutTask: Task<Void, Never>?
    private struct TimedOutFinalSyncContext {
        let requestID: UUID
        let draftRevision: Int
    }

    private var timedOutFinalSyncContext: TimedOutFinalSyncContext?
    private var pendingFinalSyncDraftRevision: Int?
    
    // MARK: Init
    init(router: Router, memoRepository: MemoRepositoryProtocol, locationUseCase: LocationUseCase) {
        self.router = router
        self.memoRepository = memoRepository
        self.locationUseCase = locationUseCase
        
        self.state = .init(isInComfieZone: locationUseCase.isInComfieZone(locationUseCase.getCurrentLocation()))
        
        observeIsInComfieZone()
    }

    deinit {
        cancelFinalSyncTimeout()
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
            performUISideEffect(for: .resignInputFocusWithSyncInput)
        case .comfieZoneSettingButtonTapped:
            state = handleAction(state, .navigation(.toComfieZoneSetting))
        case .moreButtonTapped:
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
    private func handleMemoCellIntent(_ intent: Intent.MemoCellIntent) -> State {
        switch intent {
        case .deleteButtonTapped(let memo):
            return handleAction(state, .popup(.showDeletePopup(memo)))
        case .editButtonTapped(let memo):
            guard state.savePhase == .idle else { return state }
            let newState = handleAction(state, .input(.startEditing(memo)))
            performUISideEffect(for: .setMemoInputFocus)

            // 메모 수정 시, 해당 메모 위치로 스크롤 이동
            performScrollEffect(for: .toMemo(memo: memo))
            return newState
        case .editingCancelButtonTapped:
            guard state.savePhase == .idle else { return state }
            let newState = handleAction(state, .input(.cancelEditing))
            performUISideEffect(for: .resignInputFocusWithoutSync)
            return newState
        case .retrospectionButtonTapped(let memo):
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
            guard case .idle = state.savePhase else { return state }

            let requestID = UUID()
            pendingFinalSyncDraftRevision = state.inputSnapshotRevision
            timedOutFinalSyncContext = nil
            var newState = state
            newState.savePhase = .awaitingFinalSync(requestID: requestID)
            performUISideEffect(for: .requestFinalSyncAndResign(requestID: requestID))
            startFinalSyncTimeout(for: requestID)
            return newState
        case .syncInputSnapshotWithRevision(let snapshot):
            return handleAction(state, .input(.syncInputSnapshot(snapshot: snapshot)))
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
        case .finalSyncTimedOut(let requestID):
            return handleAction(state, .input(.finalSyncTimedOut(requestID: requestID)))
        }
    }
    
    private func handleDeletePopupIntent(_ intent: Intent.PopupIntent) -> State {
        switch intent {
        case .cancelDeleteButtonTapped:
            return handleAction(state, .popup(.cancelDelete))
        case .confirmDeleteButtonTapped:
            return handleAction(state, .memo(.delete))
        }
    }
}

// MARK: - Handle Action Methods
extension MemoStore {
    private func handleMemoAction(_ state: State, _ action: Action.MemoAction) -> State {
        var newState = state
        
        switch action {
        case .fetchAll:
            return fetchMemos(newState)
        case .save:
            syncEmojiStringForPersist(&newState)
            return saveMemo(newState)
        case .update(let updatedMemo):
            syncEmojiStringForPersist(&newState)
            return updateMemo(newState, updatedMemo)
        case .delete:
            if let memo = newState.deletingMemo {
                return deleteMemo(newState, memo)
            }
        }
        return newState
    }
    
    private func handleInputAction(_ state: State, _ action: Action.InputAction) -> State {
        var newState = state
        switch action {
        case .draftAvailabilityChangedWithRevision(let isEmpty, let revision):
            newState.isInputEmpty = isEmpty
            newState.inputSnapshotRevision = max(newState.inputSnapshotRevision, revision)
            if case .awaitingFinalSync = newState.savePhase {
                pendingFinalSyncDraftRevision = revision
            }

            if case .idle = newState.savePhase,
               let timedOutContext = timedOutFinalSyncContext,
               revision != timedOutContext.draftRevision {
                timedOutFinalSyncContext = nil
            }
            return newState
        case .syncInputSnapshot(let snapshot):
            if case .awaitingFinalSync = newState.savePhase {
                pendingFinalSyncDraftRevision = snapshot.revision
            }
            if case .idle = newState.savePhase,
               let timedOutContext = timedOutFinalSyncContext,
               snapshot.revision != timedOutContext.draftRevision {
                timedOutFinalSyncContext = nil
            }
            return applyInputSnapshot(newState, snapshot: snapshot)
        case .finalSyncCompleted(let requestID, let snapshot):
            let isAwaitingMatchedRequest: Bool
            if case .awaitingFinalSync(let currentRequestID) = newState.savePhase {
                isAwaitingMatchedRequest = (currentRequestID == requestID)
            } else {
                isAwaitingMatchedRequest = false
            }

            let isLateCompletionForTimedOutRequest: Bool
            if case .idle = newState.savePhase,
               let timedOutContext = timedOutFinalSyncContext {
                isLateCompletionForTimedOutRequest =
                    timedOutContext.requestID == requestID
                    && timedOutContext.draftRevision == newState.inputSnapshotRevision
                    && timedOutContext.draftRevision == snapshot.revision
            } else {
                isLateCompletionForTimedOutRequest = false
            }

            guard isAwaitingMatchedRequest || isLateCompletionForTimedOutRequest else {
                return newState
            }

            cancelFinalSyncTimeout()
            pendingFinalSyncDraftRevision = nil
            timedOutFinalSyncContext = nil
            newState = applyInputSnapshot(newState, snapshot: snapshot)
            newState.savePhase = .persisting

            if let editingMemo = newState.editingMemo {
                return handleAction(newState, .memo(.update(editingMemo)))
            } else {
                let persistedState = handleAction(newState, .memo(.save))
                performScrollEffect(for: .toBottom)
                return persistedState
            }
        case .finalSyncTimedOut(let requestID):
            guard case .awaitingFinalSync(let currentRequestID) = newState.savePhase else {
                return newState
            }
            guard currentRequestID == requestID else {
                return newState
            }

            newState.savePhase = .idle
            let timedOutDraftRevision = pendingFinalSyncDraftRevision ?? newState.inputSnapshotRevision
            timedOutFinalSyncContext = TimedOutFinalSyncContext(
                requestID: requestID,
                draftRevision: timedOutDraftRevision
            )
            pendingFinalSyncDraftRevision = nil
            cancelFinalSyncTimeout()
            return newState
        case .startEditing(let memo):
            // 작성되고 있던 메모 reset
            newState.resetEditingMemo()
            newState.setEditingMemo(memo)
        case .cancelEditing:
            newState.resetEditingMemo()
        }
        
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
    private func startFinalSyncTimeout(for requestID: UUID) {
        cancelFinalSyncTimeout()

        finalSyncTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.finalSyncTimeoutNanoseconds)
            guard !Task.isCancelled, let self else { return }
            await MainActor.run {
                self.handleIntent(.memoInput(.finalSyncTimedOut(requestID: requestID)))
            }
        }
    }

    private func cancelFinalSyncTimeout() {
        finalSyncTimeoutTask?.cancel()
        finalSyncTimeoutTask = nil
    }

    private func applyInputSnapshot(_ state: State, snapshot: MemoInputSnapshot) -> State {
        var newState = state
        let originalText = snapshot.originalText
        let emojiText = snapshot.emojiText

        let syncedEmojiText: String
        if newState.isInComfieZone {
            // 원문 모드에서는 기존 이모지 매핑을 최대한 유지한다.
            let seededPreviousEmojiText: String
            if newState.inputOriginalText.isEmpty,
               newState.inputMemoText.isEmpty,
               emojiText.count == originalText.count {
                // 최초 동기화 시 전달된 이모지 스냅샷을 신뢰한다.
                seededPreviousEmojiText = emojiText
            } else {
                seededPreviousEmojiText = newState.inputMemoText
            }

            syncedEmojiText = EmojiString.mergedEmojiTextPreservingUnchanged(
                previousOriginalText: newState.inputOriginalText,
                previousEmojiText: seededPreviousEmojiText,
                newOriginalText: originalText
            )
        } else {
            syncedEmojiText = emojiText
        }

        newState.inputOriginalText = originalText
        newState.inputMemoText = syncedEmojiText
        newState.inputSnapshotRevision = max(newState.inputSnapshotRevision, snapshot.revision)
        newState.isInputEmpty = syncedEmojiText.isEmpty
        newState.emojiString.syncWithSnapshot(originalText: originalText, emojiText: syncedEmojiText)
        return newState
    }

    private func syncEmojiStringForPersist(_ state: inout State) {
        let originalSource = state.inputOriginalText.isEmpty ? state.inputMemoText : state.inputOriginalText
        state.emojiString = EmojiString.normalizedForPersist(
            originalText: originalSource,
            preferredEmojiText: state.inputMemoText
        )

        state.emojiString.setUnassignedEmojis()
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
    
    private func saveMemo(_ state: State) -> State {
        var newState = state
        let newMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText:
                newState.emojiString.getOriginalString(),
            emojiText:
                newState.emojiString.getEmojiString()
        )
        
        switch memoRepository.save(memo: newMemo) {
        case .success:
            newState.memos.append(newMemo)
            newState.inputMemoText = ""
            newState.inputOriginalText = ""
            newState.inputSnapshotRevision += 1
            newState.inputSeedVersion += 1
            newState.isInputEmpty = true
            newState.emojiString = EmojiString()
            newState.savePhase = .idle
        case .failure(let error):
            print("메모 저장 실패: \(error)")
            newState.savePhase = .idle
        }
        return newState
    }
    
    private func updateMemo(_ state: State, _ memo: Memo) -> State {
        var newState = state
        var updatedMemo = memo
        
        updatedMemo.originalText = newState.emojiString.getOriginalString()
        updatedMemo.emojiText = newState.emojiString.getEmojiString()
        
        switch memoRepository.update(memo: updatedMemo) {
        case .success:
            if let index = newState.memos.firstIndex(where: { $0.id == memo.id }) {
                newState.memos[index] = updatedMemo
            }
            
            newState.resetEditingMemo()
            newState.savePhase = .idle
        case .failure(let error):
            print("메모 업데이트 실패: \(error)")
            newState.savePhase = .idle
        }
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
