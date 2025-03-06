//
//  COMFIERoutingView.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

struct COMFIERoutingView: View {
    @State private var router: Router = Router()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            router.rootView
                .onAppear { finishLoadingView() }
                .navigationDestination(for: Route.self) { route in
                    route.view()
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

#Preview {
    COMFIERoutingView()
}
