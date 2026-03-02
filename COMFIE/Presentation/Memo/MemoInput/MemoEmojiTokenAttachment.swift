//
//  MemoEmojiTokenAttachment.swift
//  COMFIE
//
//  Created by zaehorang on 2/5/26.
//

import UIKit

// 텍스트뷰 안에서 "원문 1글자 + 이모지 1글자"를 같이 들고 다니는 토큰입니다.
final class MemoEmojiTokenAttachment: NSTextAttachment {
    // 토큰이 나타내는 원문 글자입니다.
    let original: String
    // 화면에 보여줄 이모지 글자입니다.
    let emoji: String

    // 토큰을 만들 때 원문/이모지 쌍과 폰트를 함께 받아 이미지까지 준비합니다.
    init(original: String, emoji: String, font: UIFont) {
        // 스냅샷 복원을 위해 원문 값을 보관합니다.
        self.original = original
        // 스냅샷 복원을 위해 이모지 값을 보관합니다.
        self.emoji = emoji
        // NSTextAttachment 기본 초기화를 먼저 수행합니다.
        super.init(data: nil, ofType: nil)

        // 폰트 기준으로 이모지 렌더 크기를 계산합니다.
        let emojiString = NSAttributedString(string: emoji, attributes: [.font: font])
        let textSize = emojiString.size()
        // 폭이 0이 되면 토큰이 깨질 수 있으니 최소 1을 보장합니다.
        let width = max(1, ceil(textSize.width))
        // 높이는 라인 높이에 맞춰 caret/선택 동작을 안정화합니다.
        let height = ceil(font.lineHeight)
        let size = CGSize(width: width, height: height)
        // 실제 텍스트 대신 표시될 이모지 이미지를 렌더링합니다.
        image = Self.renderEmojiImage(emoji, in: size, font: font)
        // baseline 정렬을 맞추기 위해 descender를 반영합니다.
        bounds = CGRect(x: 0, y: font.descender, width: width, height: height)
    }

    // 현재 구현에서는 아카이브 복원을 지원하지 않습니다.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 이모지 문자열을 attachment 이미지로 그려서 반환합니다.
    private static func renderEmojiImage(_ emoji: String, in size: CGSize, font: UIFont) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            // 렌더링 때도 동일한 폰트를 써서 텍스트/토큰 높이 차이를 줄입니다.
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let attributed = NSAttributedString(string: emoji, attributes: attributes)
            let textSize = attributed.size()
            // 토큰 영역 가운데에 맞춰 그립니다.
            let origin = CGPoint(
                x: max(0, (size.width - textSize.width) * 0.5),
                y: max(0, (size.height - textSize.height) * 0.5)
            )
            attributed.draw(at: origin)
        }
    }
}
