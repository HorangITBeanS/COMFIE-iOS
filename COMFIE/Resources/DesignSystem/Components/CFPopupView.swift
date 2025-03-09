//
//  CFPopupView.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/9/25.
//

import SwiftUI

struct CFPopupView: View {
    let type: CFPopupType
    let leftButtonAction: (() -> Void)
    let rightButtonAction: (() -> Void)
    
    var body: some View {
        ZStack {
            Color.popupBackdrop.ignoresSafeArea()
            CFPopup(type: type,
                    leftButtonAction: leftButtonAction,
                    rightButtonAction: rightButtonAction)
        }
    }
}

private struct CFPopup: View {
    let type: CFPopupType
    let leftButtonAction: (() -> Void)
    let rightButtonAction: (() -> Void)
    
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 302, height: 123)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.12), radius: 24)
            .overlay(alignment: .top) {
                CFPopupContentView(type: type,
                                   leftButtonAction: leftButtonAction,
                                   rightButtonAction: rightButtonAction)
            }
    }
}

private struct CFPopupContentView: View {
    let type: CFPopupType
    let leftButtonAction: (() -> Void)
    let rightButtonAction: (() -> Void)
    
    var body: some View {
        VStack(spacing: 0) {
            Text(type.title)
                .comfieFont(.systemSubtitle)
                .foregroundStyle(.popupBlack)
                .padding(.bottom, 4)
                .padding(.top, 16)
            
            Text(type.subTitle)
                .comfieFont(.systemBody)
                .foregroundStyle(.popupGray)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    leftButtonAction()
                } label: {
                    CFPopupButton(type: .destructive,
                                  description: type.leftButtonDescription)
                }
                
                Button {
                    rightButtonAction()
                } label: {
                    CFPopupButton(type: .cancel,
                                  description: type.rightButtonDescription)
                }
            }
            .padding(.bottom, 16)
        }
    }
}

private struct CFPopupButton: View {
    let type: CFPopupType.ButtonType
    let description: String
    
    var body: some View {
        Rectangle()
            .fill(type.backgroundColor)
            .frame(width: 120, height: 36)
            .cornerRadius(8)
            .overlay {
                Text(description)
                    .comfieFont(.systemBody)
                    .foregroundStyle(type.textColor)
            }
    }
}

#Preview {
    CFPopupView(type: .deleteComfieZone,
                leftButtonAction: { print("left Click") },
                rightButtonAction: { print("right Click") })
}
