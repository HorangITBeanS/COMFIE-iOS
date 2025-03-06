//
//  Route.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

// Navigation으로 이동하는 경로
enum Route {
    case loading
    case onboarding
    case memo
    case retrospection
    case settingComfieZone
    
    @ViewBuilder func view() -> some View {
        ViewFactory().makeView(self)
    }
}

struct ViewFactory {
    // MARK: - Intent
    private func makeOnboardingIntent() -> OnboardingStore { OnboardingStore() }
    
    // MARK: - View
    @ViewBuilder func makeView(_ route: Route) -> some View {
        switch route {
        case .loading:
            LoadingView()
        case .onboarding:
            OnboardingView(intent: makeOnboardingIntent())
        case .memo:
            Text("Memo")
        case .retrospection:
            Text("Memo")
        case .settingComfieZone:
            Text("Memo")
        }
    }
}
