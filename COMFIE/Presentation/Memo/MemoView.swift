//
//  MemoView.swift
//  COMFIE
//
//  Created by zaehorang on 3/23/25.
//

import SwiftUI

struct MemoView: View {
    @State var intent: MemoStore
    @State private var newMemoText: String = ""
    
    var body: some View {
        ZStack {
            Color.keyBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                navigationBarView
                
                ScrollView {
                    
                }
                .overlay(alignment: .center) {
                    Text("아직 메모가 없어요. \n다행이네요!")
                }
                .multilineTextAlignment(.center)
                
                memoInputView
            }
        }
    }
    
    var navigationBarView: some View {
        HStack {
            // 조건에 따라 변경하기
            Image("icUncomfie")
            // Image("icComfie")
            
            Spacer()
            
            Button {
                // 페이지 이동
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
            TextField("입력", text: $newMemoText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.vertical, 9)
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .background(Color.keyBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                newMemoText = ""
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
