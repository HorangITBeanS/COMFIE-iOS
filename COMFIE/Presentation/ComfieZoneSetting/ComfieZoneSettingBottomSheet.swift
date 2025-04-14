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
            
            Group {
                switch state.bottomSheetState {
                case .plusButton:
                    PlusButton(
                        onTap: { intent(.plusButtonTapped) }
                    )
                case .comfiezoneSettingTextField:
                    Text("텍스트필드")
                case .inComfieZone:
                    Text("보라색 컴피존")
                case .outComfieZone:
                    Text("회색 컴피존")
                }
            }
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

private struct PlusButton: View {
    var onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
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
        }
    }
}

#Preview {
    ComfieZoneSettingView(
        intent: ComfieZoneSettingStore()
    )
}
