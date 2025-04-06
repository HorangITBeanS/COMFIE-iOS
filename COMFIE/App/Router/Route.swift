//
//  Route.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

// Navigation으로 이동하는 경로
enum Route {
    case loading
    case onboarding
    case memo
    case retrospection
    case comfieZoneSetting
    
    @ViewBuilder func view(_ router: Router) -> some View {
        DIContainer(router: router).makeView(self)
    }
}
