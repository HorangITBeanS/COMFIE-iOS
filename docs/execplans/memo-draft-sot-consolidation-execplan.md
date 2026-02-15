# Memo Input 경계 단순화 + 의사결정 근거 문서화 ExecPlan

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document follows `/PLANS.md` from the repository root and must be maintained in accordance with that file.

## Purpose / Big Picture

이 변경의 목적은 메모 입력 책임을 단순하게 분리해, 사용자가 기존과 같은 동작을 안정적으로 사용하도록 만드는 것이다. 사용자는 이전과 동일하게 입력, 이모지 표시 전환, 저장 버튼 활성화, 저장 중 가드, 편집 취소, 한국어 IME 조합 입력을 사용할 수 있어야 한다.

차이는 내부 구조다. 이제 입력 중간 텍스트의 소유자는 `UITextView` 경계이고, `MemoStore`는 정책과 저장 트랜잭션만 담당한다. 저장은 "최종 스냅샷" 요청-응답 한 번으로만 진행된다.

## Progress

- [x] (2026-02-15 09:20Z) 기존 구현과 테스트를 전수 확인하고, 입력 책임 분리와 timeout 제거 범위를 확정했다.
- [x] (2026-02-15 10:00Z) `MemoStore`에 `inputSeed`, `isInputEmpty`, `savePhase` 중심 상태를 유지하고 입력 중간 본문 상시 보관 책임을 제거했다.
- [x] (2026-02-15 10:35Z) `MemoStore.Intent.MemoInputIntent.finalSyncFailed(requestID:)`를 추가하고 timeout 기반 복구 로직을 제거했다.
- [x] (2026-02-15 11:05Z) `MemoView`를 입력 중재자로 고정하고 Store side effect를 `MemoInputUIEvent`로 전달하도록 연결했다.
- [x] (2026-02-15 11:40Z) `MemoInputTextView`/`MemoInputUITextView`/`Coordinator`에서 `MemoStore` 직접 의존을 제거했다.
- [x] (2026-02-15 12:20Z) `Coordinator`가 로컬 draft(`original/emoji/revision`)를 소유하고 final sync 요청 시점에만 스냅샷을 응답하도록 정리했다.
- [x] (2026-02-15 13:00Z) `textView == nil` 경계에서 local draft fallback 또는 실패 이벤트를 보내 저장 파이프라인 고착을 방지했다.
- [x] (2026-02-15 14:05Z) timeout 전제 테스트를 마이그레이션하고 `finalSyncFailed`, requestID mismatch, 빈 스냅샷 저장 금지 케이스를 강화했다.
- [x] (2026-02-15 14:50Z) `xcodebuild test -scheme COMFIE` 전체 테스트를 통과시켰다.
- [x] (2026-02-15 20:50+0900) 전체 회귀를 재실행해 `** TEST SUCCEEDED **`를 재확인하고 최신 xcresult 경로를 기록했다.
- [x] (2026-02-15 20:55+0900) `docs/decisions` 문서 2개를 작성하고 이 ExecPlan의 living 섹션을 최신 구현 결과로 갱신했다.
- [x] (2026-02-15 21:01+0900) 안전 범위 중복 제거 리팩토링을 적용했다(입력 seed 초기화 공통화, idle 가드 predicate 통합, Coordinator flush+sync helper 통합, Snapshot dead code 제거).
- [x] (2026-02-15 23:18+0900) 문서 변경분(`docs/decisions` 2건 + 본 ExecPlan)을 최종 점검하고 최신 상태로 확정했다.

## Surprises & Discoveries

- Observation: 시작 시점에 `docs/decisions` 디렉터리가 존재하지 않아 문서화 산출물을 새로 만들 필요가 있었다.
  Evidence: 초기 `ls docs/decisions` 실패 후 디렉터리 생성.

- Observation: 기존 테스트가 timeout/late-completion 정책에 강하게 결합되어 있어, 실패 이벤트 정책으로 바꾸면서 테스트 의도를 함께 재작성해야 했다.
  Evidence: 기존 `COMFIETests/MemoStoreInputSnapshotTests.swift`의 timeout 관련 시나리오 다수 교체.

- Observation: 입력 타입을 별도 파일로 분리했을 때 타깃 포함 누락으로 컴파일 실패가 발생해, 최종적으로 `MemoStore.swift`에 타입을 공존시켰다.
  Evidence: `cannot find type 'MemoInputSeed' in scope` 계열 빌드 에러 재현 후 해결.

- Observation: ComfieZone plain-mode 매핑 테스트는 단순 원문 비교가 아니라 "기존 이모지 매핑 보존"이 핵심이라, final snapshot fixture를 실제 저장 경로 형태로 맞춰야 했다.
  Evidence: `MemoStoreComfieZoneMappingTests`의 fixture 수정 전/후 통과 여부 차이.

