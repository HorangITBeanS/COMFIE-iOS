//
//  DIContainer.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

class DIContainer {
    let router: Router
    
    init(router: Router) {
        self.router = router
    }
    
    // MARK: - Repository
    let memoRepository: MemoRepositoryProtocol = MemoRepository()
    let retrospectionRepository: RetrospectionRepositoryProtocol = RetrospectionRepository()
    let comfieZoneRepository: ComfieZoneRepositoryProtocol = ComfieZoneRepository()
    
    // MARK: - Service
    lazy var makeLocationService: LocationService = { LocationService() }()
    
    // MARK: - UseCase
    private func makeLocationUseCase() -> LocationUseCase {
        LocationUseCase(
            locationService: makeLocationService,
            comfiZoneRepository: comfieZoneRepository
        )
    }
    
    // MARK: - Intent
    private func makeOnboardingIntent() -> OnboardingStore {
        OnboardingStore(
            router: router,
            locationUseCase: makeLocationUseCase()
        )
    }
    
    private func makeMemoIntent() -> MemoStore {
        MemoStore(
            router: router,
            memoRepository: memoRepository,
            locationUseCase: makeLocationUseCase()
        )
    }
    
    private func makeComfieZoneSettingPopupIntent() -> ComfieZoneSettingPopupStore { ComfieZoneSettingPopupStore() }
    private func makeComfieZoneSettingIntent() -> ComfieZoneSettingStore {
        ComfieZoneSettingStore(
            popupIntent: makeComfieZoneSettingPopupIntent(),
            locationUseCase: makeLocationUseCase(),
            comfieZoneRepository: comfieZoneRepository
        )
    }
    
    private func makeRetrospectionIntent(memo: Memo) -> RetrospectionStore {
        RetrospectionStore(router: router, repository: retrospectionRepository, memo: memo)
    }
    private func makeMoreIntent() -> MoreStore { MoreStore(router: router) }
    
    // MARK: - View
    @ViewBuilder func makeView(_ route: Route) -> some View {
        switch route {
        // MARK: - 메인 화면
        case .loading:
            LoadingView()
        case .onboarding:
            OnboardingView(intent: makeOnboardingIntent())
        case .memo:
            MemoView(intent: makeMemoIntent())
        case .retrospection(let memo):
            RetrospectionView(intent: makeRetrospectionIntent(memo: memo))
        case .comfieZoneSetting:
            ComfieZoneSettingView(intent: makeComfieZoneSettingIntent())
        case .more:
            MoreView(intent: makeMoreIntent())
            
        // MARK: - 메인 화면 > 더보기(more)
        case .serviceTerm:
            TermView(type: .service)
        case .privacyPolicy:
            TermView(type: .privacy)
        case .makers:
            MakersView()
        }
    }
}
