//
//  OnboardingIntent.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import Foundation

@Observable
class OnboardingStore: IntentStore {
    // MARK: 화면에 사용되는 상태, 밖에서는 setter에 접근 불가능
    private(set) var state: State = .init()
    struct State { }
    
    // MARK: 사용자가 화면에서 하고자 하는 '의도'
    enum Intent {
        case nextButtonTapped  // 다음 버튼 탭
    }
    
    // MARK: Intent를 수행하기 위해 필요한 동작
    enum Action {
        case requestLocationPermission       // 사용자 위치 정보 요청
        case navigateToMainScreen            // 메인 스크린으로 이동
    }
    
    // MARK: 화면 전환을 위한 router
    private let router: Router
    private let locationUseCase: LocationUseCase

    init(router: Router, locationUseCase: LocationUseCase) {
        self.router = router
        self.locationUseCase = locationUseCase
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .nextButtonTapped:
            // 사용자에게 위치 정보 허용 요청
            _ = handleAction(state, .requestLocationPermission)
            
            // 다음 화면으로 이동
            _ = handleAction(state, .navigateToMainScreen)
        }
    }
    
    // State가 불변 상태를 유지할 수 있도록 - 새로운 객체를 생성하여 대체한다
    // 이전 상태와 액션을 입력 받아 새로운 상태를 반환
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .requestLocationPermission:
            locationUseCase.requestLocationAuthorization()
            
        case .navigateToMainScreen:
            router.hasEverOnboarded = true
        }
        return newState
    }
}
