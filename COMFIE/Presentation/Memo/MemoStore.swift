//
//  MemoStore.swift
//  COMFIE
//
//  Created by zaehorang on 3/6/25.
//

import UIKit

@Observable
class MemoStore: IntentStore {
    private(set) var state: State = .init()
    private let router: Router // 화면 전환을 위한 router
    private let memoRepository: MemoRepository
    
    // MARK: State
    struct State {
        var memos: [Memo] = []
        // 사용자가 텍스트 필드에 입력하는 메모
        var inputMemoText: String = ""
        var editingMemo: Memo?
        var deletingMemo: Memo?
    }
    
    // MARK:  Intent
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
        }
    }
    
    // MARK: Action
    enum Action {
        case navigateToRetrospectionView(Memo)  // 회고 화면으로
        case navigateToComfieZoneSettingView  // 컴피존 설정 화면으로
        
        case saveMemo
        case fetchMemos
        
        case showDeleteMemoPopup(Memo)
        case deleteMemo
        case cancelDeleteMemo
        
        case updateMemo(Memo)
        
        case setNewMemo(String)
        case startEditingMemo(Memo)
        case cancelEditing
        
        case hideKeyboard
    }
    
    // MARK: init
    init(router: Router, memoRepository: MemoRepository) {
        self.router = router
        self.memoRepository = memoRepository
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .memoCell(let memoCellIntent):
            state = handleMemoCellIntent(memoCellIntent)
        case .memoInput(let memoInputIntent):
            state = handleMemoInputIntent(memoInputIntent)
        case .deletePopup(let popupIntent):
            state = handleDeletePopupIntent(popupIntent)
            
        case .onAppear:
            state = handleAction(state, .fetchMemos)
        case .backgroundTapped:
            _ = handleAction(state, .hideKeyboard)
        case .comfieZoneSettingButtonTapped:
            state = handleAction(state, .navigateToComfieZoneSettingView)
        }
    }
    
    // State가 불변 상태를 유지할 수 있도록 - 새로운 객체를 생성하여 대체한다
    // 이전 상태와 액션을 입력 받아 새로운 상태를 반환
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        
        switch action {
        case .navigateToRetrospectionView:
            // TODO: 메모 데이터 주입해주기 + 네비게이션 확인
            router.push(.retrospection)
        case .navigateToComfieZoneSettingView:
            router.push(.comfieZoneSetting)
            
        case .setNewMemo(let text):
            newState.inputMemoText = text
        case .saveMemo:
            return handleSaveMemo(newState)
        case .fetchMemos:
            return handleFetchMemos(newState)
        case .startEditingMemo(let memo):
            return handleStartEditingMemo(newState, memo)
        case .updateMemo(let updatedMemo):
            return handleUpdateMemo(newState, updatedMemo)
        case .cancelEditing:
            return clearEditingState(newState)
            
        case .showDeleteMemoPopup(let memo):
            newState.deletingMemo = memo
        case .deleteMemo:
            if let memo = newState.deletingMemo {
                return handleDeleteMemo(newState, memo)
            }
        case .cancelDeleteMemo:
            newState.deletingMemo = nil
            
        case .hideKeyboard:
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
        return newState
    }
}

// MARK: - Handle Intent Methods
extension MemoStore {
    private func handleMemoCellIntent(_ intent: Intent.MemoCellIntent) -> State {
        switch intent {
        case .deleteButtonTapped(let memo):
            return handleAction(state, .showDeleteMemoPopup(memo))
        case .editButtonTapped(let memo):
            return handleAction(state, .startEditingMemo(memo))
        case .editingCancelButtonTapped:
            return handleAction(state, .cancelEditing)
        case .retrospectionButtonTapped(let memo):
            return handleAction(state, .navigateToRetrospectionView(memo))
        }
    }
    
    private func handleMemoInputIntent(_ intent: Intent.MemoInputIntent) -> State {
        switch intent {
        case .memoInputButtonTapped:
            let newState: State
            if let editingMemo = state.editingMemo {
                newState = handleAction(state, .updateMemo(editingMemo))
            } else {
                newState = handleAction(state, .saveMemo)
            }
            return handleAction(newState, .hideKeyboard)
        case .updateNewMemo(let text):
            return handleAction(state, .setNewMemo(text))
        }
    }
    
    private func handleDeletePopupIntent(_ intent: Intent.PopupIntent) -> State {
        switch intent {
        case .cancelDeleteButtonTapped:
            return handleAction(state, .cancelDeleteMemo)
        case .confirmDeleteButtonTapped:
            return handleAction(state, .deleteMemo)
        }
    }
}

// MARK: - Handle Action Methods
extension MemoStore {
    private func handleFetchMemos(_ state: State) -> State {
        var newState = state
        switch memoRepository.fetchAllMemos() {
        case .success(let memos):
            newState.memos = memos
        case .failure(let error):
            print("메모 불러오기 실패: \(error)")
        }
        return newState
    }
    
    private func handleSaveMemo(_ state: State) -> State {
        var newState = state
        let newMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: newState.inputMemoText,
            emojiText: "🐯🐯🐯🐯"
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
    
    private func handleStartEditingMemo(_ state: State, _ memo: Memo) -> State {
        var newState = state
        newState.editingMemo = memo
        newState.inputMemoText = memo.originalText
        return newState
    }
    
    private func handleUpdateMemo(_ state: State, _ memo: Memo) -> State {
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
    
    private func handleDeleteMemo(_ state: State, _ memo: Memo) -> State {
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
