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
    private var popupState: ComfieZoneSettingPopupStore.State { intent.popupIntent.state }
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
        .comfieZoneInfoPopupView(  // 컴피존 안내 팝업
            showPopup: popupState.showInfoPopup,
            onDismiss: { intent.popupIntent(.closeInfoPopup) }
        )
        .popup(  // 위치 권한 요청 팝업
            showPopup: popupState.showRequestLocationPermissionPopup,
            type: .requestLocatioinPermission,
            leftButtonType: .cancel,
            leftButtonAction: { intent.popupIntent(.closeRequestLocationPermissionPopup) },
            rightButtonType: .normal,
            rightButtonAction: { intent.popupIntent(.goSettingButtonTapped) }
        )
        .popup(  // 컴피존 삭제 팝업
            showPopup: popupState.showDeleteComfieZonePopup,
            type: .deleteComfieZone,
            leftButtonAction: { intent(.deleteComfieZonePopupButtonTapped) },
            rightButtonAction: { intent.popupIntent(.closeDeleteComfieZonePopup) }
        )
        .toolbar(.hidden, for: .navigationBar)  // 기본 네비게이션바 삭제
    }
    
    // 네비게이션 바 우측 정보 버튼
    private var infoButton: CFNavigationBarButton {
        CFNavigationBarButton {
            intent.popupIntent(.infoButtonTapped)
        } label: {
            Image(.icInfo)
                .resizable()
                .frame(width: 24, height: 24)
        }
    }
}

#Preview {
    ComfieZoneSettingView(
        intent: ComfieZoneSettingStore(popupIntent: .init())
    )
}
