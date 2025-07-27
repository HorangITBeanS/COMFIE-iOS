//
//  ComfieZoneConstant.swift
//  COMFIE
//
//  Created by Anjin on 7/1/25.
//

import Foundation
import MapKit

struct ComfieZoneConstant {
    static let mapRadiusInMeters: (latitude: CLLocationDistance, longitude: CLLocationDistance) = (200, 200) // 지도 반경
    static let comfieZoneRadius: CLLocationDistance = 10.0  // 컴피존 반경
    static let defaultPosition = CLLocationCoordinate2D(  // 정자역
        latitude: 37.3663000,
        longitude: 127.1083000
    )
}
