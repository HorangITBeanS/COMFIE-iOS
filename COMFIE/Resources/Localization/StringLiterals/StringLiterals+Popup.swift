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
            static let exitWithoutSaving: LocalizedStringResource = "popup_title_exit_without_saving"
        }
        
        enum SubTitle {
            static let deleteComfieZone: LocalizedStringResource = "popup_subtitle_delete_comfiezone"
            static let deleteMemo: LocalizedStringResource = "popup_subtitle_delete_memo"
            static let deleteRetrospection: LocalizedStringResource = "popup_subtitle_delete_retrospection"
            static let exitWithoutSaving: LocalizedStringResource = "popup_subtitle_exit_without_saving"
        }
        
        enum ButtonDescription {
            static let delete: LocalizedStringResource = "popup_button_delete"
            static let cancel: LocalizedStringResource = "popup_button_cancel"
            static let noSave: LocalizedStringResource = "popup_button_no_save"
            static let keepEdit: LocalizedStringResource = "popup_button_keep_edit"
        }
    }
}
