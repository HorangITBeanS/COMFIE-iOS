//
//  MemoInputContracts.swift
//  COMFIE
//
//  Created by zaehorang on 2/25/26.
//

import Foundation

// Memo 입력창을 다시 그릴 때 사용하는 seed 스냅샷입니다.
struct MemoInputSeed: Equatable {
    var token: Int
    var originalText: String
    var emojiText: String

    static let empty = MemoInputSeed(token: 0, originalText: "", emojiText: "")
}

// 저장 직전에 Coordinator가 보내는 최종 입력 스냅샷입니다.
struct MemoInputSnapshot: Equatable {
    let originalText: String
    let emojiText: String
}

// InputView -> Store 단방향 출력 이벤트입니다.
enum MemoInputOutputEvent: Equatable {
    case draftAvailabilityChanged(isEmpty: Bool)
    case finalSnapshotReady(requestID: UUID, snapshot: MemoInputSnapshot)
    case finalSnapshotFailed(requestID: UUID)
}

// Store -> InputView 단방향 UI 명령입니다.
enum MemoInputUICommand: Equatable {
    case resignWithSync
    case resignWithoutSync
    case requestFinalSyncAndResign(requestID: UUID)
    case setFocus
}

// 동일 명령 중복 실행을 막기 위해 UUID를 함께 묶은 이벤트 래퍼입니다.
struct MemoInputUIEvent: Equatable {
    let id: UUID
    let command: MemoInputUICommand

    init(command: MemoInputUICommand) {
        self.id = UUID()
        self.command = command
    }
}
