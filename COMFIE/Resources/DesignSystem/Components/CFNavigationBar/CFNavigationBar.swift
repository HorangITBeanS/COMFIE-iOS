//
//  CFNavigationBar.swift
//  COMFIE
//
//  Created by Anjin on 3/27/25.
//

import SwiftUI

struct CFNavigationBarButton: Identifiable {
    let id: UUID = UUID()
    let action: () -> Void
    let label: AnyView
    
    init<Content: View>(
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Content
    ) {
        self.action = action
        self.label = AnyView(label())
    }
}

struct CFNavigationBar: View {
    let title: String
    let isBackButtonHidden: Bool
    let backButtonAction: () -> Void
    let leadingButtons: [CFNavigationBarButton]
    let trailingButtons: [CFNavigationBarButton]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 네비게이션바 타이틀
            Text(title)
                .comfieFont(.title)
                .foregroundStyle(Color.textBlack)
            
            HStack(spacing: 0) {
                // 왼쪽 버튼들
                HStack(spacing: 8) {
                    if isBackButtonHidden == false {
                        backButton()  // 뒤로가기 버튼
                    }
                    
                    navigationButtons(for: leadingButtons)
                }
                
                Spacer()
                
                // 오른쪽 버튼들
                HStack(spacing: 8) {
                    navigationButtons(for: trailingButtons)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 56)
        .background(Color.cfWhite)
    }
    
    @ViewBuilder
    private func backButton() -> some View {
        Button {
            backButtonAction()
            dismiss()
        } label: {
            Image(.icBack)
                .resizable()
                .frame(width: 24, height: 24)
        }
    }
    
    @ViewBuilder
    private func navigationButtons(for buttons: [CFNavigationBarButton]) -> some View {
        ForEach(buttons) { button in
            Button {
                button.action()
            } label: {
                button.label
            }
        }
    }
}

#Preview {
    VStack {
        Text("hello")
    }
    .cfNavigationBar(
        "title",
        trailingButtons: [
            CFNavigationBarButton {
                // action
            } label: {
                Image(.icInfo)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        ]
    )
}
