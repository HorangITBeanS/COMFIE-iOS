//
//  ComfieZoneNameCell.swift
//  COMFIE
//
//  Created by Anjin on 4/14/25.
//

import SwiftUI

struct ComfieZoneNameCell: View {
    var name: String
    var isInComfieZone: Bool
    var onXButtonTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                // 컴피존 이름
                Text(name)
                    .comfieFont(.body)
                    .foregroundStyle(Color.textWhite)
                
                Spacer(minLength: 0)
            }
            
            // Divider 막대
            Rectangle()
                .frame(width: 1, height: 32)
                .foregroundStyle(Color.cfWhite)
                .padding(.leading, 8)
                .padding(.trailing, 12)
            
            // X 버튼 - 컴피존 설정
            Button {
                onXButtonTapped()
            } label: {
                Image(.icX)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.textWhite)
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .background(isInComfieZone ? Color.keyPrimary : Color.keyDeactivated)
    }
}