- Observation: `textView == nil` 경계는 이미 회귀 테스트로 보호되고 있었고, 이번 구조에서도 fallback 응답 정책이 유효했다.
  Evidence: `MemoStoreInputSnapshotTests`의 nil textView final sync 테스트 통과.

## Decision Log

- Decision: 입력 중 원문/이모지 중간값은 Input View(`MemoInputUITextView.Coordinator`)가 소유한다.
  Rationale: IME 조합 상태(`markedTextRange`), 커서, attachment 변환은 UIKit 로컬 상태와 분리할수록 오류 위험이 커진다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: Store가 실시간으로 소유하는 입력 상태는 `isInputEmpty` Bool로 제한한다.
  Rationale: 버튼 UX/가드에는 충분하고, 본문 동기화 복잡도는 크게 감소한다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: 표시 모드는 도메인 상태인 `isInComfieZone`에서 계산하고 View는 Bool만 소비한다.
  Rationale: 도메인 정책 일관성과 테스트 가능성을 유지한다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: 저장 요청은 Store side effect에서 시작하고 MemoView가 InputView와 Store 사이를 중재한다.
  Rationale: MVI 흐름을 유지하면서 InputView의 Store 비종속성을 보장한다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: final sync 상관관계는 `requestID` 단일 규칙으로 검증한다.
  Rationale: 최소 안전장치로 stale 응답 반영을 차단할 수 있다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: timeout을 제거하고 `finalSyncFailed(requestID)` 이벤트로 `idle` 복귀한다.
  Rationale: timeout/late-callback 복합 정책보다 상태 전이가 단순하고 명시적이다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: `textView == nil`일 때는 local draft로 즉시 final snapshot 응답하거나 불가능하면 실패 이벤트를 보낸다.
  Rationale: 생명주기 경계에서도 저장 파이프라인 정지를 방지한다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: 빈값 저장 금지는 View 가드와 Store 가드를 모두 유지한다.
  Rationale: 제품 불변식은 방어를 한 레이어에만 의존하지 않는다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: 저장 실패 시 입력 draft는 유지하고 savePhase만 `idle`로 복귀한다.
  Rationale: 사용자가 즉시 재시도할 수 있어야 한다.
  Date/Author: 2026-02-15 / user + assistant

- Decision: 새 입력 계약 타입(`MemoInputSeed`, `MemoInputSnapshot`, `MemoInputUICommand`, `MemoInputUIEvent`)은 현재 `MemoStore.swift`에 둔다.
  Rationale: 별도 파일 타깃 누락으로 인한 빌드 불안정성을 즉시 차단하고, 추후 타깃 정리 시 분리 가능하다.
  Date/Author: 2026-02-15 / assistant

- Decision: 중복 제거 리팩토링은 동작 불변 원칙으로 수행하고, 정책/콜백 시맨틱 변경은 분리한다.
  Rationale: 유지보수성을 개선하면서도 저장 파이프라인/IME 회귀 위험을 최소화하기 위해서다.
  Date/Author: 2026-02-15 / user + assistant

## Outcomes & Retrospective

핵심 목표였던 "동작 동일성 유지 + Store 복잡도 감소 + 의사결정 재사용 가능성"을 달성했다. 사용자는 기존과 같은 화면 동작을 유지하고, 내부적으로는 입력 책임 경계가 명확해졌다.

Store는 더 이상 입력 중간 문자열 동기화를 강제하지 않고, final sync 트랜잭션과 정책 가드에 집중한다. InputView는 IME/커서/attachment 세부를 로컬 상태로 처리한다. timeout 제거로 save 파이프라인 상태 전이가 단순해졌고, 실패 복구는 명시 이벤트로 관찰 가능해졌다.

남은 학습 과제는 테스트 파일 분할이다. 특히 `MemoStoreInputSnapshotTests`는 범위가 넓어 이후 유지보수 비용을 낮추기 위해 주제별 파일 분할이 유효하다.

## Context and Orientation

이 작업에서 "Input View"는 `UITextView`를 감싼 SwiftUI 브리지 계층(`MemoInputTextView`, `MemoInputUITextView`, `Coordinator`)을 뜻한다. 여기서 "draft"는 사용자가 입력 중인 임시 텍스트 상태이고, "final snapshot"은 저장 직전에 확정된 `(originalText, emojiText, revision)` 값이다.

핵심 파일은 다음과 같다.

