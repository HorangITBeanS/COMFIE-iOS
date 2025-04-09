//
//  CFListRow.swift
//  COMFIE
//
//  Created by Anjin on 4/9/25.
//

import SwiftUI

struct CFListRow<Content: View>: View {
    let title: String
    let isLast: Bool
    let action: (() -> Void)?
    @ViewBuilder var trailingView: Content
    
    // trailingView를 closure로 주입하는 경우
    init(
        title: String,
        isLast: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder trailingView: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.isLast = isLast
        self.action = action
        self.trailingView = trailingView()
    }
    
    // trailingView를 View로 주입하는 경우
    init(
        title: String,
        isLast: Bool = false,
        action: (() -> Void)? = nil,
        trailingView: Content
    ) {
        self.title = title
        self.isLast = isLast
        self.action = action
        self.trailingView = trailingView
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .comfieFont(.body)
                    .foregroundStyle(Color.textBlack)
                
                Spacer()
                
                trailingView
            }
            
            if isLast == false {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.keyBackground)
            }
        }
    }
}
