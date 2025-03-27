//
//  Memo.swift
//  COMFIE
//
//  Created by Anjin on 3/7/25.
//

import Foundation

struct Memo: Identifiable {
    let id: UUID
    let createdAt: Date
    var originalText: String
    var emojiText: String
    var retrospectionText: String?
}
