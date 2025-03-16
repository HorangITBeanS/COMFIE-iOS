//
//  Memo+toEntity.swift
//  COMFIE
//
//  Created by zaehorang on 3/10/25.
//

import CoreData

extension Memo {
    static func toEntity(context: NSManagedObjectContext, memo: Memo) -> MemoEntity {
        let entity = MemoEntity(context: context)
        entity.id = memo.id
        entity.createdAt = memo.createdAt
        entity.originalText = memo.originalText
        entity.emojiText = memo.emojiText
        entity.retrospectionText = memo.retrospectionText
        
        return entity
    }
}
