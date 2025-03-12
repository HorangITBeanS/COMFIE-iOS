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
            .padding(.horizontal, 50)
        }
    }
}

private struct CFPopup: View {
    let type: CFPopupType
    let leftButtonAction: (() -> Void)
    let rightButtonAction: (() -> Void)
    
    var body: some View {
        VStack(spacing: 0) {
            CFPopupContentView(type: type,
                               leftButtonAction: leftButtonAction,
                               rightButtonAction: rightButtonAction)
            .padding(.vertical, 16)
            .padding(.horizontal, 27)
        }
        .background(Color.cfWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.12), radius: 24)
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
            
            Text(type.subTitle)
                .comfieFont(.systemBody)
                .foregroundStyle(.popupGray)
                .padding(.bottom, 16)
            
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
        }
    }
}

private struct CFPopupButton: View {
    let type: CFPopupType.ButtonType
    let description: LocalizedStringResource
    
    var body: some View {
        HStack {
            Spacer()
            Text(description)
                .comfieFont(.systemBody)
                .foregroundStyle(type.textColor)
            Spacer()
        }
        .padding(.vertical, 10)
        .background(type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CFPopupView(type: .deleteComfieZone,
                leftButtonAction: { print("left Click") },
                rightButtonAction: { print("right Click") })
}
