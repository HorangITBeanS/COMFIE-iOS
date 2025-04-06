//
//  CFNavigationBar.swift
//  COMFIE
//
//  Created by Anjin on 3/27/25.
//

import SwiftUI

enum CFNavigationBarButtonContent {
    case button(action: () -> Void, label: AnyView)
    case menu(label: AnyView, menuItems: [MenuItem])
    
    struct MenuItem {
        let title: String
        let role: ButtonRole?
        let systemImage: String?
        let action: () -> Void
    }
}

struct CFNavigationBarButton: Identifiable {
    let id: UUID = UUID()
    let content: CFNavigationBarButtonContent
    
    static func button(
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) -> CFNavigationBarButton {
        .init(content: .button(action: action, label: AnyView(label())))
    }
    
    static func menu(
        @ViewBuilder label: () -> some View,
        menuItems: [CFNavigationBarButtonContent.MenuItem]
    ) -> CFNavigationBarButton {
        .init(content: .menu(label: AnyView(label()), menuItems: menuItems))
    }
}

@ViewBuilder
private func navigationButtons(for buttons: [CFNavigationBarButton]) -> some View {
    ForEach(buttons) { button in
        switch button.content {
        case let .button(action, label):
            Button(action: action) {
                label
            }
            
        case let .menu(label, menuItems):
            Menu {
                ForEach(menuItems.indices, id: \.self) { index in
                    let item = menuItems[index]
                    Button(role: item.role) {
                        item.action()
                    } label: {
                        if let systemImage = item.systemImage {
                            Label(item.title, systemImage: systemImage)
                        } else {
                            Text(item.title)
                        }
                    }
                }
            } label: {
                label
            }
        }
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
}

#Preview {
    VStack {
        Text("hello")
    }
    .cfNavigationBar(
        "title",
        backButtonAction: { },
        trailingButtons: [
            CFNavigationBarButton.button {
                // action
            } label: {
                Image(.icInfo)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        ]
    )
}
