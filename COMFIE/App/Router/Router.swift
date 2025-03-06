//
//  Router.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

@Observable
class Router {
    var path: [Route] = .init()
    
    // 앱 최초 실행 시, 2초간 로딩 화면 종료 여부
    var isLoadingViewFinished: Bool = false
    var rootView: some View {
        if isLoadingViewFinished == false {
            // 앱 진입 시, 로딩 View
            return Route.loading.view()
        } else {
            // 앱 최초 실행 O -> 온보딩 View
            // 앱 최초 실행 X -> 메모 View
            return Route.onboarding.view()
        }
    }
}
