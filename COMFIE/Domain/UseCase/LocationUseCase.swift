//
//  LocationUseCase.swift
//  COMFIE
//
//  Created by Anjin on 4/29/25.
//

import Foundation

class LocationUseCase {
    private let locationService: LocationService
    
    init(locationService: LocationService) {
        self.locationService = locationService
    }
    
    func requestLocationAuthorization() {
        locationService.requestAurhorization()
    }
}
