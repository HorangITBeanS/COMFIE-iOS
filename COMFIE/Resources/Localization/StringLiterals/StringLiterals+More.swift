//
//  StringLiterals+More.swift
//  COMFIE
//
//  Created by Anjin on 4/9/25.
//

import Foundation

extension StringLiterals {
    enum More {
        static let navigationTitle: LocalizedStringResource = "more_navigation_title"
        
        // 약관 및 정책
        static let termsSectionTitle: LocalizedStringResource = "more_terms_section_title"
        static let serviceTerm: LocalizedStringResource = "more_service_term"
        static let privacyPolicy: LocalizedStringResource = "more_privacy_policy"
        static let locationTerm: LocalizedStringResource = "more_location_term"
        
        // 고객 지원
        static let customerSupportSectionTitle: LocalizedStringResource = "more_customer_support_section_title"
        static let sendFeedback: LocalizedStringResource = "more_send_feedback"
        static let makers: LocalizedStringResource = "more_makers"
        
        // 현재 버전
        static let currentVersion: LocalizedStringResource = "more_current_version"
    }
}

// 더보기 > 약관 및 정책
extension StringLiterals.More {
    enum Term {
        enum NavigationTitle {
            static let service: LocalizedStringResource = "more_term_navigation_title_service"
            static let privacy: LocalizedStringResource = "more_term_navigation_title_privacy"
            static let location: LocalizedStringResource = "more_term_navigation_title_location"
        }
        
        enum Content {
            static let service: LocalizedStringResource = "more_term_content_service"
            static let privacy: LocalizedStringResource = "more_term_content_privacy"
            static let location: LocalizedStringResource = "more_term_content_location"
        }
    }
}

// 더보기 > 의견 보내기
extension StringLiterals.More {
    enum SendFeedback {
        static let navigatioinTitle: LocalizedStringResource = "more_send_feedback_navigation_title"
    }
}
