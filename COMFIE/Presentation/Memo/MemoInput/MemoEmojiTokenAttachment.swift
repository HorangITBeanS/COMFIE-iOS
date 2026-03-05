//
//  MemoEmojiTokenAttachment.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

// 텍스트뷰 안에서 "원문 1글자 + 이모지 1글자"를 같이 들고 다니는 토큰입니다.
final class MemoEmojiTokenAttachment: NSTextAttachment {
    let original: String
    let emoji: String

    // 원문/이모지 쌍으로 attachment를 구성하고 렌더링 크기와 baseline을 고정합니다.
    init(original: String, emoji: String, font: UIFont) {
        self.original = original
        self.emoji = emoji
        super.init(data: nil, ofType: nil)

        let emojiString = NSAttributedString(string: emoji, attributes: [.font: font])
        let textSize = emojiString.size()
        let width = max(1, ceil(textSize.width))
        let height = ceil(font.lineHeight)
        let size = CGSize(width: width, height: height)
        image = Self.renderEmojiImage(emoji, in: size, font: font)
        bounds = CGRect(x: 0, y: font.descender, width: width, height: height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 이모지를 텍스트와 같은 폰트 기준으로 이미지화해 attachment에 맞춰 그립니다.
    private static func renderEmojiImage(_ emoji: String, in size: CGSize, font: UIFont) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let attributed = NSAttributedString(string: emoji, attributes: attributes)
            let textSize = attributed.size()
            let origin = CGPoint(
                x: max(0, (size.width - textSize.width) * 0.5),
                y: max(0, (size.height - textSize.height) * 0.5)
            )
            attributed.draw(at: origin)
        }
    }
}
