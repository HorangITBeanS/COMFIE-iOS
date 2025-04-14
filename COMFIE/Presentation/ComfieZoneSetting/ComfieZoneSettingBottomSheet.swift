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
                case .plusButton:
                    // + 버튼
                    PlusButton(onTap: { intent(.plusButtonTapped) })
                    
                case .comfiezoneSettingTextField:
                    // 컴피존 설정 텍스트필드
                    ComfieZoneSettingTextField(
                        newComfieZoneName: Binding(
                            get: { state.newComfiezoneName },
                            set: { intent(.updateComfieZoneNameTextField($0)) }
                        ),
                        onCheckButtonTapped: { intent(.checkButtonTapped) }
                    )
                    
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

private struct ComfieZoneSettingTextField: View {
    @Binding var newComfieZoneName: String
    var onCheckButtonTapped: () -> Void
    private let strings = StringLiterals.ComfieZoneSetting.BottomSheet.self
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                // 컴피존 이름 설정 TextField
                TextField(
                    strings.textFieldTitleKey.localized,
                    text: $newComfieZoneName,
                    axis: .vertical
                )
                .comfieFont(.body)
                .foregroundStyle(Color.textWhite)
                
                // PlaceHolder
                if newComfieZoneName.isEmpty {
                    Text(strings.textFieldPlaceholder)
                        .comfieFont(.body)
                        .foregroundStyle(Color.textWhite)
                        .padding(.leading, 2)
                }
            }
            
            // Divider 막대
            Rectangle()
                .frame(width: 1, height: 32)
                .foregroundStyle(Color.cfWhite)
                .padding(.leading, 8)
                .padding(.trailing, 12)
            
            // 체크 버튼 - 컴피존 설정
            Button {
                onCheckButtonTapped()
            } label: {
                Image(.icCheck)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.textWhite)
            }
            .disabled(newComfieZoneName.isEmpty)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .background(newComfieZoneName.isEmpty ? Color.keySecondary : Color.keyPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
