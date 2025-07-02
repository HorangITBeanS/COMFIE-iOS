//
//  StringLiterals+Popup.swift
//  COMFIE
//
//  Created by Anjin on 3/12/25.
//

import SwiftUI

extension StringLiterals {
    enum Popup {
        enum Title {
            static let deleteComfieZone: LocalizedStringResource = "popup_title_delete_comfiezone"
            static let deleteMemo: LocalizedStringResource = "popup_title_delete_memo"
            static let deleteRetrospection: LocalizedStringResource = "popup_title_delete_retrospection"
            static let requestLocationPermission: LocalizedStringResource = "popup_title_request_location_permission"
            static let mailUnavailable: LocalizedStringResource = "popup_title_mail_unavailable"
        }
        
        enum SubTitle {
            static let deleteComfieZone: LocalizedStringResource = "popup_subtitle_delete_comfiezone"
            static let deleteMemo: LocalizedStringResource = "popup_subtitle_delete_memo"
            static let deleteRetrospection: LocalizedStringResource = "popup_subtitle_delete_retrospection"
            static let requestLocationPermission: LocalizedStringResource = "popup_subtitle_request_location_permission"
            static let mailUnavailable: LocalizedStringResource = "popup_subtitle_mail_unavailable"
        }
        
        enum ButtonDescription {
            static let delete: LocalizedStringResource = "popup_button_delete"
            static let cancel: LocalizedStringResource = "popup_button_cancel"
            static let noSave: LocalizedStringResource = "popup_button_no_save"
            static let keepEdit: LocalizedStringResource = "popup_button_keep_edit"
            static let doNext: LocalizedStringResource = "popup_button_do_next"
            static let goSetting: LocalizedStringResource = "popup_button_go_setting"
            static let copyMail: LocalizedStringResource = "popup_button_copy_mail"
            static let close: LocalizedStringResource = "popup_button_close"
        }
    }
}
