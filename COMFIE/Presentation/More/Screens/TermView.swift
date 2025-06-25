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
        CFWebView(urlString: contentURL())
            .edgesIgnoringSafeArea(.bottom)
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
