//
//  View+ComfieFonts.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/8/25.
//

import SwiftUI

enum ComfieFontType {
    case title
    case body
    case systemTitle
    case systemSubtitle
    case systemBody
    
    var fontName: PretendardWeight {
        switch self {
        case .title: return .bold
        case .body, .systemBody: return .regular
        case .systemTitle, .systemSubtitle: return .medium
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .title: return 20
        case .body: return 16
        case .systemTitle: return 16
        case .systemSubtitle: return 14
        case .systemBody: return 12
        }
    }
    
    var kerning: CGFloat {
        switch self {
        case .title: return 0
        case .body, .systemTitle, .systemSubtitle, .systemBody: return -2
        }
    }
    
    var lineHeight: CGFloat {
        switch self {
        case .title: return 10
        case .body, .systemTitle, .systemSubtitle, .systemBody: return 13.5
        }
    }
}

enum PretendardWeight: String {
    case bold = "Pretendard-Bold"
    case medium = "Pretendard-Medium"
    case regular = "Pretendard-Regular"
}

extension View {
    func comfieFont(_ type: ComfieFontType) -> some View {
        let font = UIFont(name: type.fontName.rawValue, size: type.fontSize) ?? UIFont.systemFont(ofSize: type.fontSize)
        
        return self
            .font(Font(font))
            .padding(.vertical, (type.lineHeight - font.lineHeight) / 2)
            .lineSpacing(type.lineHeight - font.lineHeight)
    }
}
