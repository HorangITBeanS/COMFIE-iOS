# Memo Input Draft SoT Consolidation and Save Boundary Hardening

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document follows `/PLANS.md` from the repository root and must be maintained in accordance with that file.

## Purpose / Big Picture

We started this work because memo input had two competing sources of truth for draft text: the UIKit editor engine (`UITextView` and its `textStorage`, cursor, and IME composition state) and store-level draft fields in `MemoStore.State` (`inputOriginalText`, `inputMemoText`, `emojiString`). That duplication created synchronization loops and made Korean IME handling, cursor stability, and token attachment handling fragile.

After this change, users should be able to type and edit in both emoji mode and ComfieZone plain mode without cursor jumps, without composition breakage, and while preserving existing emoji mappings for unchanged characters. Save and update should still happen through `MemoStore`, but only from an explicit final snapshot transaction.

## Progress

- [x] (2026-02-12 09:58Z) Recorded why this work started and linked it to concrete user-facing failures (dual SoT and sync loops).
- [x] (2026-02-12 09:58Z) Audited current implementation in `COMFIE/Presentation/Memo/MemoStore.swift`, `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Coordinator.swift`, `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Snapshot.swift`, and `COMFIE/Presentation/Memo/MemoView.swift`.
- [x] (2026-02-12 09:58Z) Ran baseline verification: `MemoStoreInputSnapshotTests` passes on iPhone 16 simulator via `xcodebuild test`.
- [x] (2026-02-12 13:35Z) Implemented Milestone 1 contract upgrade: added `MemoInputSnapshot(revision)` payloads, wired coordinator to emit revision-aware events, and kept legacy intent paths for compatibility.
- [x] (2026-02-12 13:35Z) Added regression coverage for revision handling in `COMFIETests/MemoStoreInputSnapshotTests.swift`.
- [x] (2026-02-12 13:35Z) Re-ran focused suites (`MemoStoreInputSnapshotTests`, `EmojiStringTests`, `RetrospectionEmojiMappingTests`) and confirmed pass.
- [x] (2026-02-12 13:38Z) Introduced `state.isInputEmpty` as UI-facing input availability state and switched send/check button enablement in `COMFIE/Presentation/Memo/MemoView.swift` to this field.
- [x] (2026-02-12 13:38Z) Wired editor-to-store availability event in snapshot sync path, keeping legacy draft snapshot writes during migration.
- [x] (2026-02-12 22:43Z) Completed Milestone 2 core move: `MemoInputUITextView.Coordinator` now owns live draft (`draftOriginalText`, `draftEmojiText`, `draftRevision`) and per-keystroke path emits only availability+revision, not full snapshot sync.
- [x] (2026-02-12 22:43Z) Added seed boundary in store/editor contract via `inputSeedVersion`; coordinator re-renders only on seed changes or mode changes, preventing store-driven re-render loops while typing.
- [x] (2026-02-12 22:43Z) Hardened timeout/late-callback behavior with revision-aware availability (`draftAvailabilityChangedWithRevision`) and timed-out request context (`requestID + draftRevision`) in `MemoStore`.
- [x] (2026-02-12 22:46Z) Updated IME coordinator tests to assert coordinator-local draft state instead of store live snapshot state.
- [x] (2026-02-12 22:52Z) Re-ran focused suites and full suite (`xcodebuild test -scheme COMFIE`) with success.
- [x] (2026-02-12 14:00Z) Completed Milestone 3 cleanup scope: removed legacy compatibility memo-input intents and migrated reducer/tests to revision-aware snapshot payloads only.
- [x] (2026-02-12 14:08Z) Completed Milestone 4 cleanup scope: added dedicated availability-path stale-revision test coverage and revalidated focused/full suites (`MemoStoreInputSnapshotTests`, `EmojiStringTests`, `RetrospectionEmojiMappingTests`, full `COMFIE`).
- [x] (2026-02-12 14:40Z) Added manual QA checklist for the two critical scenarios and UI automation smoke tests for memo send + Hangul typing/cursor interaction stability.
- [x] (2026-02-12 14:48Z) Re-validated the newly added Hangul append mapping-preservation unit test in isolation and re-ran the two memo UI smoke tests for final confidence.

