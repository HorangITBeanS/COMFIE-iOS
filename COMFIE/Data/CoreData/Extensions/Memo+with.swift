//
//  Memo+with.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 4/14/25.
//

extension Memo {
    func with(retrospectionText: String?) -> Memo {
        Memo(
            id: self.id,
            createdAt: self.createdAt,
            originalText: self.originalText,
            emojiText: self.emojiText,
            retrospectionText: retrospectionText
        )
    }
}
