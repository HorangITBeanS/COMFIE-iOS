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