## Surprises & Discoveries

- Observation: The codebase already contains a partial transaction design (`savePhase`, `requestFinalSyncAndResign`, timeout, and request ID matching), so the planned direction can be completed incrementally instead of rewritten.
  Evidence: `COMFIE/Presentation/Memo/MemoStore.swift` already models `.awaitingFinalSync(requestID:)` and `.finalSyncCompleted`.

- Observation: Focused tests already exercise many edge cases including late callback after timeout and ComfieZone mapping preservation.
  Evidence: `COMFIETests/MemoStoreInputSnapshotTests.swift` includes tests for timeout recovery, mismatched request IDs, and plain-mode mapping preservation.

- Observation: The full test log shows `MemoStoreInputSnapshotTests` twice in output, but command exits with `** TEST SUCCEEDED **`.
  Evidence: `xcodebuild test -only-testing:COMFIETests/MemoStoreInputSnapshotTests` run on 2026-02-12 completed successfully with xcresult at `/Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_18-57-21-+0900.xcresult`.

- Observation: Swift enum case overloading by same base name caused ambiguous pattern matching during Milestone 1.
  Evidence: Build error `tuple pattern has the wrong length` appeared until cases were renamed to `syncInputSnapshotWithRevision` and `finalSyncCompletedWithRevision`.

- Observation: Expanding dedicated availability-path tests pushed `MemoStoreInputSnapshotTests` above SwiftLint `type_body_length` serious threshold.
  Evidence: build failed with `Type Body Length Violation ... currently spans 633 lines`; resolved by moving shared helpers to file scope so the struct body dropped under the serious threshold.

- Observation: Once coordinator stopped sending per-keystroke snapshot payloads, IME tests that asserted `store.state.inputOriginalText` became boundary-inaccurate and failed.
  Evidence: `MemoStoreInputSnapshotTests/imeMultiCharacterInsertTokenizesInsertedRange` and `.../imeCursorMoveFlushesPendingSingleInsertConversion` failed until assertions were moved to `coordinator.draftOriginalText`.

- Observation: Full-suite run emitted an `xctrunner` launch-denied message for one simulator clone but still completed with `** TEST SUCCEEDED **`.
  Evidence: `xcodebuild test -scheme COMFIE` logged `Failed to launch ... com.HITBS.COMFIE.xctrunner` for clone UDID `4624E86B-...` while all listed test cases passed and exit code was 0.

## Decision Log

- Decision: Keep `MemoStore` as the owner of domain and save transaction state, but not as the owner of live editor draft text.
  Rationale: UIKit IME and cursor state are inherently local to `UITextView`; forcing full external control increases complexity and defect risk.
  Date/Author: 2026-02-12 / Codex + user direction.

- Decision: Use command/event boundaries instead of direct method calls between store and editor.
  Rationale: `Store -> Command` and `Editor -> Event` keeps ownership and ordering explicit, avoids tight coupling, and supports request ID matching.
  Date/Author: 2026-02-12 / Codex + user direction.

- Decision: Preserve existing behavior during migration by introducing compatibility layers first.
  Rationale: Current tests are strong and should remain green while ownership is shifted; this lowers rollout risk.
  Date/Author: 2026-02-12 / Codex.

- Decision: Use uniquely named revision-aware intents instead of overloading enum case names.
  Rationale: Swift pattern matching became ambiguous with overloaded case base names, while explicit names were stable and clearer in call sites.
  Date/Author: 2026-02-12 / Codex.

- Decision: Decouple button enablement from store draft text early via `isInputEmpty`, while preserving draft snapshot compatibility for now.
  Rationale: This provides immediate boundary cleanup with low risk and prepares Milestone 2/3 without a full behavior break.
  Date/Author: 2026-02-12 / Codex.

