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
    
    var letterSpacing: CGFloat {
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
    /// 뷰에 comfieFont 메소드를 활용하여 폰트를 지정합니다.
    func comfieFont(_ type: ComfieFontType) -> some View {
        let font = UIFont(name: type.fontName.rawValue, size: type.fontSize) ?? UIFont.systemFont(ofSize: type.fontSize)
        
        return self
            .font(Font(font))
            .kerning(type.letterSpacing / 100 * type.fontSize)
            .padding(.vertical, (type.lineHeight - font.lineHeight) / 2)
            .lineSpacing(type.lineHeight - font.lineHeight)
    }
}
