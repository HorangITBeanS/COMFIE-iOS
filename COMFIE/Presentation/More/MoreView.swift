//
//  MoreView.swift
//  COMFIE
//
//  Created by Anjin on 4/9/25.
//

import MessageUI
import SwiftUI

struct MoreView: View {
    @State var intent: MoreStore
    private var state: MoreStore.State { intent.state }
    private let strings = StringLiterals.More.self
    
    @State var mailViewResult: Result<MFMailComposeResult, Error>?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    // 약관 및 정책
                    CFList(sectionTitle: strings.termsSectionTitle.localized) {
                        CFListRow(
                            title: strings.serviceTerm.localized,
                            action: { intent(.serviceTermRowTapped) },
                            trailingView: forwardImage
                        )
                        
                        CFListRow(
                            title: strings.privacyPolicy.localized,
                            isLast: true,
                            action: { intent(.privacyPolicyRowTapped) },
                            trailingView: forwardImage
                        )
                    }
                    
                    // 고객 지원
                    CFList(sectionTitle: strings.customerSupportSectionTitle.localized) {
                        CFListRow(
                            title: strings.sendFeedback.localized,
                            action: { intent(.sendFeedbackRowTapped) }
                        )
                        
                        CFListRow(
                            title: strings.makers.localized,
                            isLast: true,
                            action: { intent(.makersRowTapped) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                
                Spacer()
                
                // 현재 버전
                currentVersionView
            }
            .frame(maxWidth: .infinity)
            .background(Color.keyBackground)
            .cfNavigationBarWithImageTitle()
            // 의견 보내기 - 메일앱 활성화 사용자 - 메일앱 시트
            .sheet(
                isPresented: .constant(state.showMailSheet),
                onDismiss: { intent(.dismissMailSheet) },
                content: {
                    MailView(
                        onDismiss: { intent(.dismissMailSheet) },
                        result: $mailViewResult
                    )
                }
            )
            
            if intent.state.showMailUnavailablePopupView {
                CFPopupView(type: .mailUnavailable,
                            leftButtonType: .normal,
                            leftButtonAction: { intent(.copyMailButtonTapped) },
                            rightButtonAction: { intent(.closePopupButtonTapped) }
                )
            }
        }
    }
    
    // > 이미지
    private var forwardImage: some View {
        Image(.icForward)
            .resizable()
            .frame(width: 14, height: 20)
    }
    
    // 현재 버전
    private var currentVersionView: some View {
        HStack(spacing: 0) {
            Text(strings.currentVersion.localized)
                .foregroundStyle(Color.textBlack)
            
            Text(state.currentVersion)
                .foregroundStyle(Color.textDarkgray)
        }
        .comfieFont(.systemBody)
        .padding(.bottom, 26)
    }
}

#Preview {
    MoreView(intent: MoreStore(router: .init()))
}
