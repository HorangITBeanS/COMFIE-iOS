//
//  RetrospectionStore.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 4/6/25.
//

import Combine
import SwiftUI

@Observable
class RetrospectionStore: IntentStore {
    private(set) var state: State = .init()
    
    let sideEffectPublisher = PassthroughSubject<SideEffect, Never>()
    
    private let router: Router
    private let repository: RetrospectionRepsitoryProtocol
    
    let memo: Memo
    
    init(router: Router, repository: RetrospectionRepsitoryProtocol, memo: Memo) {
        self.router = router
        self.repository = repository
        self.memo = memo
    }
    
    struct State {
        var originalMemo: String = ""
        var inputContent: String = ""
        var showCompleteButton: Bool = false
        var showDeletePopupView: Bool = false
    }
    
    enum Intent {
        case onAppear
        case backgroundTapped
        case contentFieldTapped
        case updateRetrospection(String)
        
        // 네비게이션바 내 버튼
        case backButtonTapped
        case deleteMenuButtonTapped
        case completeButtonTapped
        
        // 삭제 팝업 내 버튼
        case deleteRetrospectionButtonTapped
        case cancelDeleteRetrospectionButtonTapped
    }
    
    // MARK: - Action
    
    enum Action {
        // retrospection CRUD
        case fetchMemo
        case updateRetrospection(String)
        case saveRetrospection
        case deleteRetrospection
        
        // complete Button
        case showCompleteButton
        case hideCompleteButton
        
        // delete-Popup view
        case showDeletePopupView
        case hideDeletePopupView
        
        case popToLast
    }
    
    // MARK: - Side Effect
    
    enum SideEffect {
        case ui(UI)
        
        enum UI {
            case setContentFieldFocus
            case removeContentFieldFocus
        }
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .onAppear:
            state = handleAction(state, .fetchMemo)
            performSideEffect(for: .ui(.setContentFieldFocus))
        case .backgroundTapped:
            performSideEffect(for: .ui(.removeContentFieldFocus))
            state = handleAction(state, .hideCompleteButton)
        case .contentFieldTapped:
            performSideEffect(for: .ui(.setContentFieldFocus))
            state = handleAction(state, .showCompleteButton)
        case .updateRetrospection(let content): state = handleAction(state, .updateRetrospection(content))
            
        case .backButtonTapped: state = handleAction(state, .saveRetrospection)
        case .deleteMenuButtonTapped:
            withAnimation { state = handleAction(state, .showDeletePopupView) }
            performSideEffect(for: .ui(.removeContentFieldFocus))
        case .completeButtonTapped:
            performSideEffect(for: .ui(.removeContentFieldFocus))
            state = handleAction(state, .hideCompleteButton)
            
        case .deleteRetrospectionButtonTapped:
            state = handleAction(state, .deleteRetrospection)
            _ = handleAction(state, .popToLast)
        case .cancelDeleteRetrospectionButtonTapped: state = handleAction(state, .hideDeletePopupView)
        }
    }
    
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .fetchMemo:
            newState.originalMemo = memo.originalText
            if let retrospection = memo.retrospectionText {
                newState.inputContent = retrospection
            }
        case .updateRetrospection(let text): newState.inputContent = text
        case .showCompleteButton: newState.showCompleteButton = true
        case .hideCompleteButton: newState.showCompleteButton = false
            
        case .saveRetrospection: _ = saveRetrospection(newState)
        case .deleteRetrospection: _ = deleteRetrospection(newState)
            
        case .showDeletePopupView: newState.showDeletePopupView = true
        case .hideDeletePopupView: newState.showDeletePopupView = false
        case .popToLast: router.pop()
        }
        return newState
    }
}

//MARK: - Helper Methods
extension RetrospectionStore {
    private func saveRetrospection(_ state: State) -> State {
        var newState = state
        let memo = Memo(id: memo.id,
                        createdAt: memo.createdAt,
                        originalText: memo.originalText,
                        emojiText: memo.emojiText,
                        retrospectionText: newState.inputContent)
        switch repository.update(memo: memo) {
        case .success(let success):
            print("저장 성공!")
        case .failure(let failure):
            print("\(memo)저장을 실패했습니다.")
        }
        
        return newState
    }
    
    private func deleteRetrospection(_ state: State) -> State {
        var newState = state
        switch repository.delete(memo: memo) {
        case .success(let success):
            print("삭제 성공!")
        case .failure(let failure):
            print("\(memo)삭제를 실패했습니다.")
        }
        
        return newState
    }
}

// MARK: - Side Effect Method

extension RetrospectionStore {
    private func performSideEffect(for action: SideEffect) {
        sideEffectPublisher.send(action)
    }
}
