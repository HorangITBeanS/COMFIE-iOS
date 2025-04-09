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
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // 지도 화면
                Map(position: .constant(MapCameraPosition.region(state.initialPosition)))
                    .mapStyle(.standard(elevation: .flat))
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: -12, trailing: 0))
                    .disabled(true)
                
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
            VStack(alignment: .leading, spacing: 16) {
                Text("컴피존")
                    .comfieFont(.title)
                    .foregroundStyle(Color.textBlack)
                    .padding(.top, 24)
                    .padding(.leading, 28)
                
                HStack {
                    Spacer()
                    
                    Image(.icPlus)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.white)
                    
                    Spacer()
                }
                .frame(height: 50)
                .background(Color.keySecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .background(Color.cfWhite)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    topTrailingRadius: 12
                )
            )
        }
        .background(Color.cfWhite)
        .cfNavigationBar("현재위치", trailingButtons: [infoButton])
        // 컴피존 안내 팝업
        .comfieZoneInfoPopupView(
            showPopup: state.showInfoPopup,
            onDismiss: { intent(.closeInfoPopup) }
        )
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
