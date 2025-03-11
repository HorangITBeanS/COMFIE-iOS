//
//  CFPopupType.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/9/25.
//

import SwiftUI

enum CFPopupType {
    case deleteComfieZone
    case deleteMemo
    case deleteRetrospection
    case exitWithoutSaving
    
    var title: String {
        switch self {
        case .deleteComfieZone: return StringLiterals.Popup.Title.deleteComfieZone.localized
        case .deleteMemo: return StringLiterals.Popup.Title.deleteMemo.localized
        case .deleteRetrospection: return StringLiterals.Popup.Title.deleteRetrospection.localized
        case .exitWithoutSaving: return StringLiterals.Popup.Title.exitWithoutSaving.localized
        }
    }
    
    var subTitle: String {
        switch self {
        case .deleteComfieZone: return StringLiterals.Popup.SubTitle.deleteComfieZone.localized
        case .deleteMemo: return StringLiterals.Popup.SubTitle.deleteMemo.localized
        case .deleteRetrospection: return StringLiterals.Popup.SubTitle.deleteRetrospection.localized
        case .exitWithoutSaving: return StringLiterals.Popup.SubTitle.exitWithoutSaving.localized
        }
    }
    
    var leftButtonDescription: String {
        switch self {
        case .deleteComfieZone, .deleteMemo, .deleteRetrospection: return StringLiterals.Popup.ButtonDescription.delete.localized
        case .exitWithoutSaving: return StringLiterals.Popup.ButtonDescription.noSave.localized
        }
    }
    
    var rightButtonDescription: String {
        switch self {
        case .deleteComfieZone, .deleteMemo, .deleteRetrospection: return StringLiterals.Popup.ButtonDescription.cancel.localized
        case .exitWithoutSaving: return StringLiterals.Popup.ButtonDescription.keepEdit.localized
        }
    }
    
    enum ButtonType {
        case destructive
        case cancel
        
        var backgroundColor: Color {
            switch self {
            case .destructive: return Color.popupRed
            case .cancel: return Color.cfLightgray
            }
        }
        
        var textColor: Color {
            switch self {
            case .destructive: return Color.textWhite
            case .cancel: return Color.textBlack
            }
        }
    }
}
