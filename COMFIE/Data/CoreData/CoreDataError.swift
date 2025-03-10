//
//  CoreDataError.swift
//  COMFIE
//
//  Created by zaehorang on 3/11/25.
//

import Foundation

enum CoreDataError: LocalizedError {
    case mapFromEntityFailed
    case entityNotFound
    case deleteFailed
    
    var erriorDescription: String? {
        switch self {
        case .mapFromEntityFailed:
            return "CoreData Entity에서 Domain Entity로 매핑을 실패했습니다."
        case .entityNotFound:
            return "요청한 CoreData Entity를 찾을 수 없습니다."
        case .deleteFailed:
            return "CoreData에서 삭제를 실패했습니다."
        }
    }
}
