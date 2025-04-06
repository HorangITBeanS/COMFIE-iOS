//
//  RetrospectionStore.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 4/6/25.
//

import Foundation

@Observable
class RetrospectionStore: IntentStore {
    private(set) var state: State = .init()
    
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
    
    struct State {
        var originalMemo: String = ""
        var inputContent: String = ""
    }
    
    enum Intent {
        case onAppear
        case backgroundTapped
        
        case updateNewRetrospection(String)
    }
    
    // MARK: - Action
    
    enum Action {
        case fetchMemo
    }
    
    // MARK: - Side Effect
    enum SideEffect {
        case navigation
        case ui(UI)
        
        enum UI {
            case setContentFieldFocus
            case removeContentFieldFocus
        }
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .onAppear: state = handleAction(state, .fetchMemo)
        case .backgroundTapped: print("backgroundTapped")
        case .updateNewRetrospection(let content): print("updateNewRetrospection: \(content)")
        }
    }
    
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .fetchMemo: print("fetchMemo")
            newState.originalMemo = "Hello, World!"
        }
        return newState
    }
}