- Decision: Introduce `inputSeedVersion` separate from `inputSnapshotRevision`.
  Rationale: Seed-change detection and draft-revision tracking must be independent; otherwise availability revisions could trigger unintended store-driven text re-renders.
  Date/Author: 2026-02-12 / Codex.

- Decision: Keep legacy snapshot intents in `MemoStore` while moving coordinator typing flow off snapshot sync.
  Rationale: This preserves existing tests/callers during migration and allows incremental cleanup without breaking save/update transaction behavior.
  Date/Author: 2026-02-12 / Codex.

- Decision: Use availability+revision events to guard late timeout completion acceptance.
  Rationale: After removing per-keystroke text payload sync, revision is the minimal deterministic signal for stale-callback invalidation.
  Date/Author: 2026-02-12 / Codex.

- Decision: Keep `inputOriginalText`/`inputMemoText` as editor seed and persist sources for now, while removing only legacy intent compatibility paths.
  Rationale: Seed/reset and commit flows still require deterministic store-side values; dropping these fields in the same refactor would increase rollback risk without user-visible value.
  Date/Author: 2026-02-12 / Codex.

## Outcomes & Retrospective

Milestone 2-4 outcome: live draft ownership is now in `MemoInputUITextView.Coordinator` for typing/IME/cursor flows, store communication during editing is availability+revision plus explicit final snapshot completion, and legacy memo-input compatibility intents have been removed. Save/update still commit through `MemoStore` transaction boundaries (`requestID`, timeout, late-callback rules), and focused/full suites pass after boundary-aware test updates.

Current intentional boundary: store-held `inputOriginalText`/`inputMemoText` remain as seed/reset + persist payload state, while live per-keystroke draft SoT stays in coordinator-local state.

## Context and Orientation

`MemoStore` is the intent/action reducer class in `COMFIE/Presentation/Memo/MemoStore.swift`. It owns domain state, transaction state (`savePhase`), seed snapshot state for editor rehydration (`inputOriginalText`, `inputMemoText`, `inputSeedVersion`), and commit persistence behavior.

`MemoInputUITextView.Coordinator` in `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Coordinator.swift` is the UIKit delegate adapter used by SwiftUI. It handles IME composition, token attachment rendering, focus side effects, and snapshot extraction from `textStorage`.

`MemoInputUITextView+Snapshot.swift` now keeps local draft updates (`updateDraft`) and sends only draft availability+revision events during typing. Final text payload is sent only on explicit final-sync request.

`MemoView` in `COMFIE/Presentation/Memo/MemoView.swift` enables/disables the send/check button by reading `intent.state.isInputEmpty`, which is fed from editor availability events.

For this plan:

- A "draft" means in-progress editor text state that can still change by typing, cursor movement, IME composition, and attachment conversion.
- A "final snapshot" means immutable `(originalText, emojiText, revision)` captured for a specific save/update request.
- "ComfieZone plain mode" means `state.isInComfieZone == true`, where the view renders plain original text but must preserve prior emoji mapping for unchanged characters.

## Plan of Work

Milestone 1 introduces explicit interfaces without removing old behavior yet. Add a typed snapshot payload and typed editor command/event messages in `MemoStore` and `MemoInputUITextView` so transaction boundaries are explicit. Continue passing current tests.

Milestone 2 moves live draft ownership into `MemoInputUITextView.Coordinator`. The coordinator should keep local draft fields and a monotonically increasing local revision counter. It should update local draft on IME and text edits, and only send summary events needed by store (for example, "hasDraftText changed" and "final snapshot completed").

Milestone 3 removes compatibility paths in `MemoStore` intent/action handling. The reducer keeps revision-aware snapshot payloads only and treats `inputOriginalText`/`inputMemoText` as seed/reset + persist sources, not as live per-keystroke draft ownership.

Milestone 4 expands and adjusts tests. Keep existing tests that assert final-sync behavior, timeout behavior, and mapping preservation, and add explicit coverage for out-of-order callbacks after availability revision changes and for send-button enablement via availability events.

## Concrete Steps

Run all commands from `/Users/zaehorang/Documents/Projects/COMFIE-iOS`.

