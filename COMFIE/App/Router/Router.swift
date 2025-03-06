//
//  Router.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import Combine
import SwiftUI

@Observable
class Router {
    // 네비게이션 경로
    var path: [Route] = .init()
    
    // 앱 실행 시, 2초간 로딩 화면 종료 여부
    var isLoadingViewFinished: Bool = false  // 앱 최초 실행 시, 2초간 로딩 화면 종료 여부
    
    // 앱 최초 실행 여부 - 온보딩 화면 전환 확인
    var hasEverOnboarded: Bool = false {
        didSet {
            UserDefaultsService().save(value: hasEverOnboarded, key: .hasEverOnboarded)
        }
    }
    
    init() {
        let result = UserDefaultsService().load(type: Bool.self, key: .hasEverOnboarded)
        switch result {
        case .success(let data):
            hasEverOnboarded = data
        case .failure:
            hasEverOnboarded = false
        }
    }
    
    // 가장 상위 View - 앱 진입 시 파악
    @ViewBuilder func rootView(_ router: Router) -> some View {
        if isLoadingViewFinished == false {
            // 앱 진입 시, 로딩 View
            Route.loading.view(router)
        } else {
            if hasEverOnboarded == false {
                // 앱 최초 실행 O -> 온보딩 View
                Route.onboarding.view(router)
            } else {
                // 앱 최초 실행 X -> 메모 View
                Route.memo.view(router)
            }
        }
    }
}