- `COMFIE/Presentation/Memo/MemoStore.swift`: 도메인 상태, 저장 트랜잭션, 가드 정책을 처리한다.
- `COMFIE/Presentation/Memo/MemoView.swift`: Store side effect를 받아 InputView 명령으로 중재한다.
- `COMFIE/Presentation/Memo/MemoInput/MemoInputTextView.swift`: SwiftUI 입력 컴포넌트 계약.
- `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView.swift`: UIKit 브리지 입력/출력 인터페이스.
- `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Coordinator.swift`: IME/커서/최종 스냅샷 생성 로직.
- `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Snapshot.swift`: draft 가용성 이벤트와 스냅샷 보조 로직.
- `COMFIETests/MemoStoreInputSnapshotTests.swift`: final sync 트랜잭션 회귀군.
- `COMFIETests/MemoStoreSavePhaseNavigationTests.swift`: savePhase 가드 회귀군.
- `COMFIETests/MemoStoreComfieZoneMappingTests.swift`: plain-mode 이모지 매핑 회귀군.
- `COMFIETests/MemoInputIMEInsertionTests.swift`: 입력/IME 경계 회귀군.

의사결정 기록은 다음 문서에 남겼다.

- `docs/decisions/2026-02-15-memo-input-boundary-simplification.md`
- `docs/decisions/2026-02-15-memo-final-sync-no-timeout.md`

## Plan of Work

먼저 Store와 Input 경계를 계약 기반으로 분리했다. Store는 입력 본문 실시간 동기화를 버리고, `isInputEmpty`와 `savePhase`를 중심으로 저장 정책만 유지한다. 저장 버튼에서 즉시 저장하지 않고 `requestFinalSyncAndResign(requestID)` 명령을 내리고, matching `requestID`의 `finalSyncCompleted`만 저장에 반영한다.

그다음 MemoView를 중재자로 고정했다. Store side effect를 수신해 InputView 명령으로 전달하고, InputView의 draft/final/fail 이벤트를 다시 Store intent로 전달한다. 이로써 InputView 파일군의 `MemoStore` 직접 참조를 제거했다.

이후 timeout 경로를 제거했다. 응답 누락이나 불가능한 상태는 시간 기반 추정이 아니라 `finalSyncFailed(requestID)`로 복구한다. `textView == nil` 경계에서는 가능한 경우 local draft를 즉시 final snapshot으로 응답하고, seed와 draft 모두 비어 있으면 실패 이벤트로 복귀한다.

마지막으로 테스트를 새 계약으로 마이그레이션하고, 결정 근거를 `docs/decisions`에 분리 문서로 남겼다.

## Concrete Steps

작업 디렉터리는 `/Users/zaehorang/Documents/Projects/COMFIE-iOS`다.

timeout 참조 제거 확인:

    rg -n "finalSyncTimedOut|finalSyncTimeout|startFinalSyncTimeout" COMFIE/Presentation/Memo

기대 결과는 출력 없음이다.

InputView의 Store 직접 의존 제거 확인:

    rg -n "MemoStore" COMFIE/Presentation/Memo/MemoInput

기대 결과는 출력 없음이다.

전체 테스트 검증:

    xcodebuild test -scheme COMFIE -destination 'id=919596A7-E423-4D2A-86EE-A892781BCC2C' -derivedDataPath /tmp/comfie-codex-derived

기대 결과 핵심 라인은 다음과 같다.

    ** TEST SUCCEEDED **

## Validation and Acceptance

수용 기준은 다음 사용자 행동으로 판단한다.

- 빈 입력이면 저장 버튼이 비활성이고 Store 저장 진입이 차단된다.
- 저장 버튼 연타 시 `awaitingFinalSync` 요청은 1회만 처리된다.
- `requestID`가 다른 final 응답은 무시된다.
- 응답 누락/실패 시 `finalSyncFailed`로 `savePhase`가 `idle`로 복귀한다.
- `textView == nil` 경계에서도 저장 파이프라인이 고착되지 않는다.
- 저장 실패 후 입력 draft는 유지된다.
- IME marked/unmarked 변환과 plain-mode 이모지 매핑이 회귀하지 않는다.
- savePhase 진행 중 네비게이션/삭제/배경 탭 차단이 유지된다.

검증 근거 테스트는 다음 파일에 존재한다.

- `COMFIETests/MemoStoreInputSnapshotTests.swift`
- `COMFIETests/MemoStoreSavePhaseNavigationTests.swift`
- `COMFIETests/MemoStoreComfieZoneMappingTests.swift`
- `COMFIETests/MemoInputIMEInsertionTests.swift`

## Idempotence and Recovery

이 계획은 반복 실행 가능하게 구성되었다. Store 경계 변경, View 중재 연결, timeout 제거, 테스트 마이그레이션을 분리 단계로 적용했기 때문에 문제 발생 시 최근 단계만 되돌려 재적용할 수 있다.

