//
//  CFNavigationBar.swift
//  COMFIE
//
//  Created by Anjin on 3/27/25.
//

import SwiftUI

struct CFNavigationBarButton: Identifiable {
    let id: UUID = UUID()
    let image: Image
    let action: () -> Void
}

struct CFNavigationBar: View {
    let title: String
    let isBackButtonHidden: Bool
    let trailingButton: CFNavigationBarButton?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 네비게이션바 타이틀
            Text(title)
                .comfieFont(.title)
                .foregroundStyle(Color.textBlack)
            
            HStack {
                // 왼쪽 뒤로가기 버튼
                if isBackButtonHidden == false {
                    Button {
                        dismiss()
                    } label: {
                        Image(.icBack)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
                
                Spacer()
                
                // 오른쪽 버튼
                if let button = trailingButton {
                    Button {
                        button.action()
                    } label: {
                        button.image
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 56)
    }
}
