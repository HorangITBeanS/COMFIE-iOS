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
                
                ComfieZoneInfoPopupView(dismissPopup: onDismiss)
                    .padding(.horizontal, 50)
            }
        }
    }
}

struct ComfieZoneInfoPopupView: View {
    private let strings = StringLiterals.ComfieZoneSetting.InfoPopup.self
    let dismissPopup: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 20) {
                // 타이틀 - 컴피존이란?
                Text(strings.title)
                    .comfieFont(.title)
                    .foregroundStyle(Color.textBlack)
                
                Image(.icComfieZoneInfo)
                    .resizable()
                    .frame(width: 132, height: 132)
                
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
            
            // X 버튼 - 팝업 dismiss
            Button {
                dismissPopup()
            } label: {
                Image(.icX)
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .padding(.top, 2)
        }
        .padding(20)
        .background(Color.cfWhite)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 0)
    }
}
