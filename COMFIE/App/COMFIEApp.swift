//
//  COMFIEApp.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import SwiftUI

@main
struct COMFIEApp: App {
    @State private var router: Router
    private var diContainer: DIContainer
    
    init() {
        let router = Router()
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        if isUITesting {
            // UI 테스트 진입 안정화를 위해 로딩/온보딩/튜토리얼 상태를 고정한다.
            UserDefaults.standard.set(true, forKey: UserDefaultsConstants.Keys.hasEverOnboarded.rawValue)
            UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
            router.hasEverOnboarded = true
            router.isLoadingViewFinished = true
        }
        self.router = router
        self.diContainer = DIContainer(router: router)
    }
    
    var body: some Scene {
        WindowGroup {
            COMFIERoutingView(diContainer: diContainer)
                .environment(router)
        }
    }
}
