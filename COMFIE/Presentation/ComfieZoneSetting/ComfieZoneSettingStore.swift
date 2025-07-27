//
//  ComfieZoneSettingStore.swift
//  COMFIE
//
//  Created by Anjin on 4/4/25.
//

import Combine
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
    private let locationUseCase: LocationUseCase
    private let comfieZoneRepository: ComfieZoneRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private(set) var currentLocation: CLLocation?
    
    init(
        popupIntent: ComfieZoneSettingPopupStore,
        locationUseCase: LocationUseCase,
        comfieZoneRepository: ComfieZoneRepositoryProtocol
    ) {
        self.popupIntent = popupIntent
        self.locationUseCase = locationUseCase
        self.comfieZoneRepository = comfieZoneRepository
        
        let isLocationAuthorized = self.getLocationAuthStatus()  // 위치 권한 여부
        let comfieZone = comfieZoneRepository.fetchComfieZone()  // 컴피존
        
        if let comfieZone {
            // 컴피존 있음 > 나의 위치로 지도 고정, 위치 권한 사라지면 컴피존 위치로 고정
            self.state = createStateWithComfieZone(comfieZone, isLocationAuthorized: isLocationAuthorized)
        } else {
            // 컴피존 없음 > 초기 위치 설정
            self.state = createInitialStateWithoutComfieZone(isLocationAuthorized: isLocationAuthorized)
        }
        
        // subscribe to currentLocationPublisher
        locationUseCase.currentLocationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.currentLocation = location
            }
            .store(in: &cancellables)
    }
    
    private(set) var state: State = .init()
    struct State {
        // 지도 초기 위치
        var currentLocation: CLLocationCoordinate2D?
        var initialPosition = MKCoordinateRegion(
            center: ComfieZoneConstant.defaultPosition,
            latitudinalMeters: ComfieZoneConstant.mapRadiusInMeters.latitude,
            longitudinalMeters: ComfieZoneConstant.mapRadiusInMeters.longitude
        )
        
        // Bottom Sheet
        var bottomSheetState: ComfieZoneSettingBottomSheetState = .comfieZoneName
        var isLocationAuthorized: Bool = false  // 위치 권한 여부
        var isInComfieZone: Bool = false        // 컴피존 안/밖 여부
        var newComfiezoneName: String = ""      // 새로운 컴피존 이름
        
        // 컴피존
        var comfieZone: ComfieZone?
    }
    
    enum Intent {
        // Popup
        case deleteComfieZonePopupButtonTapped
        
        // Bottom Sheet
        case plusButtonTapped  // 컴피존 추가 버튼 클릭
        case updateComfieZoneNameTextField(String)
        case checkButtonTapped
        case xButtonTapped
        
        // Update State
        case updateAllStatesByNewCurrentLocation
    }
    
    enum Action {
        // Bottom Sheet
        case getLocationAuthStatus
        case activeComfiezoneSettingTextField
        case addComfieZone
        case deleteComfieZone
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .plusButtonTapped:
            state = handleAction(state, .getLocationAuthStatus)
            if state.isLocationAuthorized {
                // 위치 권한 설정 있을 때 - 텍스트필드 활성화
                state = handleAction(state, .activeComfiezoneSettingTextField)
            } else {
                // 위치 권한 설정이 없을 때 - 설정 팝업
                popupIntent(.openRequestLocationPermissionPopup)
            }
        case .updateComfieZoneNameTextField(let text):
            state.newComfiezoneName = text
        case .checkButtonTapped:
            withAnimation {
                state = handleAction(state, .addComfieZone)
            }
        case .xButtonTapped:
            popupIntent(.openDeleteComfieZonePopup)
        case .deleteComfieZonePopupButtonTapped:  // 컴피존 삭제
            if state.isInComfieZone {
                withAnimation {
                    state = handleAction(state, .deleteComfieZone)
                }
            } else {
                // 컴피존 밖에 있을 때 - Face ID 인식 후 삭제
                Task { @MainActor in
                    let service = LocalAuthenticationService()
                    let result = await service.request()
                    switch result {
                    case .success:
                        withAnimation {
                            state = handleAction(state, .deleteComfieZone)
                        }
                    case .failure:
                        popupIntent(.closeDeleteComfieZonePopup)
                    }
                }
            }
        case .updateAllStatesByNewCurrentLocation:
            let isLocationAuthorized = getLocationAuthStatus()
            let comfieZone = comfieZoneRepository.fetchComfieZone()
            
            if let comfieZone {
                state = createStateWithComfieZone(comfieZone, isLocationAuthorized: isLocationAuthorized)
            } else {
                state = createInitialStateWithoutComfieZone(isLocationAuthorized: isLocationAuthorized)
            }
        }
    }
    
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        switch action {
        case .getLocationAuthStatus:
            newState.isLocationAuthorized = getLocationAuthStatus()
        case .activeComfiezoneSettingTextField:
            newState.bottomSheetState = .setComfiezoneTextField
        case .addComfieZone:
            // 현재 위치 가져오기
            let userLocation = locationUseCase.getCurrentLocation()?.coordinate
            
            let comfieZone = ComfieZone(
                id: UUID(),
                longitude: userLocation?.longitude ?? ComfieZoneConstant.defaultPosition.longitude,
                latitude: userLocation?.latitude ?? ComfieZoneConstant.defaultPosition.latitude,
                name: state.newComfiezoneName
            )
            
            // 컴피존 추가하기
            newState.comfieZone = comfieZone
            comfieZoneRepository.saveComfieZone(comfieZone)
            
            // bottom sheet cell -> 컴피존 이름
            newState.isInComfieZone = true
            newState.bottomSheetState = .comfieZoneName
            
        case .deleteComfieZone:
            popupIntent(.closeDeleteComfieZonePopup)
            newState.comfieZone = nil
            newState.isInComfieZone = false
            newState.bottomSheetState = .addComfieZone
            comfieZoneRepository.deleteComfieZone()
        }
        return newState
    }
    
    // 사용자 위치 권한 여부
    private func getLocationAuthStatus() -> Bool {
        let status = locationUseCase.getUserLocationAuthorizationStatus()
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    // 컴피존 없을 때 > 초기값 설정
    private func createInitialStateWithoutComfieZone(isLocationAuthorized: Bool) -> State {
        let defaultPosition = ComfieZoneConstant.defaultPosition
        
        let position: CLLocationCoordinate2D
        if isLocationAuthorized,
           let userLocation = locationUseCase.getCurrentLocation()?.coordinate {
            position = userLocation
        } else {
            position = defaultPosition
        }
        
        return State(
            initialPosition: makeCoordinateRegion(center: position),
            bottomSheetState: .addComfieZone,
            isLocationAuthorized: isLocationAuthorized
        )
    }
    
    // 컴피존 있을 때 > 초기 값 설정
    private func createStateWithComfieZone(
        _ comfieZone: ComfieZone,
        isLocationAuthorized: Bool
    ) -> State {
        var position = CLLocationCoordinate2D(
            latitude: comfieZone.latitude,
            longitude: comfieZone.longitude
        )
        var userLocationCoordinate: CLLocationCoordinate2D?
        var isInComfieZone = false
        
        if isLocationAuthorized,
           let userLocation = locationUseCase.getCurrentLocation() {
            userLocationCoordinate = userLocation.coordinate
            position = userLocation.coordinate
            
            let comfieZoneLocation = CLLocation(latitude: comfieZone.latitude, longitude: comfieZone.longitude)
            let userComfieZoneDistance = userLocation.distance(from: comfieZoneLocation)
            
            isInComfieZone = userComfieZoneDistance <= ComfieZoneConstant.comfieZoneRadius  // 컴피존 반경
        }
        
        return State(
            currentLocation: userLocationCoordinate,
            initialPosition: makeCoordinateRegion(center: position),
            bottomSheetState: .comfieZoneName,
            isLocationAuthorized: isLocationAuthorized,
            isInComfieZone: isInComfieZone,
            comfieZone: comfieZone
        )
    }
    
    // 반경 생성
    private func makeCoordinateRegion(center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: center,
            latitudinalMeters: ComfieZoneConstant.mapRadiusInMeters.latitude,  // 지도 반경
            longitudinalMeters: ComfieZoneConstant.mapRadiusInMeters.longitude
        )
    }
}
