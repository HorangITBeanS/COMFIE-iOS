//
//  LocationUseCase.swift
//  COMFIE
//
//  Created by Anjin on 4/29/25.
//

import Combine
import CoreLocation
import Foundation

class LocationUseCase {
    private let locationService: LocationService
    private let comfieZoneRepository: ComfieZoneRepositoryProtocol
    
    var currentLocationPublisher: AnyPublisher<CLLocation, Never> {
        locationService.currentLocationPublisher
    }
    
    init(
        locationService: LocationService,
        comfiZoneRepository: ComfieZoneRepositoryProtocol
    ) {
        self.locationService = locationService
        self.comfieZoneRepository = comfiZoneRepository
    }
    
    func requestLocationAuthorization() {
        locationService.requestAurhorization()
    }
    
    func getUserLocationAuthorizationStatus() -> CLAuthorizationStatus {
        return locationService.authorizationStatus
    }
    
    func getCurrentLocation() -> CLLocation? {
        return locationService.currentLocation
    }
    
    func isInComfieZone() -> Bool {
        let location = self.getCurrentLocation()
        let comfieZone = comfieZoneRepository.fetchComfieZone()
        if let comfieZone, let location {
            let comfieZoneLocation = CLLocation(latitude: comfieZone.latitude, longitude: comfieZone.longitude)
            let userComfieZoneDistance = location.distance(from: comfieZoneLocation)
            let isInComfieZone = userComfieZoneDistance <= 50.0  // 컴피존 반경
            return isInComfieZone
        } else {
            return false
        }
    }
}