1. Capture current baseline tests before refactor:

       xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/MemoStoreInputSnapshotTests

   Expected result includes:

       ** TEST SUCCEEDED **

2. Implement Milestone 1 interfaces in:

   - `COMFIE/Presentation/Memo/MemoStore.swift`
   - `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Coordinator.swift`
   - `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Snapshot.swift`

   Then rerun the same focused test command and fix regressions before continuing.

3. Implement Milestones 2 and 3, then run:

       xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/MemoStoreInputSnapshotTests
       xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/EmojiStringTests
       xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/RetrospectionEmojiMappingTests

4. When focused suites pass, run full tests for confidence:

       xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'

## Validation and Acceptance

Acceptance is behavioral:

- In normal emoji mode, typing convertible characters keeps attachment rendering and does not corrupt original text on save.
- In ComfieZone plain mode, editing unchanged segments preserves previous emoji mapping after save/update.
- Save button behavior remains correct after store draft removal: disabled when editor draft is empty, enabled when non-empty.
- Save/update only happens after matching `requestID` final snapshot event and ignores mismatched or stale events.
- If final snapshot callback is delayed past timeout, behavior follows explicit rule: either accept late callback only when draft/revision unchanged, or ignore with deterministic tests.

Validation evidence must include passing test output and at least one manual simulator check:

- Edit an existing memo in ComfieZone mode, append one character, save, and verify first characters keep prior emoji mapping.
- Type Korean with IME and move cursor; verify no composition crash and no forced text reset during marked text.

## Idempotence and Recovery

The plan is safe to run repeatedly because each milestone is additive and validated with tests before removing old paths. If a milestone fails tests, keep compatibility code and revert only the latest edits in touched files instead of resetting the entire branch. If simulator state becomes unstable, rerun with a fresh simulator boot and the same test command.

If migration is partially applied and send button logic breaks, temporary recovery is to keep a compatibility event that mirrors `hasDraftText` to store while draft text remains local to coordinator. Remove that compatibility path only after tests and manual checks pass.

## Artifacts and Notes

Baseline test run (2026-02-12):

    Command:
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/MemoStoreInputSnapshotTests

    Key output:
    ** TEST SUCCEEDED **
    Test suite 'MemoStoreInputSnapshotTests' ... passed
    xcresult: /Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_18-57-21-+0900.xcresult

Milestone 2 verification run (2026-02-12):

    Command:
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/MemoStoreInputSnapshotTests

    Key output:
    ** TEST SUCCEEDED **
    xcresult: /Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_22-48-32-+0900.xcresult

Focused dependency runs (2026-02-12):

    Commands:
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/EmojiStringTests
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/RetrospectionEmojiMappingTests

    Key output:
    ** TEST SUCCEEDED **

Full suite confidence run (2026-02-12):

    Command:
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'

    Key output:
    ** TEST SUCCEEDED **
    Note: one simulator clone logged a temporary `com.HITBS.COMFIE.xctrunner` launch denial, but the final test command exit code remained 0 and test cases completed.

Milestone 3/4 cleanup verification runs (2026-02-12):

    Commands:
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/MemoStoreInputSnapshotTests
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/EmojiStringTests
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/RetrospectionEmojiMappingTests
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'

    Key output:
    ** TEST SUCCEEDED **
    MemoStoreInputSnapshotTests xcresult: /Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_23-03-44-+0900.xcresult
    RetrospectionEmojiMappingTests xcresult: /Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_23-05-04-+0900.xcresult
    Full suite xcresult: /Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_23-05-44-+0900.xcresult

UI automation run (2026-02-12):

    Command:
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIEUITests/COMFIEUITests/testMemoInputSendCreatesNewMemoCell -only-testing:COMFIEUITests/COMFIEUITests/testHangulTypingAndCursorTapKeepsInputInteractive

    Key output:
    ** TEST SUCCEEDED **
    xcresult: /Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_23-40-13-+0900.xcresult

