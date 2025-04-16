//
//  ComfieZoneSettingPopupStore.swift
//  COMFIE
//
//  Created by Anjin on 4/17/25.
//

import UIKit

@Observable
class ComfieZoneSettingPopupStore: IntentStore {
    private(set) var state: State = .init()
    struct State {
        // 컴피존 안내 팝업
        var showInfoPopup: Bool = false
        
        // 위치 권한 요청 팝업
        var showRequestLocationPermissionPopup: Bool = false
        
        // 컴피존 삭제 팝업
        var showDeleteComfieZonePopup: Bool = false
    }
    
    enum Intent {
        // 컴피존 안내 팝업
        case infoButtonTapped  // 열기
        case closeInfoPopup    // 닫기
        
        // 위치 권한 요청 팝업
        case openRequestLocationPermissionPopup
        case closeRequestLocationPermissionPopup
        case goSettingButtonTapped  // 설정하러 가기
        
        // 컴피존 삭제 팝업
        case openDeleteComfieZonePopup
        case closeDeleteComfieZonePopup
    }
    
    enum Action { }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        // 컴피존 안내 팝업
        case .infoButtonTapped:
            state.showInfoPopup = true
        case .closeInfoPopup:
            state.showInfoPopup = false
        
        // 위치 권한 요청 팝업
        case .openRequestLocationPermissionPopup:
            state.showRequestLocationPermissionPopup = true
        case .closeRequestLocationPermissionPopup:
            state.showRequestLocationPermissionPopup = false
        case .goSettingButtonTapped:
            showSettingApp()  // 설정 앱으로 이동
            state.showRequestLocationPermissionPopup = false
            
        // 컴피존 삭제 팝업
        case .openDeleteComfieZonePopup:
            state.showDeleteComfieZonePopup = true
        case .closeDeleteComfieZonePopup:
            state.showDeleteComfieZonePopup = false
            
        }
    }
    
    // 설정 앱으로 이동
    private func showSettingApp() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }
    }
}
