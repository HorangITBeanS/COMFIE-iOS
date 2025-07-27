//
//  Memo+with.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 4/14/25.
//

extension Memo {
    func with(retrospectionText: String?, emojiRetrospectionText: String?) -> Memo {
        Memo(
            id: self.id,
            createdAt: self.createdAt,
            originalText: self.originalText,
            emojiText: self.emojiText,
            originalRetrospectionText: retrospectionText,
            emojiRetrospectionText: emojiRetrospectionText
        )
    }
}
