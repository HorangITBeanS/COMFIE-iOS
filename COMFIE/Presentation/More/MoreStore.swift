//
//  MoreStore.swift
//  COMFIE
//
//  Created by Anjin on 4/10/25.
//

import Foundation

@Observable
class MoreStore: IntentStore {
    private(set) var state: State = .init()
    struct State {
        // 현재 버전
        var currentVersion: String {
            let versionKey = "CFBundleShortVersionString"
            guard let version: String = Bundle.main.infoDictionary?[versionKey] as? String else { return "nil-version" }
            
            return " \(version)"
        }
    }
    
    enum Intent {
        case serviceTermRowTapped
        case privacyPolicyRowTapped
        case locationTermRowTapped
        
        case sendFeedbackRowTapped
        case makersRowTapped
    }
    
    enum Action {
        case navigateToServiceTerm
        case navigateToPrivacyPolicy
        case navigateToLocationTerm
        
        case navigateToSendFeedback
        case navigateToMakers
    }
    
    private let router: Router

    init(router: Router) {
        self.router = router
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .serviceTermRowTapped:
            _ = handleAction(state, .navigateToServiceTerm)
        case .privacyPolicyRowTapped:
            _ = handleAction(state, .navigateToPrivacyPolicy)
        case .locationTermRowTapped:
            _ = handleAction(state, .navigateToLocationTerm)
        case .sendFeedbackRowTapped:
            _ = handleAction(state, .navigateToSendFeedback)
        case .makersRowTapped:
            _ = handleAction(state, .navigateToMakers)
        }
    }
    
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .navigateToServiceTerm:
            router.push(.serviceTerm)
        case .navigateToPrivacyPolicy:
            router.push(.privacyPolicy)
        case .navigateToLocationTerm:
            router.push(.locationTerm)
        case .navigateToSendFeedback:
            router.push(.sendFeedback)
        case .navigateToMakers:
            router.push(.makers)
        }
        return newState
    }
}
