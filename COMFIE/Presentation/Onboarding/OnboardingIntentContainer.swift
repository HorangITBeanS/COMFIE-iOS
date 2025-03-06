//
//  OnboardingIntent.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import Foundation

enum LocationPermissionStatus {
    case notDetermined
    case denied
    case authorizedAlways
    case authorizedWhenInUse
}

@Observable
class OnboardingIntentContainer: IntentContainer {
    // MARK: 화면에 사용되는 상태, 밖에서는 setter에 접근 불가능
    private(set) var state: State = .init()
    struct State {
        var locationPermissionStatus: LocationPermissionStatus?
    }
    
    // MARK: 사용자가 화면에서 하고자 하는 '의도'
    enum Intent {
        case nextButtonTapped  // 다음 버튼 탭
    }
    
    // MARK: Intent를 수행하기 위해 필요한 동작
    enum Action {
        case requestLocationPermission       // 사용자 위치 정보 요청
        case updateLocationPermissionStatus(LocationPermissionStatus)  // 위치 허용 권한 업데이트
        case navigateToMainScreen            // 메인 스크린으로 이동
    }
    
    func intent(_ action: Intent) {
        switch action {
        case .nextButtonTapped:
            // 사용자에게 위치 정보 허용 요청
            _ = reduce(state, .requestLocationPermission)
            
            // 사용자의 허용 정보에 따라 State 변경
            let permissionStatus = LocationPermissionStatus.authorizedAlways
            state = reduce(state, .updateLocationPermissionStatus(permissionStatus))
            
            // 다음 화면으로 이동
            _ = reduce(state, .navigateToMainScreen)
        }
    }
    
    // State가 불변 상태를 유지할 수 있도록 - 새로운 객체를 생성하여 대체한다
    // 이전 상태와 액션을 입력 받아 새로운 상태를 반환
    private func reduce(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .requestLocationPermission:
            print("요청 요청")
            
        case .updateLocationPermissionStatus:
            print("위치 요청")
            newState.locationPermissionStatus = .authorizedAlways
            
        case .navigateToMainScreen:
            print("메인화면으로 이동")
        }
        return newState
    }
}
