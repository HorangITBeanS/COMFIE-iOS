//
//  OnboardingView.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import SwiftUI

struct OnboardingView: View {
    @State var intent: OnboardingStore
    private let strings = StringLiterals.Onboarding.self
    
    var body: some View {
        ZStack {
            Color.cfWhite.ignoresSafeArea()
            
            VStack(spacing: 28) {
                Image(.icComfieZoneInfo)
                    .resizable()
                    .frame(width: 280, height: 280)
                
                VStack(spacing: 12) {
                    TextWithDifferentFont(
                        originalString: strings.requestLocation.localized,
                        originalFont: .body,
                        differentFontString: strings.requestLocationHighlight.localized,
                        differentFont: .bodyBold
                    )
                    .foregroundStyle(Color.textBlack)
                    .frame(width: 260)
                    
                    Text(strings.requestLocationDescription)
                        .comfieFont(.systemBody)
                        .foregroundStyle(Color.textGray)
                        .frame(width: 280)
                }
                .multilineTextAlignment(.center)
            }
            
            VStack {
                Spacer()
                
                Button {
                    intent(.nextButtonTapped)
                } label: {
                    HStack {
                        Spacer()
                        Text(strings.nextButton)
                            .comfieFont(.body)
                            .foregroundStyle(Color.cfWhite)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(Color.keyPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 38)
            }
        }
    }
}

#Preview {
    OnboardingView(
        intent: OnboardingStore(
            router: Router(),
            locationUseCase: LocationUseCase(
                locationService: LocationService()
            )
        )
    )
}
