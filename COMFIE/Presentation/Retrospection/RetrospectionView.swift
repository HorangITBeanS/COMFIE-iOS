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
            Color.keySubBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CFNavigationBar(title: stringLiterals.title.localized,
                                isBackButtonHidden: false,
                                backButtonAction: { intent(.backButtonTapped) },
                                leadingButtons: [],
                                trailingButtons: retrospectionTrailingButtons)
                .onTapGesture(perform: { intent(.backgroundTapped) })
                
                ScrollViewReader { proxy in
                    ScrollView {
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
                        .highPriorityGesture(
                            TapGesture().onEnded { intent(.backgroundTapped) }
                        )
                        
                        VStack(spacing: 0) {
                            TextField(stringLiterals.contentPlaceholder.localized,
                                      text: Binding(
                                        get: { intent.state.inputContent },
                                        set: { intent(.updateRetrospection($0)) }
                                      ),
                                      axis: .vertical)
                            .comfieFont(.body)
                            .foregroundStyle(.textBlack)
                            .tint(.textBlack)
                            .multilineTextAlignment(.leading)
                            .focused($isKeyboardFocused)
                            .onChange(of: intent.state.inputContent) {
                                withAnimation {
                                    proxy.scrollTo(ViewID.textField, anchor: .bottom)
                                }
                            }
                            .onChange(of: isKeyboardFocused) {
                                if isKeyboardFocused {
                                    intent(.contentFieldTapped)
                                }
                            }
                            .id(ViewID.textField)
                            
                            Spacer()
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .frame(minHeight: 88)
                    }
                    .background(Color.keySubBackground)
                    .onTapGesture(perform: { intent(.contentFieldTapped) })
                }
            }
            .navigationBarBackButtonHidden(true)
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
                        Text(stringLiterals.doneButton.localized)
                            .comfieFont(.systemTitle)
                            .foregroundStyle(.keyPrimary)
                    }
                )
            )
        }
        
        return buttons
    }
    
    private enum ViewID {
        case textField
    }
}

#Preview {
    RetrospectionView(intent: .init(router: .init()))
}
