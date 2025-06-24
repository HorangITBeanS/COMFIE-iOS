//
//  TermView.swift
//  COMFIE
//
//  Created by Anjin on 4/10/25.
//

import SwiftUI

struct TermView: View {
    enum Term { case service, privacy }
    let type: Term
    private let strings = StringLiterals.More.Term.self
    
    var body: some View {
        ScrollView {
            Text(content())
                .comfieFont(.body)
                .foregroundStyle(Color.textBlack)
                .padding(24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.keyBackground)
        .cfNavigationBar(navigationTitle())
    }
    
    private func content() -> String {
        switch type {
        case .service: strings.Content.service.localized
        case .privacy: strings.Content.privacy.localized
        }
    }
    
    private func navigationTitle() -> String {
        switch type {
        case .service: strings.NavigationTitle.service.localized
        case .privacy: strings.NavigationTitle.privacy.localized
        }
    }
}
