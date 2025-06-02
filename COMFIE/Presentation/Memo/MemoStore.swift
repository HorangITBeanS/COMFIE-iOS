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
    // MARK: State
    struct State {
        var memos: [Memo] = []
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
        var editingMemo: Memo?
        var deletingMemo: Memo?
        
        func isEditingMemo(_ memo: Memo) -> Bool {
            editingMemo?.id == memo.id
        }
        
        mutating func setEditingMemo(_ memo: Memo) {
            editingMemo = memo
            inputMemoText = memo.emojiText
            emojiString = EmojiString(memo: memo)
        }
        
        mutating func resetEditingMemo() {
            emojiString = .init()
            inputMemoText = ""
            editingMemo = nil
        }
        
        mutating func setDeletingMemo(_ memo: Memo) {
            deletingMemo = memo
        }
        
        mutating func resetDeletingMemo() {
            deletingMemo = nil
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
        case moreButtonTapped
        
        enum PopupIntent {
            case confirmDeleteButtonTapped
            case cancelDeleteButtonTapped
        }
        
        enum MemoInputIntent {
            case updateNewMemo(String)
            case memoInputButtonTapped
            
            case transformTriggerDetected(index: Int, newMemoText: String)
            case deleteTriggerDetected(start: Int, end: Int?)
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
        
        enum MemoAction {
            case fetchAll
            case save
            case update(Memo)
            case delete
        }
        
        enum InputAction {
            case updateText(String)
            case startEditing(Memo)
            case cancelEditing
            
            case updateEmojiString(index: Int, newMemoText: String)
            case deleteEmojiString(start: Int, end: Int?)
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
    }
    
    // MARK: Side Effect
    enum SideEffect {
        case ui(UI)
        
        enum UI {
            case resignInputFocusWithSyncInput
            case setMemoInputFocus
            case updateInputViewWithState
        }
    }
    
    // MARK: ScrollEffect
    enum ScrollEffect {
        case toMemo(id: UUID)
        case toBottom
    }
    
    private let router: Router
    private let memoRepository: MemoRepositoryProtocol
    
    private(set) var sideEffectPublisher = PassthroughSubject<SideEffect, Never>()
    private(set) var scrollEffectPublisher = PassthroughSubject<ScrollEffect, Never>()
    
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
            performSideEffect(for: .ui(.resignInputFocusWithSyncInput))
        case .comfieZoneSettingButtonTapped:
            state = handleAction(state, .navigation(.toComfieZoneSetting))
        case .moreButtonTapped:
            state = handleAction(state, .navigation(.toMore))
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
            performSideEffect(for: .ui(.updateInputViewWithState))
            performSideEffect(for: .ui(.setMemoInputFocus))
            
            // 메모 수정 시, 해당 메모 위치로 스크롤 이동
            performSCrollEffect(for: .toMemo(id: memo.id))
            return newState
        case .editingCancelButtonTapped:
            let newState = handleAction(state, .input(.cancelEditing))
            performSideEffect(for: .ui(.updateInputViewWithState))
            performSideEffect(for: .ui(.resignInputFocusWithSyncInput))
            return newState
        case .retrospectionButtonTapped(let memo):
            let newState = handleNavigationAction(state, .toRetrospection(memo))
            return newState
        }
    }
    
    private func handleMemoInputIntent(_ intent: Intent.MemoInputIntent) -> State {
        switch intent {
        case .memoInputButtonTapped:
            // ⚠️ 텍스트뷰에 보이는 값과 상태가 불일치하는 문제 방지를 위해, 입력 종료 시 델리게이트 메서드에서 동기화 메서드를 추가로 실행함.
            performSideEffect(for: .ui(.resignInputFocusWithSyncInput))
            
            // resignFirstResponder 호출과 그 후 동작들이 모두 메인 스레드(MainActor)에서 실행되어 순서가 보장됨.
            Task { @MainActor in
                if let editingMemo = state.editingMemo {
                    // 메모 수정 중
                    self.state = handleAction(state, .memo(.update(editingMemo)))
                } else {
                    // 새로운 메모 작성 중
                    self.state = handleAction(state, .memo(.save))
                    
                    // 메모가 추가 시, 해당 메모 위치(bottom)으로 스크롤 이동
                    performSCrollEffect(for: .toBottom)
                }
            }
            
            performSideEffect(for: .ui(.updateInputViewWithState))
            // 🥲 여기 리턴 값은 사실상 의미 없는 값
            return state
        case .updateNewMemo(let text):
            return handleAction(state, .input(.updateText(text)))
        case .transformTriggerDetected(index: let index, newMemoText: let newMemoText):
            return handleAction(state, .input(.updateEmojiString(index: index, newMemoText: newMemoText)))
        case .deleteTriggerDetected(start: let start, end: let end):
            return handleAction(state, .input(.deleteEmojiString(start: start, end: end)))
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
            // 동기화
            newState.emojiString.syncWithNewString(newState.inputMemoText)
            // 이모지 채우기
            newState.emojiString.setUnassignedEmojis()
            return saveMemo(newState)
        case .update(let updatedMemo):
            // 동기화
            newState.emojiString.syncWithNewString(newState.inputMemoText)
            // 이모지 채우기
            newState.emojiString.setUnassignedEmojis()
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
        case .updateText(let text):
            newState.inputMemoText = text
        case .startEditing(let memo):
            // 작성되고 있던 메모 reset
            newState.resetEditingMemo()
            newState.setEditingMemo(memo)
        case .cancelEditing:
            newState.resetEditingMemo()
        case .updateEmojiString(index: let index, newMemoText: let newMemoText):
            newState.emojiString.applyEmojiString(at: index, newMemoText)
        case .deleteEmojiString(start: let start, end: let end):
            // 삭제 전, 지금까지 입력된 문자로 동기화를 먼저 진행
            newState.emojiString.syncWithNewString(newState.inputMemoText)
            newState.emojiString.deleteEmojiString(from: start, to: end)
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
}

// MARK: - Side Effect Method
extension MemoStore {
    private func performSideEffect(for action: SideEffect) {
        sideEffectPublisher.send(action)
    }
    
    private func performSCrollEffect(for action: ScrollEffect) {
        scrollEffectPublisher.send(action)
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
            originalText:
                newState.emojiString.getOriginalString(),
            emojiText:
                newState.emojiString.getEmojiString()
        )
        
        switch memoRepository.save(memo: newMemo) {
        case .success:
            newState.memos.append(newMemo)
            newState.inputMemoText = ""
            newState.emojiString = EmojiString()
        case .failure(let error):
            print("메모 저장 실패: \(error)")
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
            
            newState.resetDeletingMemo()
        case .failure(let error):
            print("메모 삭제 실패: \(error)")
        }
        return newState
    }
}
