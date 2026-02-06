//
//  MemoEmojiTokenAttachment.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

final class MemoEmojiTokenAttachment: NSTextAttachment {
    let original: String
    let emoji: String

    init(original: String, emoji: String, font: UIFont) {
        self.original = original
        self.emoji = emoji
        super.init(data: nil, ofType: nil)

        // 이모지를 이미지로 렌더링해 텍스트 레이아웃/커서 동작을 안정화한다.
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
