//
//  LocationService.swift
//  COMFIE
//
//  Created by Anjin on 4/29/25.
//

import Combine
import CoreLocation
import MapKit
import SwiftUI

@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let currentLocationSubject = PassthroughSubject<CLLocation, Never>()
    var currentLocationPublisher: AnyPublisher<CLLocation, Never> {
        currentLocationSubject.eraseToAnyPublisher()
    }
    
    private(set) var currentLocation: CLLocation? {
        didSet {
            if let location = currentLocation {
                currentLocationSubject.send(location)
            }
        }
    }
    
    override init() {
        super.init()
        manager.delegate = self
        // 정확한 위치 요청
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 현재 사용자의 위치 권한 정보
        authorizationStatus = manager.authorizationStatus
        
        // 실시간 위치 요청 시작
        let isAuthorized = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        if isAuthorized {
            manager.startUpdatingLocation()
            currentLocation = manager.location
        }
    }
    
    // 위치 권한 요청
    func requestAurhorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    // 위치 권한 변경 시 요청되는 메서드
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }
    
    // 위치 변경 시 요청되는 메서드
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocation = location
    }
    
    // 위치 추적 실패 시 요청되는 메서드
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 추적 실패: \(error.localizedDescription)")
    }
    
    func currentRegion() -> MKCoordinateRegion? {
        guard let location = currentLocation else { return nil }
        return MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: ComfieZoneConstant.mapRadiusInMeters.latitude,
            longitudinalMeters: ComfieZoneConstant.mapRadiusInMeters.longitude
        )
    }
}
