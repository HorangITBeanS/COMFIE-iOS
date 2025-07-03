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
    var isUserInComfieZone: Bool {
        intent.state.isInComfieZone
    }
    
    private var isEditingMemo: Bool {
        intent.state.editingMemo != nil
    }
    
    var body: some View {
        ZStack {
            Color.keyBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    MemoListView(intent: $intent, isUserInComfieZone: isUserInComfieZone)
                        .onTapGesture {
                            intent(.backgroundTapped)
                        }
                        .padding(.top, 56)
                    
                    if isEditingMemo {
                        VStack {
                            Spacer()
                            editingCancelButton
                                .padding(.bottom, 10)
                        }
                    }
                    
                    navigationBarView
                        .onTapGesture {
                            intent(.backgroundTapped)
                        }
                }
                
                memoInputView
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
            Image(.tutorial)
                .resizable()
                .ignoresSafeArea()
            
            if intent.state.deletingMemo != nil {
                CFPopupView(type: .deleteMemo) {
                    intent(.deletePopup(.confirmDeleteButtonTapped))
                } rightButtonAction: {
                    intent(.deletePopup(.cancelDeleteButtonTapped))
                }
            }
        }
        .onAppear { intent(.onAppear) }
    }
    
    // MARK: - View Property
    private var navigationBarView: some View {
        HStack(spacing: 0) {
            Button {
                // 페이지 이동
                intent(.comfieZoneSettingButtonTapped)
            } label: {
                HStack(spacing: 8) {
                    // 컴피존 상태에 따라 로고 변경
                    Image(isUserInComfieZone ? .icComfie : .icUncomfie)
                        .resizable()
                        .frame(width: isUserInComfieZone ? 84 : 115, height: 25)
                    Image(.icLocation)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            
            Spacer()
            
            Button {
                intent(.moreButtonTapped)
            } label: {
                Image(.icHamburger)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .symbolRenderingMode(.monochrome)
                    .tint(.cfBlack)
            }
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 16)
        .background(.cfWhite)
        .shadow(color: Color.black.opacity(0.04),
                radius: 12,
                x: 0,
                y: 8)
    }
    
    private var memoInputView: some View {
        HStack(alignment: .top, spacing: 12) {
            MemoInputTextView(
                strings.textfieldPlaceholder.localized,
                memoStore: $intent
            )
            
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
            .disabled(intent.state.inputMemoText.isEmpty)
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
            memoRepository: MockMemoRepository(),
            locationUseCase: LocationUseCase(locationService: LocationService(), comfiZoneRepository: ComfieZoneRepository())
        )
    )
}
