//
//  MoreStore.swift
//  COMFIE
//
//  Created by Anjin on 4/10/25.
//

import Foundation
import MessageUI

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
        
        // 메일앱 활성화 여부
        var isMailAppActivate: Bool = false
        var showMailSheet: Bool = false
    }
    
    enum Intent {
        case serviceTermRowTapped
        case privacyPolicyRowTapped
        case locationTermRowTapped
        
        // 의견 보내기 - 메일앱 활성화 체크 후 화면 전환
        case sendFeedbackRowTapped
        case dismissMailSheet
        
        case makersRowTapped
    }
    
    enum Action {
        case navigateToServiceTerm
        case navigateToPrivacyPolicy
        case navigateToLocationTerm
        
        case checkMailAppActivate
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
            // 메일앱 활성화 여부 확인
            state = handleAction(state, .checkMailAppActivate)
            if state.isMailAppActivate {
                // 활성화 O > 메일앱 시트
                state.showMailSheet = true
            } else {
                // 활성화 X > 기본 화면
                _ = handleAction(state, .navigateToSendFeedback)
            }
        case .makersRowTapped:
            _ = handleAction(state, .navigateToMakers)
        case .dismissMailSheet:
            state.showMailSheet = false
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
        case .checkMailAppActivate:
            newState.isMailAppActivate = MFMailComposeViewController.canSendMail()
        case .navigateToSendFeedback:
            router.push(.sendFeedback)
        case .navigateToMakers:
            router.push(.makers)
        }
        return newState
    }
}
