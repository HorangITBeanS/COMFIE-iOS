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
    let memo: String = "안녕하세요 안녕하세요 안녕하세요"
    
    var body: some View {
        VStack(spacing: 0) {
            // 임시 네비게이션바
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
                .background(Color.keySubBackground)
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .background(Color.keySubBackground)
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
