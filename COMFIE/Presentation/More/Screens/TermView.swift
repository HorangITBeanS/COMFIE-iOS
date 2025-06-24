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
            Text(contentURL())
                .comfieFont(.body)
                .foregroundStyle(Color.textBlack)
                .padding(24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.keyBackground)
        .cfNavigationBarWithImageTitle()
    }
    
    private func contentURL() -> String {
        switch type {
        case .service: strings.ContentURL.service
        case .privacy: strings.ContentURL.privacy
        }
    }
}
