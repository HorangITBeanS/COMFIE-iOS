//
//  RetrospectionView.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/26/25.
//

import SwiftUI

struct RetrospectionView: View {
    @State private var retrospectionContent: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 임시 네비게이션바
            Rectangle()
                .frame(height: 56)
            
            ZStack(alignment: .top) {
                Color.keyBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text(Date().toFormattedDateTimeString())
                            .comfieFont(.systemBody)
                            .foregroundStyle(.cfBlack.opacity(0.6))
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    HStack(spacing: 0) {
                        // memo.originalText 연결
                        Text("뭐라고 적어야 화가 나보일까?")
                            .comfieFont(.body)
                            .foregroundStyle(.textBlack)
                        
                        Spacer()
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.cfGray)
                        .padding(.vertical, 17)
                    
                    TextField("",
                              text: $retrospectionContent,
                              axis: .vertical)
                        .comfieFont(.body)
                        .foregroundStyle(.textBlack)
                        .tint(.cfBlack)

                }
                .padding(24)
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    RetrospectionView()
}
