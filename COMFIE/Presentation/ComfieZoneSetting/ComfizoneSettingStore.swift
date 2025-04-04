//
//  ComfizoneSettingStore.swift
//  COMFIE
//
//  Created by Anjin on 4/4/25.
//

import Foundation
import MapKit

@Observable
class ComfizoneSettingStore: IntentStore {
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
    }
    
    enum Intent {
        case infoButtonTapped  // 안내 버튼 클릭
    }
    
    enum Action { }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .infoButtonTapped:
            print("정보버튼 클릭")
        }
    }
}
