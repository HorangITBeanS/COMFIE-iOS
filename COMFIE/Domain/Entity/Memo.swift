//
//  Memo.swift
//  COMFIE
//
//  Created by Anjin on 3/7/25.
//

import Foundation

struct Memo: Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    var originalText: String
    var emojiText: String
    var retrospectionText: String?
}

/// dummy memo
extension Memo {
    static var sampleMemos: [Memo] {
        [Memo(id: UUID(), createdAt: Date(), originalText: "첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모", emojiText: "😀", retrospectionText: "첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모첫 번째 메모"),
        Memo(id: UUID(), createdAt: Date(), originalText: "두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모", emojiText: "📚", retrospectionText: "두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모두 번째 메모"),
        Memo(id: UUID(), createdAt: Date().addingTimeInterval(-86400), originalText: "세 번째 메모", emojiText: "✈️"),
        Memo(id: UUID(), createdAt: Date().addingTimeInterval(-86400 * 2), originalText: "네 번째 메모", emojiText: "🍔"),
        Memo(id: UUID(), createdAt: Date().addingTimeInterval(-86400 * 2), originalText: "다섯 번째 메모", emojiText: "🏀")
    ]
    }
}
