//
//  ComfieZoneSettingStore.swift
//  COMFIE
//
//  Created by Anjin on 4/4/25.
//

import MapKit
import SwiftUI

@Observable
class ComfieZoneSettingStore: IntentStore {
    private(set) var state: State = .init()
    struct State {
        var initialPosition = MKCoordinateRegion(
            center: CLLocationCoordinate2D(  // 정자역
                latitude: 37.3663000,
                longitude: 127.1083000
            ),
            latitudinalMeters: 200,  // 지도 반경
            longitudinalMeters: 200
        )
        
        var showInfoPopup: Bool = false
    }
    
    enum Intent {
        case infoButtonTapped  // 안내 버튼 클릭
        case closeInfoPopup  // 안내 팝업 닫기
    }
    
    enum Action { }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .infoButtonTapped:
            state.showInfoPopup = true
        case .closeInfoPopup:
            withAnimation {
                state.showInfoPopup = false
            }
        }
    }
}
