//
//  MoreView.swift
//  COMFIE
//
//  Created by Anjin on 4/9/25.
//

import SwiftUI

struct MoreView: View {
    private let strings = StringLiterals.More.self
    
    var body: some View {
        VStack {
            Text("약관 및 정책")
            
            Spacer()
            
            Text("현재 버전")
        }
        .frame(maxWidth: .infinity)
        .background(Color.keyBackground)
        .cfNavigationBar(strings.navigationTitle.localized)
    }
}

#Preview {
    MoreView()
}
