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
        VStack(spacing: 50) {
            // TODO: 만든 사람들 그래픽 추후에 추가
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120), spacing: 0)],
                alignment: .leading
            ) {
                ForEach(0 ..< 5, id: \.self) { _ in
                    Circle()
                        .foregroundStyle(Color.keyDeactivated)
                        .frame(width: 120, height: 120)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            
            // 연락
            CFList(sectionTitle: strings.contactSectiontitle.localized) {
                CFListRow(
                    title: strings.instagram.localized,
                    trailingView: trailingTextView(strings.instagramContent)
                )
                .disabled(true)
                
                CFListRow(
                    title: strings.email.localized,
                    isLast: true,
                    trailingView: trailingTextView(strings.emailContent)
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.keyBackground)
        .cfNavigationBar(strings.navigatioinTitle.localized)
    }
    
    @ViewBuilder
    private func trailingTextView(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .comfieFont(.body)
            .foregroundStyle(Color.textBlack)
    }
}

#Preview {
    MakersView()
}
