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
        ZStack {
            VStack(spacing: 0) {
                CFNavigationBar(title: stringLiterals.title.localized,
                                isBackButtonHidden: false,
                                backButtonAction: { intent(.backButtonTapped) },
                                leadingButtons: [],
                                trailingButtons: retrospectionTrailingButtons)
                
                List {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            // memo.createdDate 연결 필요
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
                        .tint(.textBlack)
                        .focused($isKeyboardFocused)
                        .onChange(of: isKeyboardFocused) { _, isFocused in
                            if isFocused {
                                intent(.contentFieldTapped)
                            }
                        }

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
            .onTapGesture { intent(.backgroundTapped) }
            .onAppear { intent(.onAppear) }
            .onReceive(intent.sideEffectPublisher) { sideEffect in
                switch sideEffect {
                case .ui(.setContentFieldFocus): isKeyboardFocused = true
                case .ui(.removeContentFieldFocus): isKeyboardFocused = false
                }
            }
            
            if intent.state.showDeletePopupView {
                CFPopupView(type: .deleteRetrospection,
                            leftButtonAction: { intent(.deleteRetrospectionButtonTapped) },
                            rightButtonAction: { intent(.cancelDeleteRetrospectionButtonTapped) })
            }
        }
    }
    
    private var menuButton: some View {
        Menu {
            Button(role: .destructive) {
                intent(.deleteMenuButtonTapped)
            } label: {
                Label(stringLiterals.deleteRetrospection.localized,
                      systemImage: "trash")
            }
        } label: {
            Image(.icEllipsis)
                .resizable()
                .frame(width: 24, height: 24)
        }
    }
    
    private var retrospectionTrailingButtons: [CFNavigationBarButton] {
        var buttons: [CFNavigationBarButton] = []
        buttons.append(
            CFNavigationBarButton(
                action: { },
                label: { menuButton }
            )
        )
        if intent.state.showCompleteButton {
            buttons.append(
                CFNavigationBarButton(
                    action: { intent(.completeButtonTapped) },
                    label: {
                        Text("완료")
                            .comfieFont(.systemTitle)
                            .foregroundStyle(.keyPrimary)
                    }
                )
            )
        }
        
        return buttons
    }
}

#Preview {
    RetrospectionView(intent: .init(router: .init()))
}