가장 위험한 변경은 timeout 제거였고, 이를 `finalSyncFailed` 대체 경로와 동시 적용해 상태 고착을 방지했다. 실패 시 복구는 단순하다. `savePhase`를 `idle`로 복귀시키고 draft를 유지하므로 사용자는 입력 손실 없이 재시도할 수 있다.

## Artifacts and Notes

주요 산출물:

- `docs/decisions/2026-02-15-memo-input-boundary-simplification.md`
- `docs/decisions/2026-02-15-memo-final-sync-no-timeout.md`

최종 검증 로그 요약:

    rg -n "finalSyncTimedOut|finalSyncTimeout|startFinalSyncTimeout" COMFIE/Presentation/Memo
    (no output)

    rg -n "MemoStore" COMFIE/Presentation/Memo/MemoInput
    (no output)

    rg -n "syncSnapshotToStoreIfPossible\(" COMFIE/Presentation/Memo
    (no output)

    rg -n "case finalSyncFailed|case finalSyncCompletedWithRevision|case requestFinalSyncAndResign" COMFIE/Presentation/Memo/MemoStore.swift
    (expected interface cases remain)

    xcodebuild test -scheme COMFIE -destination 'id=919596A7-E423-4D2A-86EE-A892781BCC2C' -derivedDataPath /tmp/comfie-codex-derived
    ** TEST SUCCEEDED **
    xcresult: /tmp/comfie-codex-derived/Logs/Test/Test-COMFIE-2026.02.15_20-59-18-+0900.xcresult

## Interfaces and Dependencies

최종 인터페이스는 다음 규약을 따른다.

`COMFIE/Presentation/Memo/MemoStore.swift`에서 입력 계약 타입을 제공한다.

    struct MemoInputSeed: Equatable {
        var token: Int
        var originalText: String
        var emojiText: String
    }

    struct MemoInputSnapshot: Equatable {
        let originalText: String
        let emojiText: String
        let revision: Int
    }

    enum MemoInputUICommand: Equatable {
        case resignWithSync
        case resignWithoutSync
        case requestFinalSyncAndResign(requestID: UUID)
        case setFocus
    }

    struct MemoInputUIEvent: Equatable {
        let id: UUID
        let command: MemoInputUICommand
    }

`MemoStore.Intent.MemoInputIntent`는 다음 케이스를 가진다.

    case draftAvailabilityChangedWithRevision(isEmpty: Bool, revision: Int)
    case memoInputButtonTapped
    case finalSyncCompletedWithRevision(requestID: UUID, snapshot: MemoInputSnapshot)
    case finalSyncFailed(requestID: UUID)

`MemoStore.State`는 입력 경계 관련으로 다음 속성을 유지한다.

    var inputSeed: MemoInputSeed
    var isInputEmpty: Bool
    var savePhase: SavePhase
    var isInComfieZone: Bool
    var editingMemo: Memo?
    var deletingMemo: Memo?

`COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView.swift`의 Input View 계약은 다음이다.

    init(
        inputSeed: MemoInputSeed,
        isEmojiPresentationEnabled: Bool,
        uiCommandEvent: MemoInputUIEvent?,
        onDraftAvailabilityChanged: @escaping (Bool, Int) -> Void,
        onFinalSnapshotReady: @escaping (UUID, MemoInputSnapshot) -> Void,
        onFinalSnapshotFailed: @escaping (UUID) -> Void
    )

의존성 경계 규칙:

- InputView 파일군은 `MemoStore` 타입을 직접 참조하지 않는다.
- MemoView만 Store와 InputView 양쪽을 알고 중재한다.
- 저장 트랜잭션 시작/검증 책임은 Store에 남긴다.
- plain-mode 이모지 보존 계산은 `EmojiString` 도메인 함수에 위임한다.

Revision Note (2026-02-15 20:50+0900): 전체 테스트를 한 번 더 재실행해 성공 로그와 xcresult 경로를 갱신했다. 문서 기준 검증 증거를 최신 상태로 유지하기 위한 업데이트다.
Revision Note (2026-02-15 20:55+0900): 본 리비전에서 ExecPlan을 2026-02-15 최종 구현 상태로 전면 갱신했다. 기존 timeout/legacy 의존 설명을 제거하고, 실제 반영된 인터페이스, 실패 이벤트 기반 복구, 테스트/문서 산출물 근거를 통합했다.
Revision Note (2026-02-15 21:01+0900): 안전 범위 중복 제거를 코드에 반영하고, 정적 확인(미사용 메서드 제거/인터페이스 유지)과 전체 테스트 성공 증거를 ExecPlan에 추가했다.
Revision Note (2026-02-15 23:18+0900): 문서 변경분을 최종 점검해 결정 문서 2건과 ExecPlan living 섹션을 현재 브랜치 상태와 일치하도록 확정했다.
