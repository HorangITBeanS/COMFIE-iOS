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
        
        var showMailUnavailablePopupView: Bool = false
    }
    
    enum Intent {
        case serviceTermRowTapped
        case privacyPolicyRowTapped
        
        // 의견 보내기 - 메일앱 활성화 체크 후 화면 전환
        case sendFeedbackRowTapped
        case dismissMailSheet
        
        // 메일 비활성화 알럿 내 버튼
        case copyMailButtonTapped
        case closePopupButtonTapped
        
        case makersRowTapped
    }
    
    enum Action {
        case navigateToServiceTerm
        case navigateToPrivacyPolicy
        
        case checkMailAppActivate
        case copyMail
        case hideMailUnavailablePopupView
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
        case .sendFeedbackRowTapped:
            // 메일앱 활성화 여부 확인
            state = handleAction(state, .checkMailAppActivate)
            if state.isMailAppActivate {
                // 활성화 O > 메일앱 시트
                state.showMailSheet = true
            } else {
                // 활성화 X > 기본 화면
                state.showMailUnavailablePopupView = true
            }
        case .copyMailButtonTapped:
            state = handleAction(state, .copyMail)
        case .closePopupButtonTapped:
            state = handleAction(state, .hideMailUnavailablePopupView)
        case .dismissMailSheet:
            state.showMailSheet = false
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
        case .checkMailAppActivate:
            newState.isMailAppActivate = MFMailComposeViewController.canSendMail()
        case .copyMail:
            copyEmail()
            newState.showMailUnavailablePopupView = false
        case .hideMailUnavailablePopupView:
            newState.showMailUnavailablePopupView = false
        case .navigateToMakers:
            router.push(.makers)
        }
        return newState
    }
    
    func copyEmail(_ text: String = StringLiterals.More.SendFeedback.emailAddress) {
        if UIPasteboard.general.hasStrings {
            UIPasteboard.general.string = text
        } else {
            // 접근 권한 없어 복사 실패
        }
    }
}
