//
//  OnboardingView.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import SwiftUI

struct OnboardingView: View {
    @State var intent: OnboardingIntentContainer
    
    var body: some View {
        VStack {
            Text("온보딩 View")
            
            Button {
                intent(.nextButtonTapped)
            } label: {
                Text("다음")
            }
        }
    }
}

#Preview {
    OnboardingView(intent: OnboardingIntentContainer())
}
