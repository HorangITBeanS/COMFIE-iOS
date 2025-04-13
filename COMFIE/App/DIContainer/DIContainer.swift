//
//  DIContainer.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

struct DIContainer {
    let router: Router
    
    // MARK: - Repository
    let memoRepository: MemoRepositoryProtocol = MemoRepository()
    
    // MARK: - Intent
    private func makeOnboardingIntent() -> OnboardingStore { OnboardingStore(router: router) }
    private func makeMemoIntent() -> MemoStore {
        MemoStore(
            router: router,
            memoRepository: memoRepository
        )
    }
    private func makeComfieZoneSettingIntent() -> ComfieZoneSettingStore { ComfieZoneSettingStore() }
    private func makeRetrospectionIntent() -> RetrospectionStore { RetrospectionStore(router: router) }
    
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
            RetrospectionView(intent: makeRetrospectionIntent())
        case .comfieZoneSetting:
            ComfieZoneSettingView(intent: makeComfieZoneSettingIntent())
        }
    }
}
