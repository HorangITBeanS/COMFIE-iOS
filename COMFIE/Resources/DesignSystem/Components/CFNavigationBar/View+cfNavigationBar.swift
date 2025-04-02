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
    let backButtonAction: () -> Void
    let leadingButtons: [CFNavigationBarButton]
    let trailingButtons: [CFNavigationBarButton]
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            CFNavigationBar(
                title: title,
                isBackButtonHidden: isBackButtonHidden,
                backButtonAction: backButtonAction,
                leadingButtons: leadingButtons,
                trailingButtons: trailingButtons
            )
            
            content
            
            Spacer(minLength: 0)
        }
        .navigationBarBackButtonHidden()
    }
}

extension View {
    func cfNavigationBar(
        _ title: String,
        isBackButtonHidden: Bool = false,
        backButtonAction: @escaping () -> Void = {},
        leadingButtons: [CFNavigationBarButton] = [],
        trailingButtons: [CFNavigationBarButton] = []
    ) -> some View {
        modifier(
            CFNavigationBarModifier(
                title: title,
                isBackButtonHidden: isBackButtonHidden,
                backButtonAction: backButtonAction,
                leadingButtons: leadingButtons,
                trailingButtons: trailingButtons
            )
        )
    }
}
