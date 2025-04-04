//
//  RetrospectionView.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/26/25.
//

import SwiftUI

struct RetrospectionView: View {
    @State private var retrospectionContent: String = ""
    @FocusState private var isKeyboardFocused: Bool
    let memo: String = "뭐라고 적어야 화가 나보일까??"
    
    var body: some View {
        VStack(spacing: 0) {
            // temporary navigation bar
            Rectangle()
                .frame(height: 56)
            
            List {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text(Date().toFormattedDateTimeString())
                            .comfieFont(.systemBody)
                            .foregroundStyle(.cfBlack.opacity(0.6))
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    HStack(spacing: 0) {
                        // memo.originalText
                        Text(memo)
                            .comfieFont(.body)
                            .foregroundStyle(.textBlack)
                        
                        Spacer()
                    }
                }
                .padding(24)
                .background(Color.keyBackground)
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
                
                VStack(spacing: 0) {
                    TextField("지금 생각을 적어보세요.",
                              text: $retrospectionContent,
                              axis: .vertical)
                    .comfieFont(.body)
                    .foregroundStyle(.textBlack)
                    .tint(Color.textBlack)
                    Spacer()
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .frame(minHeight: 88)
                .background(Color.keyBackgroundSub)
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .background(Color.keyBackgroundSub)
        }
        .navigationBarBackButtonHidden()
        .onTapGesture {
            endTextEditing()
        }
    }
}

#Preview {
    RetrospectionView()
}
