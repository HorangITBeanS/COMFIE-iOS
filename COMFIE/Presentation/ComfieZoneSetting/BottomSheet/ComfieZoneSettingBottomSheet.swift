//
//  ComfieZoneSettingBottomSheet.swift
//  COMFIE
//
//  Created by Anjin on 4/14/25.
//

import SwiftUI

struct ComfieZoneSettingBottomSheet: View {
    @Binding var intent: ComfieZoneSettingStore
    private var state: ComfieZoneSettingStore.State { intent.state }
    private let strings = StringLiterals.ComfieZoneSetting.BottomSheet.self
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title - 컴피존
            Text(strings.title)
                .comfieFont(.title)
                .foregroundStyle(Color.textBlack)
                .padding(.top, 24)
                .padding(.leading, 28)
            
            VStack(spacing: 0) {
                switch state.bottomSheetState {
                case .addComfieZone:
                    // + 버튼
                    AddComfieZoneCell(onTap: { intent(.plusButtonTapped) })
                    
                case .setComfiezoneTextField:
                    // 컴피존 설정 텍스트필드
                    NewComfieZoneTextFieldCell(
                        newComfieZoneName: Binding(
                            get: { state.newComfiezoneName },
                            set: { intent(.updateComfieZoneNameTextField($0)) }
                        ),
                        onCheckButtonTapped: { intent(.checkButtonTapped) }
                    )
                    
                case .comfieZoneName:
                    // 컴피존 이름 Cell
                    ComfieZoneNameCell(
                        name: state.comfieZone?.name ?? "",
                        isInComfieZone: state.isInComfieZone,
                        onXButtonTapped: { intent(.xButtonTapped) }
                    )
                }
            }
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
}

#Preview {
    ComfieZoneSettingView(
        intent: ComfieZoneSettingStore(
            popupIntent: ComfieZoneSettingPopupStore()
        )
    )
}
