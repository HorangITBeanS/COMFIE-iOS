//
//  Memo+fromEntity.swift
//  COMFIE
//
//  Created by zaehorang on 3/11/25.
//

import CoreData

extension Memo {
    static func fromEntity(_ entity: MemoEntity) -> Result<Memo, Error> {
        guard
            let id = entity.id,
            let createdAt = entity.createdAt,
            let originalText = entity.originalText,
            let emojiText = entity.emojiText,
            let reflectionText = entity.reflectionText
        else {
            return .failure(CoreDataError.mapFromEntityFailed)
        }
        
        let memo = Memo(
            id: id,
            createdAt: createdAt,
            originalText: originalText,
            emojiText: emojiText,
            reflectionText: reflectionText
        )
        
        return .success(memo)
    }
}
