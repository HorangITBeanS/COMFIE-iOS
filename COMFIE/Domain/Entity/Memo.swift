//
//  Memo.swift
//  COMFIE
//
//  Created by Anjin on 3/7/25.
//

import Foundation

struct Memo {
    let id: UUID = .init()
    let createdAt: Date = .now
    var originalText: String
    var emojiText: String
    var reflectionText: String?
}
