//
//  MemoStore.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import Foundation

@Observable
class MemoStore: IntentStore {
    private(set) var state: State = .init()
    struct State { }
    
    enum Intent {
        case showRetrospectionView      // 회고 화면으로
        case showComfieZoneSettingView  // 컴피존 설정 화면으로
    }
    
    enum Action {
        case navigateToRetrospectionView  // 회고 화면으로
        case navigateToComfieZoneSettingView  // 컴피존 설정 화면으로
    }
    
    // 화면 전환을 위한 router
    private let router: Router

    init(router: Router) {
        self.router = router
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .showRetrospectionView:
            state = handleAction(state, .navigateToRetrospectionView)
        case .showComfieZoneSettingView:
            state = handleAction(state, .navigateToComfieZoneSettingView)
        }
    }
    
    // State가 불변 상태를 유지할 수 있도록 - 새로운 객체를 생성하여 대체한다
    // 이전 상태와 액션을 입력 받아 새로운 상태를 반환
    private func handleAction(_ state: State, _ action: Action) -> State {
        let newState = state
        switch action {
        case .navigateToRetrospectionView:
            router.push(.retrospection)
        case .navigateToComfieZoneSettingView:
            router.push(.comfieZoneSetting)
        }
        return newState
    }
}
