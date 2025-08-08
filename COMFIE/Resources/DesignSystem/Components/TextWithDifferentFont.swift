//
//  TextWithDifferentFont.swift
//  COMFIE
//
//  Created by Anjin on 3/25/25.
//

import SwiftUI

struct TextWithDifferentFont: View {
    let originalString: String
    let originalFont: ComfieFontType
    
    let differentFontString: String
    let differentFont: ComfieFontType
    
    var body: some View {
        textView()
    }
    
    private func textView() -> some View {
        // 1. 기본 문자열 생성 후 AttributedString으로 변환
        var attrString = AttributedString(originalString)
        
        // 2. "특별한 텍스트"라는 부분의 범위를 찾기
        if let range = attrString.range(of: differentFontString) {
            // 해당 범위에 대해 다른 폰트와 색상 적용
            attrString[range].font = UIFont(
                name: differentFont.fontName.rawValue,
                size: differentFont.fontSize
            )
        }
        
        // 3. Text 뷰에 AttributedString 적용
        return Text(attrString)
            .comfieFont(originalFont)
            .foregroundStyle(Color.textBlack)
            .frame(width: 260)
    }
}
