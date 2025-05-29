//
//  LoadingView.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.cfWhite.ignoresSafeArea()
            
            // 로고
            Image(.icAppLogoSmall)
                .resizable()
                .scaledToFit()
                .frame(height: 100)
        }
    }
}

#Preview {
    LoadingView()
}
