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
    // 컴피존 관련 모델에서 주입 받아야 한다.
    @State private var isUserInComfieZone: Bool = true
    
    var body: some View {
        ZStack {
            Color.keyBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Group {
                    navigationBarView
                    
                    MemoListView(intent: $intent)
                }
                .onTapGesture {
                    intent(.onTapGesture)
                }
                
                memoInputView
            }
        }
        .onAppear { intent(.onAppear) }
    }
    
    // MARK: - View Property
    var navigationBarView: some View {
        HStack {
            // 컴피존 상태에 따라 로고 변경
            if isUserInComfieZone {
                Image("icComfie")
            } else {
                Image("icUncomfie")
            }
            
            Spacer()
            
            Button {
                // 페이지 이동
                intent(.comfieZoneSettingButtonTapped)
            } label: {
                Image("icLocation")
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 16)
        .background(.cfWhite)
    }
    
    var memoInputView: some View {
        HStack(alignment: .top, spacing: 12) {
            TextField(strings.textfieldPlaceholder.localized,
                      text:
                        Binding(
                            get: { intent.state.newMemo },
                            set: { intent(.updateNewMemo($0)) }
                        ),
                      axis: .vertical)
            .lineLimit(1...4)
            .padding(.vertical, 9)
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .background(Color.keyBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                intent(.memoInputButtonTapped)
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundStyle(.cfWhite)
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(.keyDeactivated)
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    MemoView(
        intent: MemoStore(
            router: Router()
        )
    )
}