Additional confidence reruns (2026-02-12):

    Command:
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIETests/MemoStoreInputSnapshotTests/plainModeAppendingHangulCharacterPreservesExistingEmojiMappingOnUpdate

    Key output:
    ** TEST SUCCEEDED **
    xcresult: /Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_23-47-05-+0900.xcresult

    Command:
    xcodebuild test -project COMFIE.xcodeproj -scheme COMFIE -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -only-testing:COMFIEUITests/COMFIEUITests/testMemoInputSendCreatesNewMemoCell -only-testing:COMFIEUITests/COMFIEUITests/testHangulTypingAndCursorTapKeepsInputInteractive

    Key output:
    ** TEST SUCCEEDED **
    xcresult: /Users/zaehorang/Library/Developer/Xcode/DerivedData/COMFIE-etlkvyuqyqnzgqezwxfcunjfudak/Logs/Test/Test-COMFIE-2026.02.12_23-47-42-+0900.xcresult

Manual checklist artifact:

    docs/qa/memo-input-manual-validation.md

## Interfaces and Dependencies

In `COMFIE/Presentation/Memo/MemoStore.swift`, keep explicit payload and transaction boundary types:

    struct MemoInputSnapshot: Equatable {
        let originalText: String
        let emojiText: String
        let revision: Int
    }

    enum MemoInputIntent {
        case draftAvailabilityChangedWithRevision(isEmpty: Bool, revision: Int)
        case syncInputSnapshotWithRevision(MemoInputSnapshot)
        case memoInputButtonTapped
        case finalSyncCompletedWithRevision(requestID: UUID, snapshot: MemoInputSnapshot)
        case finalSyncTimedOut(requestID: UUID)
    }

    struct TimedOutFinalSyncContext {
        let requestID: UUID
        let draftRevision: Int
    }

Store must track `inputSeedVersion` separately from `inputSnapshotRevision`. Seed version drives editor rehydrate/clear, while snapshot revision tracks latest known draft revision for timeout-late-callback safety.

In `COMFIE/Presentation/Memo/MemoInput/MemoInputUITextView+Coordinator.swift`, keep local draft and revision:

    final class Coordinator: NSObject, UITextViewDelegate {
        private var draftOriginalText: String
        private var draftEmojiText: String
        private var draftRevision: Int
        private var lastAppliedInputSeedVersion: Int
    }

`EmojiString.mergedEmojiTextPreservingUnchanged` in `COMFIE/Domain/TextToEmoji/Model/EmojiString.swift` remains the canonical merge function for plain-mode mapping preservation. Do not duplicate this algorithm in the store reducer.

Revision Note (2026-02-12 09:58Z): Initial ExecPlan created to record why the work started and to define an incremental migration path from dual SoT to editor-owned draft SoT with transaction-based persistence.
Revision Note (2026-02-12 13:35Z): Milestone 1 completed with code and tests; added revision-aware snapshot contracts, noted enum-overload ambiguity, and updated progress/evidence sections.
Revision Note (2026-02-12 13:38Z): Added intermediate boundary cleanup (`isInputEmpty` + availability event), documented SwiftLint type-length constraint discovered during test expansion, and refined remaining Milestone 3 scope.
Revision Note (2026-02-12 22:52Z): Completed Milestone 2 core ownership move (coordinator live draft + availability/revision events), hardened timeout-late-callback handling with revision context, updated IME tests to boundary-correct assertions, and revalidated with focused/full test runs.
Revision Note (2026-02-12 14:08Z): Completed Milestone 3/4 scoped cleanup by removing legacy memo-input intents, adding availability-path stale-revision tests, and re-running focused/full suites to green.
Revision Note (2026-02-12 14:40Z): Added UI-test launch stabilization (`-ui-testing`), memo screen accessibility identifiers, two UI smoke tests for send/Hangul cursor interaction, and a manual QA checklist artifact.
Revision Note (2026-02-12 14:48Z): Re-ran the new Hangul append mapping-preservation unit test in isolation and re-ran memo UI smoke tests to lock in manual-checklist critical paths with fresh evidence.
