//
//  DIContainer.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

struct DIContainer {
    let router: Router
    // TODO: MemoRepository를 어디서 주입할 지 고민하기
    let memoRepository: MemoRepositoryProtocol = MemoRepository()
    
    // MARK: - Intent
    private func makeOnboardingIntent() -> OnboardingStore { OnboardingStore(router: router) }
    private func makeMemoIntent() -> MemoStore {
        MemoStore(router: router, memoRepository: memoRepository)
    }
    private func makeRetrospectionIntent() -> RetrospectionStore { RetrospectionStore(router: router) }
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
        case .retrospection:
            RetrospectionView(intent: makeRetrospectionIntent())
        case .comfieZoneSetting:
            Text("comfieZoneSetting")
        case .more:
            MoreView(intent: makeMoreIntent())
            
        // MARK: - 메인 화면 > 더보기(more)
        case .serviceTerm:
            Text("serviceTerm")
        case .privacyPolicy:
            Text("privacyPolicy")
        case .locationTerm:
            Text("locationTerm")
        case .sendFeedback:
            Text("sendFeedback")
        case .makers:
            Text("makers")
        }
    }
}
