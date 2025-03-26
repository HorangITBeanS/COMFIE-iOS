//
//  RetrospectionView.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/26/25.
//

import SwiftUI

struct RetrospectionView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 임시 네비게이션바
            Rectangle()
                .frame(height: 56)
            
            ZStack(alignment: .top) {
                Color.keyBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("2024.06.11 12:10")
                            .comfieFont(.systemBody)
                            .foregroundStyle(.black.opacity(0.6))
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    HStack(spacing: 0) {
                        Text("뭐라고 적어야 화가 나보일까? 미친거 아냐?")
                            .comfieFont(.body)
                            .foregroundStyle(.textBlack)
                        
                        Spacer()
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.cfGray)
                        .padding(.vertical, 17)
                    
                    Text("내가 정말 이런저런 어쩌구 상황에 스트레스를 많이 받는 것 같다. 앞으론 내가 힘들때에는 확실하게 거절할 수 있어야겠다. 나 거절 진짜 못하는데!!!!!!!!!!! 거절 어려워 !!!!!!!!!!!!")
                        .comfieFont(.body)
                        .foregroundStyle(.textBlack)
                }
                .padding(24)
            }
        }
    }
}

#Preview {
    RetrospectionView()
}
