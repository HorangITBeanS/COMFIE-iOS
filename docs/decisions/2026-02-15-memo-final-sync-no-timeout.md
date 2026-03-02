# 2026-02-15 Memo Final Sync timeout 제거

- Status: Accepted
- Date: 2026-02-15
- Owner: Memo feature team (user + assistant)

## 기존 정책

기존 구현은 저장 버튼 이후 `awaitingFinalSync` 상태에서 timeout을 시작하고,
timeout이 지나면 `idle`로 복귀시키는 방식이었습니다.
또한 late callback 허용/차단을 위한 추가 문맥(`timedOutFinalSyncContext`, draftRevision 비교)이 필요했습니다.

## 문제

- timeout 값 조정 자체가 정책 복잡도를 키웠다.
- timeout과 late callback 규칙이 결합되어 상태 전이 이해가 어려웠다.
- 테스트가 timeout 전제 시나리오에 강하게 묶였다.

## 최종 결정

timeout 기반 복구를 제거하고, 실패를 명시 이벤트로 복구한다.

- 추가 intent: `finalSyncFailed(requestID:)`
- `requestID`가 일치하는 `awaitingFinalSync`에서만 `idle` 복귀
- `requestID` 불일치 실패 이벤트는 무시

## 대체 설계와 기각 이유

1. timeout 유지 + 짧게 조정
기각 이유: 근본 복잡도는 그대로 남고 지연 환경에서 재현성이 떨어진다.

2. timeout 유지 + late callback 전면 허용
기각 이유: stale 응답 반영 위험이 커지고 request 상관관계 의미가 약해진다.

## 구현 반영

- timeout 관련 멤버/로직 제거
`COMFIE/Presentation/Memo/MemoStore.swift`

- 실패 복구 이벤트 추가
`MemoStore.Intent.MemoInputIntent.finalSyncFailed(requestID:)`

- InputView 실패 콜백 경로 추가
`onOutputEvent(.finalSnapshotFailed(requestID:))`

## 운영 리스크 및 관찰 포인트

- InputView가 응답을 보내지 못하는 케이스는 timeout이 아니라 실패 이벤트 경로를 반드시 보내야 한다.
- `requestID` 일치 검증이 유일한 상관관계 장치이므로 테스트에서 계속 보호해야 한다.

## 검증 테스트

- `MemoStoreInputSnapshotTests/finalSyncFailedMatchingRequestIDReturnsIdle()`
- `MemoStoreInputSnapshotTests/finalSyncFailedWithMismatchedRequestIDIsIgnored()`
- `MemoStoreInputSnapshotTests/finalSyncCompletedWithMismatchedRequestIDDoesNotPersist()`
- `MemoStoreInputSnapshotTests/saveTappedTwiceBeforeFinalSyncEmitsSingleRequest()`

## 결과

timeout 제거 후에도 저장 파이프라인은 유지된다.

- `idle -> awaitingFinalSync(requestID) -> persisting -> idle`
- 응답 누락/실패는 `finalSyncFailed(requestID)`로 명시 복구
