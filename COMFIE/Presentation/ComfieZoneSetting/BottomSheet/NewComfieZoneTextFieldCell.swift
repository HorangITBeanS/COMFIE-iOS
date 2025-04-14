//
//  NewComfieZoneTextFieldCell.swift
//  COMFIE
//
//  Created by Anjin on 4/14/25.
//

import SwiftUI

struct NewComfieZoneTextFieldCell: View {
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
    }
}
