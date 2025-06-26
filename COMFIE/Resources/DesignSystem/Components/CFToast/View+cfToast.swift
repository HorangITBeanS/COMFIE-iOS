//
//  View+cfToast.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 6/26/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func cfToast(
        showToast: Binding<Bool>,
        backgroundColor: Color,
        textColor: Color,
        content: String
    ) -> some View {
        ZStack {
            self
            
            if showToast.wrappedValue {
                CFToast(
                    backgroundColor: backgroundColor,
                    textColor: textColor,
                    content: content
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showToast.wrappedValue = false
                        }
                    }
                }
            }
        }
    }
}
