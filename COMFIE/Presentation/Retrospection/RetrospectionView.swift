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
    private let stringLiterals = StringLiterals.Retrospection.self
    
    var body: some View {
        VStack(spacing: 0) {
            CFNavigationBar(title: stringLiterals.title.localized,
                            isBackButtonHidden: false,
                            backButtonAction: { },
                            leadingButtons: [],
                            trailingButtons: [
                                CFNavigationBarButton(
                                    action: { },
                                    label: {
                                        Image(.icEllipsis)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                    }
                                )
                            ])
            
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
                    TextField(stringLiterals.contentPlaceholder.localized,
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
