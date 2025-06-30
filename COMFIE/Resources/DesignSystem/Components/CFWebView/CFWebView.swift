//
//  CFWebView.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 6/25/25.
//

import SwiftUI
import WebKit

struct CFWebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        uiView.load(URLRequest(url: url))
    }
}
