//
//  CFList.swift
//  COMFIE
//
//  Created by Anjin on 4/9/25.
//

import SwiftUI

struct CFList<Content: View>: View {
    var sectionTitle: String?
    @ViewBuilder var rowsView: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section 제목
            if let sectionTitle {
                Text(sectionTitle)
                    .comfieFont(.body)
                    .foregroundStyle(Color.textBlack)
                    .padding(.leading, 4)
            }
            
            // List
            VStack(alignment: .leading, spacing: 8) {
                rowsView
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.cfWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
