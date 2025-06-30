//
//  MakersView.swift
//  COMFIE
//
//  Created by Anjin on 4/11/25.
//

import SwiftUI

struct MakersView: View {
    private let strings = StringLiterals.More.Makers.self
    
    var body: some View {
        VStack(spacing: 6) {
            Image(.imgMakers)
            
            // 연락
            CFList(sectionTitle: strings.contactSectiontitle.localized) {
                CFListRow(
                    title: strings.instagram.localized,
                    isLast: true,
                    action: { linkComfieInstagram() },
                    trailingView: trailingTextView(strings.instagramContent)
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.keyBackground)
        .cfNavigationBarWithImageTitle()
    }
    
    @ViewBuilder
    private func trailingTextView(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .comfieFont(.body)
            .foregroundStyle(Color.textBlack)
    }
    
    private func linkComfieInstagram() {
        guard let url = URL(string: StringLiterals.More.Instagram.url) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    MakersView()
}
