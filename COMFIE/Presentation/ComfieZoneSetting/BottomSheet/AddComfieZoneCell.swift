//
//  AddComfieZoneCell.swift
//  COMFIE
//
//  Created by Anjin on 4/14/25.
//

import SwiftUI

struct AddComfieZoneCell: View {
    var onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            Image(.icPlus)
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.keySecondary)
        }
    }
}
