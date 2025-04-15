//
//  ComfieZoneSettingView.swift
//  COMFIE
//
//  Created by Anjin on 3/25/25.
//

import MapKit
import SwiftUI

struct ComfieZoneSettingView: View {
    @State var intent: ComfieZoneSettingStore
    private var state: ComfieZoneSettingStore.State { intent.state }
    private let strings = StringLiterals.ComfieZoneSetting.self
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // 지도 화면
                Map(position: .constant(MapCameraPosition.region(state.initialPosition)))
                    .mapStyle(.standard(elevation: .flat))
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: -12, trailing: 0))
                    .disabled(true)
//                    .opacity(0)
                
                // 컴피존 안내 문구 - 안, 밖, 없음
                Text("컴피존이 없어요!")
                    .comfieFont(.body)
                    .foregroundStyle(Color.textBlack)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.keyTransparent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 16)
            }
            
            // 컴피존 설정 시트
            ComfieZoneSettingBottomSheet(intent: $intent)
        }
        .background(Color.cfWhite)
        .cfNavigationBar(strings.navigationTitle.localized, trailingButtons: [infoButton])
        // 컴피존 안내 팝업
        .comfieZoneInfoPopupView(
            showPopup: state.showInfoPopup,
            onDismiss: { intent(.closeInfoPopup) }
        )
        // 위치 권한 요청 팝업
        .popup(
            showPopup: state.showRequestLocationPermissionPopup,
            type: .requestLocatioinPermission,
            leftButtonType: .cancel,
            leftButtonAction: { intent(.closeRequestLocationPermissionPopup) },
            rightButtonType: .normal,
            rightButtonAction: { intent(.goSettingButtonTapped) }
        )
        // 기본 네비게이션바 삭제
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // 네비게이션 바 우측 정보 버튼
    private var infoButton: CFNavigationBarButton {
        CFNavigationBarButton {
            intent(.infoButtonTapped)
        } label: {
            Image(.icInfo)
                .resizable()
                .frame(width: 24, height: 24)
        }
    }
}

#Preview {
    ComfieZoneSettingView(
        intent: ComfieZoneSettingStore()
    )
}
