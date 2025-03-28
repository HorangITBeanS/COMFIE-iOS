//
//  ViewFactory.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

struct ViewFactory {
    let router: Router
    // TODO: MemoRepository를 어디서 주입할 지 고민하기
    let memoRepository = MemoRepository()
    
    // MARK: - Intent
    private func makeOnboardingIntent() -> OnboardingStore { OnboardingStore(router: router) }
    private func makeMemoIntent() -> MemoStore { MemoStore(router: router, memoRepository: memoRepository) }
    
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
