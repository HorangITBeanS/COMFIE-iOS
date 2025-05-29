//
//  LocationService.swift
//  COMFIE
//
//  Created by Anjin on 4/29/25.
//

import CoreLocation

class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
        
    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

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
}
