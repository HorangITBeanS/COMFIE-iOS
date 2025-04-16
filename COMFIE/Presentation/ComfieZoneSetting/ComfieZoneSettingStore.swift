//
//  ComfieZoneSettingStore.swift
//  COMFIE
//
//  Created by Anjin on 4/4/25.
//

import MapKit
import SwiftUI

enum ComfieZoneSettingBottomSheetState {
    case addComfieZone
    case setComfiezoneTextField
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
        var isLocationAuthorized: Bool = false
//        var isLocationAuthorized: Bool = false
        var newComfiezoneName: String = ""
        
        // 컴피존 가져오기
        var comfieZone: ComfieZone? = {
            ComfieZone(id: UUID(), longitude: 37.3663000, latitude: 127.1083000, name: "여기는 우리집~")
        }()
        var isInComfieZone: Bool = true
        
        /// 위치 권한 요청 팝업
        var showRequestLocationPermissionPopup: Bool = false
        /// 컴피존 삭제 팝업
        var showDeleteComfieZonePopup: Bool = false
    }
    
    enum Intent {
        // Popup
        case infoButtonTapped  // 컴피존 안내 버튼 클릭
        case closeInfoPopup    // 컴피존 안내 팝업 닫기
        case closeRequestLocationPermissionPopup
        case goSettingButtonTapped
        case closeDeleteComfieZonePopup
        
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
        case .closeRequestLocationPermissionPopup:
            state.showRequestLocationPermissionPopup = false
            
        case .goSettingButtonTapped:
            // 설정 앱으로 이동
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }
        case .closeDeleteComfieZonePopup:
            state.showDeleteComfieZonePopup = false
        }
    }
    
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .showRequestLocationPermissionPopup:
            newState.showRequestLocationPermissionPopup = true
        case .activeComfiezoneSettingTextField:
            newState.bottomSheetState = .setComfiezoneTextField
        case .addComfieZone:
            // 현재 위치 가져와서 설정하기
            newState.comfieZone = ComfieZone(
                id: UUID(),
                longitude: 37.3663000,
                latitude: 127.1083000,
                name: state.newComfiezoneName
            )
            
            // bottom sheet cell -> 컴피존 이름
            newState.bottomSheetState = .comfieZoneName
            
            print("컴피존 추가하자")
            
        case .showDeleteComfieZonePopup:
//            // bottom sheet cell -> add button
//            newState.bottomSheetState = .addComfieZone
            
            print("컴피존 삭제 팝업")
            newState.showDeleteComfieZonePopup = true
        }
        return newState
    }
}
