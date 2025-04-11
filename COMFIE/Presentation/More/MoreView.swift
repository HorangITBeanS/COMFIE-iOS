//
//  MoreView.swift
//  COMFIE
//
//  Created by Anjin on 4/9/25.
//

import SwiftUI

struct MoreView: View {
    @State var intent: MoreStore
    private var state: MoreStore.State { intent.state }
    private let strings = StringLiterals.More.self
    
    var body: some View {
        VStack {
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
                        action: { intent(.privacyPolicyRowTapped) },
                        trailingView: forwardImage
                    )
                    
                    CFListRow(
                        title: strings.locationTerm.localized,
                        isLast: true,
                        action: { intent(.locationTermRowTapped) },
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
            Text(strings.currentVersion.localized + state.currentVersion)
                .comfieFont(.systemBody)
                .foregroundStyle(Color.textDarkgray)
                .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity)
        .background(Color.keyBackground)
        .cfNavigationBar(strings.navigationTitle.localized)
        // 의견 보내기 - 메일앱 활성화 사용자 - 메일앱 시트
        .sheet(
            isPresented: .constant(state.showMailSheet),
            onDismiss: { intent(.dismissMailSheet) },
            content: { Text("메일앱") }
        )
    }
    
    // > 이미지
    private var forwardImage: some View {
        Image(.icForward)
            .resizable()
            .frame(width: 14, height: 20)
    }
}

#Preview {
    MoreView(intent: MoreStore(router: .init()))
}
