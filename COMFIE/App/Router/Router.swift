//
//  Router.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

@Observable
class Router {
    // 네비게이션 경로
    var path: [Route] = .init()
    
    // 앱 최초 실행 시, 2초간 로딩 화면 종료 여부
    var isLoadingViewFinished: Bool = false  // 앱 최초 실행 시, 2초간 로딩 화면 종료 여부
    var isOnboardingFinished: Bool = false   // FIXME: 기본 저장 정보 활용으로 변경!! 온보딩 화면 전환
    
    // 가장 상위 View - 앱 진입 시 파악
    @ViewBuilder func rootView(_ router: Router) -> some View {
        if isLoadingViewFinished == false {
            // 앱 진입 시, 로딩 View
            Route.loading.view(router)
        } else {
            if isOnboardingFinished == false {
                // 앱 최초 실행 O -> 온보딩 View
                 Route.onboarding.view(router)
            } else {
                // 앱 최초 실행 X -> 메모 View
                Route.memo.view(router)
            }
        }
    }
}
