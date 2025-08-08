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
    let action: () -> Void
    @ViewBuilder var trailingView: Content
    
    // trailingView를 closure로 주입하는 경우
    init(
        title: String,
        isLast: Bool = false,
        action: @escaping () -> Void = { },
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
        action: @escaping () -> Void = { },
        trailingView: Content
    ) {
        self.title = title
        self.isLast = isLast
        self.action = action
        self.trailingView = trailingView
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                action()
            } label: {
                HStack {
                    Text(title)
                        .comfieFont(.body)
                        .foregroundStyle(Color.textBlack)
                    
                    Spacer()
                    
                    trailingView
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            if isLast == false {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.keyBackground)
                    .padding(.horizontal, 16)
            }
        }
    }
}
