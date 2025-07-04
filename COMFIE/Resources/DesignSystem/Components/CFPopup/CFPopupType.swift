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
    case requestLocatioinPermission
    case mailUnavailable
    
    var title: LocalizedStringResource {
        switch self {
        case .deleteComfieZone: return StringLiterals.Popup.Title.deleteComfieZone
        case .deleteMemo: return StringLiterals.Popup.Title.deleteMemo
        case .deleteRetrospection: return StringLiterals.Popup.Title.deleteRetrospection
        case .requestLocatioinPermission: return StringLiterals.Popup.Title.requestLocationPermission
        case .mailUnavailable: return StringLiterals.Popup.Title.mailUnavailable
        }
    }
    
    var subTitle: LocalizedStringResource {
        switch self {
        case .deleteComfieZone: return StringLiterals.Popup.SubTitle.deleteComfieZone
        case .deleteMemo: return StringLiterals.Popup.SubTitle.deleteMemo
        case .deleteRetrospection: return StringLiterals.Popup.SubTitle.deleteRetrospection
        case .requestLocatioinPermission: return StringLiterals.Popup.SubTitle.requestLocationPermission
        case .mailUnavailable: return StringLiterals.Popup.SubTitle.mailUnavailable
        }
    }
    
    var leftButtonDescription: LocalizedStringResource {
        switch self {
        case .deleteComfieZone, .deleteMemo, .deleteRetrospection: return StringLiterals.Popup.ButtonDescription.delete
        case .requestLocatioinPermission: return StringLiterals.Popup.ButtonDescription.doNext
        case .mailUnavailable: return StringLiterals.Popup.ButtonDescription.copyMail
        }
    }
    
    var rightButtonDescription: LocalizedStringResource {
        switch self {
        case .deleteComfieZone, .deleteMemo, .deleteRetrospection: return StringLiterals.Popup.ButtonDescription.cancel
        case .requestLocatioinPermission: return StringLiterals.Popup.ButtonDescription.goSetting
        case .mailUnavailable: return StringLiterals.Popup.ButtonDescription.close
        }
    }
    
    enum ButtonType {
        case normal
        case destructive
        case cancel
        
        var backgroundColor: Color {
            switch self {
            case .normal: return Color.keyPrimary
            case .destructive: return Color.destructiveRed
            case .cancel: return Color.cfLightgray
            }
        }
        
        var textColor: Color {
            switch self {
            case .normal, .destructive: return Color.textWhite
            case .cancel: return Color.textBlack
            }
        }
    }
}
