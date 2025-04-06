//
//  RetrospectionView.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/26/25.
//

import SwiftUI

struct RetrospectionView: View {
    @State var intent: RetrospectionStore
    @FocusState private var isKeyboardFocused: Bool
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
                        Text(intent.state.originalMemo)
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
                              text: Binding(
                                get: { intent.state.inputContent },
                                set: { intent(.updateNewRetrospection($0)) }
                            ),
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
        .onAppear { intent(.onAppear) }
    }
}

#Preview {
    RetrospectionView(intent: .init(router: .init()))
}
