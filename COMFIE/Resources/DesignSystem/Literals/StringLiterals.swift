//
//  StringLiterals.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/9/25.
//

enum StringLiterals {
    enum Popup {
        enum Title {
            static let deleteComfieZone = "컴피존을 삭제할까요?"
            static let deleteMemo = "이 메모를 삭제할까요?"
            static let deleteRetrospection = "이 회고를 삭제할까요?"
            static let exitWithoutSaving = "수정사항을 저장하지 않고 나가시겠어요?"
        }
        
        enum SubTitle {
            static let deleteComfieZone = "삭제하려면 사용자 인증이 필요해요."
            static let deleteMemo = "삭제하면 복구할 수 없어요. 계속하시겠어요?"
            static let deleteRetrospection = "삭제하면 복구할 수 없어요. 계속하시겠어요?"
            static let exitWithoutSaving = "회고 수정사항이 반영되지 않습니다."
        }
        
        enum ButtonDescription {
            static let delete = "삭제하기"
            static let cancel = "취소하기"
            static let noSave = "저장 안 함"
            static let keepEdit = "계속 수정"
        }
    }
}
