//
//  OnboardingView.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import SwiftUI

struct OnboardingView: View {
    @State var intent: OnboardingStore
    
    var body: some View {
        VStack {
            Text("온보딩 View")
            
            Button {
                intent(.nextButtonTapped)
            } label: {
                Text("메모 화면으로")
            }
        }
//        .environment(intent)
    }
}

#Preview {
    OnboardingView(intent: OnboardingStore(router: Router()))
}
