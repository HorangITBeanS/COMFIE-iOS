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
        enum ContentURL {
            static let service = "https://sites.google.com/view/comfie-terms-of-use/terms-of-use-%EA%B5%AD%EB%AC%B8"
            static let privacy = "https://sites.google.com/view/comfie-privacypolicy/privacy-policy%EA%B5%AD%EB%AC%B8"
        }
    }
}

// 더보기 > 의견 보내기
extension StringLiterals.More {
    enum SendFeedback {
        static let navigatioinTitle: LocalizedStringResource = "more_send_feedback_navigation_title"
        static let mailTitle: LocalizedStringResource = "more_send_feedback_mail_title"
        static let mailRecipient: LocalizedStringResource = "more_send_feedback_mail_recipient"
        static let emailAddress = "comfie.team@gmail.com"
        static let mailCopyToast: LocalizedStringResource = "more_send_feedback_mail_copy_toast"
    }
}

// 더보기 > 만든 사람들
extension StringLiterals.More {
    enum Makers {
        static let navigatioinTitle: LocalizedStringResource = "more_makers_navigation_title"
        
        static let contactSectiontitle: LocalizedStringResource = "more_makers_contact_sectiontitle"
        static let instagram: LocalizedStringResource = "more_makers_instagram"
        static let instagramContent: LocalizedStringResource = "more_makers_instagram_content"
    }
    
    enum Instagram {
        static let url = "https://www.instagram.com/comfie.diary"
    }
}
