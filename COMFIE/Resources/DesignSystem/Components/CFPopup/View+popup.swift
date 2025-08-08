//
//  View+popup.swift
//  COMFIE
//
//  Created by Anjin on 4/16/25.
//

import SwiftUI

/* 활용 예시
 
 .popup(
     showPopup: true,
     type: .requestLocationPermission,
     leftButtonType: .cancel,
     leftButtonAction: { },
     rightButtonType: .normal,
     rightButtonAction: { }
 )
 
 */

extension View {
    @ViewBuilder
    func popup(
        showPopup: Bool,
        type: CFPopupType,
        leftButtonType: CFPopupType.ButtonType = .destructive,
        leftButtonAction: @escaping () -> Void,
        rightButtonType: CFPopupType.ButtonType = .cancel,
        rightButtonAction: @escaping () -> Void
    ) -> some View {
        ZStack {
            self
            
            if showPopup {
                CFPopupView(
                    type: type,
                    leftButtonType: leftButtonType,
                    leftButtonAction: leftButtonAction,
                    rightButtonType: rightButtonType,
                    rightButtonAction: rightButtonAction
                )
            }
        }
    }
}
