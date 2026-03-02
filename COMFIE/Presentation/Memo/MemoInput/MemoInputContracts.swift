//
//  MemoInputContracts.swift
//  COMFIE
//
//  Created by zaehorang on 2/25/26.
//

import Foundation

// Memo 입력창을 다시 그릴 때 사용하는 seed 스냅샷입니다.
struct MemoInputSeed: Equatable {
    // seed 변경을 감지하기 위한 증가 토큰입니다.
    var token: Int
    // seed 기준 원문 문자열입니다.
    var originalText: String
    // seed 기준 이모지 문자열입니다.
    var emojiText: String

    // 입력 초기 상태를 나타내는 기본값입니다.
    static let empty = MemoInputSeed(token: 0, originalText: "", emojiText: "")
}

// 저장 직전에 Coordinator가 보내는 최종 입력 스냅샷입니다.
struct MemoInputSnapshot: Equatable {
    // 최종 원문 문자열
    let originalText: String
    // 최종 이모지 문자열
    let emojiText: String
}

// InputView -> Store 단방향 출력 이벤트입니다.
enum MemoInputOutputEvent: Equatable {
    // 현재 draft가 비어 있는지 알림
    case draftAvailabilityChanged(isEmpty: Bool)
    // 최종 스냅샷 동기화 완료 알림
    case finalSnapshotReady(requestID: UUID, snapshot: MemoInputSnapshot)
    // 최종 스냅샷 동기화 실패 알림
    case finalSnapshotFailed(requestID: UUID)
}

// Store -> InputView 단방향 UI 명령입니다.
enum MemoInputUICommand: Equatable {
    // 포커스를 내리기 전에 입력 동기화까지 수행
    case resignWithSync
    // 입력 동기화 없이 포커스만 내림
    case resignWithoutSync
    // 최종 스냅샷 동기화를 요청한 뒤 포커스 내림
    case requestFinalSyncAndResign(requestID: UUID)
    // 입력창 포커스 요청
    case setFocus
}

// 동일 명령 중복 실행을 막기 위해 UUID를 함께 묶은 이벤트 래퍼입니다.
struct MemoInputUIEvent: Equatable {
    // 이벤트 고유 ID
    let id: UUID
    // 실행할 실제 명령
    let command: MemoInputUICommand

    init(command: MemoInputUICommand) {
        // 이벤트를 새로 만들 때마다 고유 ID를 생성합니다.
        self.id = UUID()
        self.command = command
    }
}
