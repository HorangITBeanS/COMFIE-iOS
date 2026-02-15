# 2026-02-15 Memo Input 경계 단순화

- Status: Accepted
- Date: 2026-02-15
- Owner: Memo feature team (user + assistant)

## 문제 정의

기존 메모 입력 구조는 `MemoStore`와 `UITextView` 코디네이터가 동시에 입력 중간값(원문/이모지)을 들고 있었습니다.
이중 소유 때문에 IME 조합(`markedTextRange`) 중간 상태, 커서 이동, 붙여넣기, 편집 취소/재진입에서 동기화 복잡도가 계속 증가했습니다.

## 고려한 대안

1. Store가 입력 중간 텍스트를 계속 소유한다.
장점: Store만 보면 상태를 파악하기 쉽다.
단점: UIKit 입력 엔진 특성(조합중 텍스트, attachment, 커서)에 맞춘 상태 동기화 코드가 Store까지 퍼진다.

2. InputView(`MemoInputUITextView.Coordinator`)가 입력 중간 텍스트를 소유한다. (채택)
장점: IME/커서/attachment와 붙어 있는 로컬 상태를 한 곳에서 처리한다.
단점: 저장 직전 스냅샷 계약을 명시적으로 설계해야 한다.

## 최종 결정

입력 중간 텍스트 소유권은 InputView로 이동하고, Store는 정책/트랜잭션 상태만 소유한다.
Store가 실시간으로 들고 있는 입력 상태는 `isInputEmpty`만 유지한다.

## 반대 의견과 기각 이유

- 반대: Store에 실시간 텍스트를 남겨야 디버깅이 쉽다.
기각 이유: 디버깅 편의보다 조합 입력 안정성이 우선이며, 실시간 텍스트는 UIKit 상태와 분리될수록 불일치 위험이 커진다.

- 반대: InputView가 너무 똑똑해진다.
기각 이유: InputView가 똑똑해지는 범위는 입력 엔진 기술 세부(IME/커서)이며, 도메인 정책 결정은 Store가 계속 소유한다.

## 구현 결과

다음 경계를 적용했다.

- `Store -> View -> InputView` 입력
`inputSeed`, `isEmojiPresentationEnabled`, `MemoInputUICommand`

- `InputView -> View -> Store` 출력
`onDraftAvailabilityChanged`, `onFinalSnapshotReady`, `onFinalSnapshotFailed`

- InputView에서 `MemoStore` 직접 참조 제거
`COMFIE/Presentation/Memo/MemoInput/MemoInputTextView.swift`
`COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView.swift`
`COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Coordinator.swift`
`COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Snapshot.swift`

- MemoView가 중재자 역할 수행
`COMFIE/Presentation/Memo/MemoView.swift`

## 트레이드오프

- Store에서 실시간 본문 문자열을 바로 볼 수는 없다.
- 대신 저장 트랜잭션 흐름(`requestID`, `savePhase`)과 입력 엔진 흐름이 분리되어 변경 영향 범위가 줄었다.

## 회귀 방지 테스트

- `COMFIETests/MemoStoreInputSnapshotTests.swift`
- `COMFIETests/MemoInputIMEInsertionTests.swift`
- `COMFIETests/MemoStoreSavePhaseNavigationTests.swift`
- `COMFIETests/MemoStoreComfieZoneMappingTests.swift`

## 후속 관찰 포인트

- `MemoStoreInputSnapshotTests` 파일 길이 증가(리팩토링 후 700+ 라인)는 추후 테스트 모듈 분할 대상이다.
