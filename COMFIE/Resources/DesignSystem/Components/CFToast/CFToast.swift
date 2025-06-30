//
//  CFToast.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 6/26/25.
//

import SwiftUI

struct CFToast: View {
    let backgroundColor: Color
    let textColor: Color
    let content: String
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                Text(content)
                    .comfieFont(.body)
                    .foregroundStyle(textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 90)
        }
    }
}
