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
    private let userDefaults = UserDefaultsService()
    
    // 네비게이션 경로
    var path: [Route] = []
    
    // 앱 실행 시, 2초간 로딩 화면 종료 여부
    var isLoadingViewFinished: Bool = false
    
    // 앱 최초 실행 여부 - 온보딩 화면 전환 확인
    var hasEverOnboarded: Bool = false {
        didSet {
            userDefaults.save(value: hasEverOnboarded, key: .hasEverOnboarded)
        }
    }
    
    init() {
        let result = userDefaults.load(type: Bool.self, key: .hasEverOnboarded)
        
        switch result {
        case .success(let data):
            hasEverOnboarded = data
        case .failure:
            hasEverOnboarded = false
        }
    }
    
    // 가장 상위 View - 앱 진입 시 파악
    @ViewBuilder func rootView(_ diContainer: DIContainer) -> some View {
        if isLoadingViewFinished == false {
            Route.loading.view(diContainer)     // 앱 진입 시, 로딩 View
        } else if hasEverOnboarded == false {
            Route.onboarding.view(diContainer)  // 앱 최초 실행 O -> 온보딩 View
        } else {
            Route.memo.view(diContainer)        // 앱 최초 실행 X -> 메모 View
        }
    }
}
