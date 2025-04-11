//
//  SendFeedbackView.swift
//  COMFIE
//
//  Created by Anjin on 4/11/25.
//

import MessageUI
import SwiftUI

struct SendFeedbackView: View {
    private let strings = StringLiterals.More.SendFeedback.self
    
    var body: some View {
        // FIXME: 아직 의견 보내기 기본 화면 디자인이 없어서 임시로 둔 화면입니다
        Text(strings.navigatioinTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.keyBackground)
            .cfNavigationBar(strings.navigatioinTitle.localized)
    }
}

#Preview {
    SendFeedbackView()
}
