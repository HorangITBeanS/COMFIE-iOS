//
//  Route.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

// Navigation으로 이동하는 경로
enum Route {
    // MARK: - 메인 화면
    case loading
    case onboarding
    case memo
    case retrospection
    case comfieZoneSetting
    case more
    
    // MARK: - 메인 화면 > 더보기(more)
    case serviceTerm
    case privacyPolicy
    case locationTerm
    case sendFeedback
    case makers
    
    @ViewBuilder func view(_ router: Router) -> some View {
        DIContainer(router: router).makeView(self)
    }
}
