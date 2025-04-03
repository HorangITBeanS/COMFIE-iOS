//
//  MemoStore.swift
//  COMFIE
//
//  Created by zaehorang on 3/6/25.
//

import Combine
import Foundation

@Observable
class MemoStore: IntentStore {
    private(set) var state: State = .init()
    private let router: Router
    private let memoRepository: MemoRepositoryProtocol
    
    let sideEffectPublisher = PassthroughSubject<SideEffect, Never>()
    
    // MARK: State
    struct State {
        var memos: [Memo] = []
        // 사용자가 텍스트 필드에 입력하는 메모
        var inputMemoText: String = ""
        var editingMemo: Memo?
        var deletingMemo: Memo?
        
        var hideMemoIDs: Set<UUID> = []
        
        func isMemoHidden(_ memo: Memo) -> Bool {
                hideMemoIDs.contains(memo.id)
            }
        func isEditingMemo(_ memo: Memo) -> Bool {
            editingMemo?.id == memo.id
        }
    }
    
    // MARK: Intent
    enum Intent {
        case deletePopup(PopupIntent)
        case memoInput(MemoInputIntent)
        case memoCell(MemoCellIntent)
        
        case onAppear
        case backgroundTapped
        case comfieZoneSettingButtonTapped
        
        enum PopupIntent {
            case confirmDeleteButtonTapped
            case cancelDeleteButtonTapped
        }
        
        enum MemoInputIntent {
            case updateNewMemo(String)
            case memoInputButtonTapped
        }
        
        enum MemoCellIntent {
            case editButtonTapped(Memo)
            case retrospectionButtonTapped(Memo)
            case deleteButtonTapped(Memo)
            case editingCancelButtonTapped
            
            case hideMemo(Memo)
        }
    }
    
    // MARK: Action
    enum Action {
        case memo(MemoAction)
        case input(InputAction)
        case popup(PopupAction)

        enum MemoAction {
            case fetchAll
            case save
            case update(Memo)
            case delete
            
            case hideMemo(Memo)
        }

        enum InputAction {
            case updateText(String)
            case startEditing(Memo)
            case cancelEditing
        }
        
        enum PopupAction {
            case showDeletePopup(Memo)
            case cancelDelete
        }
    }
    
    // MARK: Side Effect
    enum SideEffect {
        case navigation(Navigation)
        case ui(UI)

        enum Navigation {
            case toRetrospection(Memo)
            case toComfieZoneSetting
        }

        enum UI {
            case removeMemoInputFocus
            case setMemoInputFocus
        }
    }
    
    // MARK: Init
    init(router: Router, memoRepository: MemoRepositoryProtocol) {
        self.router = router
        self.memoRepository = memoRepository
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
        case .backgroundTapped:
            performSideEffect(for: .ui(.removeMemoInputFocus))
        case .comfieZoneSettingButtonTapped:
            performSideEffect(for: .navigation(.toComfieZoneSetting))
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
            let newState = handleAction(state, .input(.startEditing(memo)))
            performSideEffect(for: .ui(.setMemoInputFocus))
            return newState
        case .editingCancelButtonTapped:
            let newState = handleAction(state, .input(.cancelEditing))
            performSideEffect(for: .ui(.removeMemoInputFocus))
            return newState
        case .retrospectionButtonTapped(let memo):
            performSideEffect(for: .navigation(.toRetrospection(memo)))
            return state
        case .hideMemo(let memo):
            return handleAction(state, .memo(.hideMemo(memo)))
        }
    }
    
    private func handleMemoInputIntent(_ intent: Intent.MemoInputIntent) -> State {
        switch intent {
        case .memoInputButtonTapped:
            let newState: State
            if let editingMemo = state.editingMemo {
                newState = handleAction(state, .memo(.update(editingMemo)))
            } else {
                newState = handleAction(state, .memo(.save))
            }
            
            performSideEffect(for: .ui(.removeMemoInputFocus))
            return newState
        case .updateNewMemo(let text):
            return handleAction(state, .input(.updateText(text)))
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
            return saveMemo(newState)
        case .update(let updatedMemo):
            return updateMemo(newState, updatedMemo)
        case .delete:
            if let memo = newState.deletingMemo {
                return deleteMemo(newState, memo)
            }
        case .hideMemo(let memo):
            if newState.hideMemoIDs.contains(memo.id) {
                newState.hideMemoIDs.remove(memo.id)
            } else {
                newState.hideMemoIDs.insert(memo.id)
            }
        }
        return newState
    }
    
    private func handleInputAction(_ state: State, _ action: Action.InputAction) -> State {
        var newState = state
        switch action {
        case .updateText(let text):
            newState.inputMemoText = text
        case .startEditing(let memo):
            return startEditingMemo(newState, memo)
        case .cancelEditing:
            return clearEditingState(newState)
        }
        return newState
    }
    
    private func handlePopupAction(_ state: State, _ action: Action.PopupAction) -> State {
        var newState = state
        switch action {
        case .showDeletePopup(let memo):
            newState.deletingMemo = memo
        case .cancelDelete:
            newState.deletingMemo = nil
        }
        return newState
    }
}

// MARK: - Side Effect Method
extension MemoStore {
    private func performSideEffect(for action: SideEffect) {
        sideEffectPublisher.send(action)
        
        switch action {
        case .navigation(.toRetrospection(let memo)):
            // TODO: 해당 뷰에 메모를 전달줘야 한다.
            router.push(.retrospection)
        case .navigation(.toComfieZoneSetting):
            router.push(.comfieZoneSetting)
        default:
            break
        }
    }
}

// MARK: - Helper Methods
extension MemoStore {
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
            originalText: newState.inputMemoText,
            emojiText: "🐯🐯🐯🐯"
            // TODO: 이모지 변경
        )
        
        switch memoRepository.save(memo: newMemo) {
        case .success:
            newState.memos.append(newMemo)
            newState.inputMemoText = ""
        case .failure(let error):
            print("메모 저장 실패: \(error)")
        }
        return newState
    }
    
    private func startEditingMemo(_ state: State, _ memo: Memo) -> State {
        var newState = state
        newState.editingMemo = memo
        newState.inputMemoText = memo.originalText
        return newState
    }
    
    private func updateMemo(_ state: State, _ memo: Memo) -> State {
        var newState = state
        var updatedMemo = memo
        updatedMemo.originalText = newState.inputMemoText
        
        switch memoRepository.update(memo: updatedMemo) {
        case .success:
            if let index = newState.memos.firstIndex(where: { $0.id == memo.id }) {
                newState.memos[index] = updatedMemo
            }
            newState.editingMemo = nil
            newState.inputMemoText = ""
        case .failure(let error):
            print("메모 업데이트 실패: \(error)")
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
            newState.deletingMemo = nil
        case .failure(let error):
            print("메모 삭제 실패: \(error)")
        }
        return newState
    }
    
    private func clearEditingState(_ state: State) -> State {
        var newState = state
        newState.editingMemo = nil
        newState.inputMemoText = ""
        return newState
    }
}
