//
//  ComfieZoneSettingStore.swift
//  COMFIE
//
//  Created by Anjin on 4/4/25.
//

import MapKit
import SwiftUI

enum ComfieZoneSettingBottomSheetState {
    case plusButton
    case comfiezoneSettingTextField
    case comfieZoneName
}

@Observable
class ComfieZoneSettingStore: IntentStore {
    private(set) var state: State = .init()
    struct State {
        /// 컴피존 안내 팝업
        var showInfoPopup: Bool = false
        
        /// 지도 초기 위치
        var initialPosition = MKCoordinateRegion(
            center: CLLocationCoordinate2D(  // 정자역
                latitude: 37.3663000,
                longitude: 127.1083000
            ),
            latitudinalMeters: 200,  // 지도 반경
            longitudinalMeters: 200
        )
        
        var bottomSheetState: ComfieZoneSettingBottomSheetState = .comfieZoneName
        var isLocationAuthorized: Bool = true
//        var isLocationAuthorized: Bool = false
        var newComfiezoneName: String = ""
        
        // 컴피존 가져오기
        var comfieZone: ComfieZone? = {
            ComfieZone(id: UUID(), longitude: 37.3663000, latitude: 127.1083000, name: "여기는 우리집~")
        }()
        var isInComfieZone: Bool = true
    }
    
    enum Intent {
        case infoButtonTapped  // 컴피존 안내 버튼 클릭
        case closeInfoPopup    // 컴피존 안내 팝업 닫기
        
        // Bottom Sheet
        case plusButtonTapped  // 컴피존 추가 버튼 클릭
        case updateComfieZoneNameTextField(String)
        case checkButtonTapped
        case xButtonTapped
    }
    
    enum Action {
        // Bottom Sheet
        case showRequestLocationPermissionPopup
        case activeComfiezoneSettingTextField
        case addComfieZone
        case showDeleteComfieZonePopup
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .infoButtonTapped:
            state.showInfoPopup = true
        case .closeInfoPopup:
            withAnimation {
                state.showInfoPopup = false
            }
        case .plusButtonTapped:
            if state.isLocationAuthorized {
                // 권한 설정 있을 때 - 텍스트필드 활성화
                state = handleAction(state, .activeComfiezoneSettingTextField)
            } else {
                // 권한 설정이 없을 때 - 설정 팝업
                state = handleAction(state, .showRequestLocationPermissionPopup)
            }
        case .updateComfieZoneNameTextField(let text):
            state.newComfiezoneName = text
        case .checkButtonTapped:
            state = handleAction(state, .addComfieZone)
        case .xButtonTapped:
            state = handleAction(state, .showDeleteComfieZonePopup)
        }
    }
    
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .showRequestLocationPermissionPopup:
            print("위치 설정 팝업 띄워")
        case .activeComfiezoneSettingTextField:
            print("텍스트 필드 띄워")
        case .addComfieZone:
            print("컴피존 추가하자")
        case .showDeleteComfieZonePopup:
            print("컴피존 삭제 팝업")
        }
        return newState
    }
}
