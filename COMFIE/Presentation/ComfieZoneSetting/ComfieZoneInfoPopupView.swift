//
//  ComfieZoneInfoPopupView.swift
//  COMFIE
//
//  Created by Anjin on 4/5/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func comfieZoneInfoPopupView(
        showPopup: Bool,
        onDismiss: @escaping () -> Void
    ) -> some View {
        ZStack {
            self
            
            if showPopup {
                Color.popupBackdrop.ignoresSafeArea()
                    .onTapGesture { onDismiss() }
                
                ComfieZoneInfoPopupView()
                    .padding(.horizontal, 50)
            }
        }
    }
}

struct ComfieZoneInfoPopupView: View {
    private let strings = StringLiterals.ComfieZoneSetting.InfoPopup.self
    
    var body: some View {
        VStack(spacing: 20) {
            // 타이틀 - 컴피존이란?
            Text(strings.title)
            
            // FIXME: 추후 이미지 디자인 완료 후 변경 필요
            Circle()
                .frame(width: 120, height: 120)
                .foregroundStyle(Color.textGray)
            
            VStack(spacing: 8) {
                // 컴피존 설명
                Text(strings.description)
                    .comfieFont(.systemSubtitle)
                    .foregroundStyle(Color.textBlack)
                
                // 삭제 시, 사용자 확인 요청 안내
                Text(strings.caption)
                    .comfieFont(.systemBody)
                    .foregroundStyle(Color.textDarkgray)
            }
            .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(Color.cfWhite)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 0)
    }
}
