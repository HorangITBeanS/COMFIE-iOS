//
//  RetrospectionView.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/26/25.
//

import SwiftUI

enum Field: Hashable {
    case content
}

struct RetrospectionView: View {
    @State private var retrospectionContent: String = ""
    @FocusState private var isKeyboardFocused: Bool
    let memo: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // temporary navigation bar
            Rectangle()
                .frame(height: 56)
            
            ZStack(alignment: .top) {
                Color.keyBackground.ignoresSafeArea()
                
                ScrollView {
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
                        .focused($isKeyboardFocused)
                    }
                    .padding(24)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            if retrospectionContent.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    isKeyboardFocused = true
                }
            }
        }
        .onTapGesture {
            endTextEditing()
        }
    }
}

#Preview {
    RetrospectionView()
}
