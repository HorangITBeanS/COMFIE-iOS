//
//  COMFIERoutingView.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

struct COMFIERoutingView: View {
    @Environment(Router.self) private var router
    let diContainer: DIContainer
    
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            router.rootView(diContainer)
                .onAppear { finishLoadingView() }
                .navigationDestination(for: Route.self) { route in
                    route.view(diContainer)
                }
        }
        .environment(router)
    }
    
    private func finishLoadingView() {
        // 2초 후에 화면 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                router.isLoadingViewFinished = true
            }
        }
    }
}
