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
            
            // 임시 로고
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 100, height: 100)
                .foregroundStyle(Color(red: 0.85, green: 0.85, blue: 0.85))
        }
    }
}

#Preview {
    LoadingView()
}
