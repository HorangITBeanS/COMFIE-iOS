//
//  StringLiterals+ComfieZoneSetting.swift
//  COMFIE
//
//  Created by Anjin on 4/5/25.
//

import Foundation

extension StringLiterals {
    enum ComfieZoneSetting {
        static let navigationTitle: LocalizedStringResource = "comfiezone_setting_navigation_title"
        
        enum InfoPopup {
            static let title: LocalizedStringResource = "comfiezone_setting_info_popup_title"
            static let description: LocalizedStringResource = "comfiezone_setting_info_popup_description"
            static let caption: LocalizedStringResource = "comfiezone_setting_info_popup_caption"
        }
        
        enum BottomSheet {
            static let title: LocalizedStringResource = "comfiezone_setting_bottom_sheet_title"
            static let textFieldTitleKey: LocalizedStringResource = "comfiezone_setting_bottom_sheet_text_field_title_key"
            static let textFieldPlaceholder: LocalizedStringResource = "comfiezone_setting_bottom_sheet_text_field_placeholder"
        }
        
        enum ToastMessage {
            static let hasNotLocationAuthorization: LocalizedStringResource = "comfiezone_setting_toast_message_has_not_location_authorization"
            static let inComfieZone: LocalizedStringResource = "comfiezone_setting_toast_message_in_comfiezone"
            static let notInComfieZone: LocalizedStringResource = "comfiezone_setting_toast_message_not_in_comfiezone"
            static let hasNotComfieZone: LocalizedStringResource = "comfiezone_setting_toast_message_has_not_comfiezone"
        }
    }
}
