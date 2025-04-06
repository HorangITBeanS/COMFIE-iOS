//
//  RetrospectionStore.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 4/6/25.
//

import Combine
import Foundation

@Observable
class RetrospectionStore: IntentStore {
    private(set) var state: State = .init()
    
    private let router: Router
    
    let sideEffectPublisher = PassthroughSubject<SideEffect, Never>()
    
    init(router: Router) {
        self.router = router
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
        case updateNewRetrospection(String)
        case backButtonTapped
        case deleteMenuButtonTapped
        
        case deleteRetrospectionButtonTapped
        case cancelDeleteRetrospectionButtonTapped
    }
    
    // MARK: - Action
    
    enum Action {
        case fetchMemo
        
        case showCompleteButton
        case hideCompleteButton
        
        case saveRetrospection
        case deleteRetrospection
        
        case showDeletePopupView
        case hideDeletePopupView
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
        case .updateNewRetrospection(let content): print("updateNewRetrospection: \(content)")
        case .backButtonTapped: state = handleAction(state, .saveRetrospection)
        case .deleteMenuButtonTapped:
            state = handleAction(state, .showDeletePopupView)
            performSideEffect(for: .ui(.removeContentFieldFocus))
        case .deleteRetrospectionButtonTapped: state = handleAction(state, .deleteRetrospection)
        case .cancelDeleteRetrospectionButtonTapped: state = handleAction(state, .hideDeletePopupView)
        }
    }
    
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .fetchMemo: print("fetchMemo")
            
        case .showCompleteButton: newState.showCompleteButton = true
        case .hideCompleteButton: newState.showCompleteButton = false
            
        case .saveRetrospection: print("saveRetrospection")
        case .deleteRetrospection: print("deleteRetrospection")
            
        case .showDeletePopupView: newState.showDeletePopupView = true
        case .hideDeletePopupView: newState.showDeletePopupView = false
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
