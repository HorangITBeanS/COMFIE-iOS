//
//  View+cfNavigationBar.swift
//  COMFIE
//
//  Created by Anjin on 3/27/25.
//

import SwiftUI

struct CFNavigationBarModifier: ViewModifier {
    let title: String
    let isBackButtonHidden: Bool
    let trailingButton: CFNavigationBarButton?
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            CFNavigationBar(
                title: title,
                isBackButtonHidden: isBackButtonHidden,
                trailingButton: trailingButton
            )
            
            content
        }
        .navigationBarBackButtonHidden()
    }
}

extension View {
    func cfNavigationBar(
        _ title: String,
        isBackButtonHidden: Bool = false,
        trailingButton: CFNavigationBarButton? = nil
    ) -> some View {
        modifier(
            CFNavigationBarModifier(
                title: title,
                isBackButtonHidden: isBackButtonHidden,
                trailingButton: trailingButton
            )
        )
    }
}

#Preview {
    VStack {
        Text("hello")
        Spacer()
        HStack { Spacer() }
    }
    .background(Color.red.opacity(0.4))
    .cfNavigationBar(
        "title",
        isBackButtonHidden: true,
        trailingButton: CFNavigationBarButton(
            image: Image(.icInfo),
            action: {}
        )
    )
}
