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
    private(set) var popupIntent: ComfieZoneSettingPopupStore
    
    init(popupStore: ComfieZoneSettingPopupStore = ComfieZoneSettingPopupStore()) {
        self.popupIntent = popupStore
    }
    
    private(set) var state: State = .init()
    struct State {
        // 지도 초기 위치
        var initialPosition = MKCoordinateRegion(
            center: CLLocationCoordinate2D(  // 정자역
                latitude: 37.3663000,
                longitude: 127.1083000
            ),
            latitudinalMeters: 200,  // 지도 반경
            longitudinalMeters: 200
        )
        
        // Bottom Sheet
        var bottomSheetState: ComfieZoneSettingBottomSheetState = .comfieZoneName
        var isLocationAuthorized: Bool = false  // 위치 권한 여부
        var isInComfieZone: Bool = false        // 컴피존 안/밖 여부
        var newComfiezoneName: String = ""      // 새로운 컴피존 이름
        
        // 컴피존
        var comfieZone: ComfieZone? = {
            ComfieZone(
                id: UUID(),
                longitude: 37.3663000,
                latitude: 127.1083000,
                name: "여기는 우리집~"
            )
        }()
    }
    
    enum Intent {
        // Popup
        case deleteComfieZonePopupButtonTapped
        
        // Bottom Sheet
        case plusButtonTapped  // 컴피존 추가 버튼 클릭
        case updateComfieZoneNameTextField(String)
        case checkButtonTapped
        case xButtonTapped
    }
    
    enum Action {
        // Bottom Sheet
        case activeComfiezoneSettingTextField
        case addComfieZone
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .plusButtonTapped:
            if state.isLocationAuthorized {
                // 권한 설정 있을 때 - 텍스트필드 활성화
                state = handleAction(state, .activeComfiezoneSettingTextField)
            } else {
                // 권한 설정이 없을 때 - 설정 팝업
                popupIntent(.openRequestLocationPermissionPopup)
            }
        case .updateComfieZoneNameTextField(let text):
            state.newComfiezoneName = text
        case .checkButtonTapped:
            state = handleAction(state, .addComfieZone)
        case .xButtonTapped:
            popupIntent(.openDeleteComfieZonePopup)
        case .deleteComfieZonePopupButtonTapped:
            // TODO: 컴피존 삭제
            if state.isInComfieZone {
                // 컴피존 안에 있을 때 - 삭제
                popupIntent(.closeDeleteComfieZonePopup)
                state.bottomSheetState = .addComfieZone
            } else {
                // 컴피존 밖에 있을 때 - Face ID 인식 후 삭제
                Task { @MainActor in
                    let service = LocalAuthenticationService()
                    let result = await service.request()
                    switch result {
                    case .success:
                        popupIntent(.closeDeleteComfieZonePopup)
                        state.bottomSheetState = .addComfieZone
                        // 컴피존 삭제
                    case .failure:
                        popupIntent(.closeDeleteComfieZonePopup)
                    }
                }
            }
        }
    }
    
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .activeComfiezoneSettingTextField:
            newState.bottomSheetState = .setComfiezoneTextField
        case .addComfieZone:
            // TODO: 컴피존 추가
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
        }
        return newState
    }
}
