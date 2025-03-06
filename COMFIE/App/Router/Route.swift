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
    case comfieZoneSetting
    
    @ViewBuilder func view(_ router: Router) -> some View {
        ViewFactory(router: router).makeView(self)
    }
}

struct ViewFactory {
    let router: Router
    
    // MARK: - Intent
    private func makeOnboardingIntent() -> OnboardingStore { OnboardingStore(router: router) }
    private func makeMemoIntent() -> MemoStore { MemoStore(router: router) }
    
    // MARK: - View
    @ViewBuilder func makeView(_ route: Route) -> some View {
        switch route {
        case .loading:
            LoadingView()
        case .onboarding:
            OnboardingView(intent: makeOnboardingIntent())
        case .memo:
            MemoView(intent: makeMemoIntent())
        case .retrospection:
            Text("retrospection")
        case .comfieZoneSetting:
            Text("comfieZoneSetting")
        }
    }
}
