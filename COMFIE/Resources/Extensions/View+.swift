//
//  View+.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/27/25.
//

import SwiftUI

extension View {
    func endTextEditing() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil)
    }
}
