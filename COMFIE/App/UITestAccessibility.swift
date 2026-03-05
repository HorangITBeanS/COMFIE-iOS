//
//  UITestAccessibility.swift
//  COMFIE
//
//  Created by zaehorang on 2/14/26.
//

import SwiftUI
import UIKit

enum UITestAccessibility {
    static var isEnabled: Bool {
        UITestBootstrap.isUITesting()
    }
}

extension View {
    @ViewBuilder
    func uiTestAccessibilityIdentifier(_ identifier: String) -> some View {
        #if DEBUG
        // 일반 실행에서는 숨기고, UITest 세션에서만 식별자를 노출한다.
        if UITestAccessibility.isEnabled {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

extension UIView {
    func applyUITestAccessibilityIdentifier(_ identifier: String) {
        #if DEBUG
        guard UITestAccessibility.isEnabled else { return }
        accessibilityIdentifier = identifier
        #endif
    }
}
