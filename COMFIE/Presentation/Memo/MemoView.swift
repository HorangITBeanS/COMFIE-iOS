//
//  MemoView.swift
//  COMFIE
//
//  Created by zaehorang on 3/23/25.
//

import SwiftUI

struct MemoView: View {
    private let strings = StringLiterals.Memo.self
    
    @State var intent: MemoStore
    
    @FocusState private var isMemoInputFieldFocused: Bool
    
    // 컴피존 관련 모델에서 주입 받아야 한다.
    @State private var isUserInComfieZone: Bool = false
    
    private var isEditingMemo: Bool {
        intent.state.editingMemo != nil
    }
    
    var body: some View {
        ZStack {
            Color.keyBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                navigationBarView
                    .onTapGesture {
                        intent(.backgroundTapped)
                    }
                 
                ZStack {
                    MemoListView(intent: $intent, isUserInComfieZone: $isUserInComfieZone)
                        .onTapGesture {
                            intent(.backgroundTapped)
                        }
                    
                    if isEditingMemo {
                        VStack {
                            Spacer()
                            editingCancelButton
                                .padding(.bottom, 10)
                        }
                    }
                }
                
                memoInputView
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
            if intent.state.deletingMemo != nil {
                CFPopupView(type: .deleteMemo) {
                    intent(.deletePopup(.confirmDeleteButtonTapped))
                } rightButtonAction: {
                    intent(.deletePopup(.cancelDeleteButtonTapped))
                }
            }
        }
        .onAppear { intent(.onAppear) }
        .onReceive(intent.sideEffectPublisher) { effect in
            switch effect {
            case .ui(.setMemoInputFocus):
                isMemoInputFieldFocused = true
            case .ui(.removeMemoInputFocus):
                isMemoInputFieldFocused = false
            }
        }
    }
    
    // MARK: - View Property
    private var navigationBarView: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                // 컴피존 상태에 따라 로고 변경
                Image(isUserInComfieZone ? .icComfie : .icUncomfie)
                    .resizable()
                    .frame(width: isUserInComfieZone ? 84 : 115, height: 25)
                Image(.icLocation)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
            
            Button {
                // 페이지 이동
                intent(.comfieZoneSettingButtonTapped)
            } label: {
                Image(.icEllipsis)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 16)
        .background(.cfWhite)
    }
    
    private var memoInputView: some View {
        HStack(alignment: .top, spacing: 12) {
            TextField(strings.textfieldPlaceholder.localized,
                      text:
                        Binding(
                            get: { intent.state.inputMemoText },
                            set: { intent(.memoInput(.updateNewMemo($0))) }
                        ),
                      axis: .vertical)
            .lineLimit(1...4)
            .focused($isMemoInputFieldFocused)
            .padding(.vertical, 9)
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .background(Color.keyBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                intent(.memoInput(.memoInputButtonTapped))
            } label: {
                Image(isEditingMemo ? .icCheck : .icSend)
                    .resizable()
                    .foregroundStyle(.cfWhite)
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(
                        intent.state.inputMemoText.isEmpty
                        ? .keyDeactivated
                        : .keyPrimary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                topTrailingRadius: 16,
                style: .continuous
            )
            .foregroundStyle(.cfWhite)
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: -4)
            .ignoresSafeArea()
        }
    }
    
    private var editingCancelButton: some View {
        Button {
            intent(.memoCell(.editingCancelButtonTapped))
        } label: {
            Text(strings.editingCancelButtonTitle.localized)
                .comfieFont(.body)
                .foregroundStyle(.destructiveRed)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(.cfWhite)
                .clipShape(RoundedRectangle(cornerRadius: 212))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 0)
        }
    }
}

#Preview {
    MemoView(
        intent: MemoStore(
            router: Router(),
            memoRepository: MockMemoRepository()
        )
    )
}
