//
//  COMFIEApp.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import SwiftUI

@main
struct COMFIEApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView(
                intent: OnboardingStore()
            )
        }
    }
}
