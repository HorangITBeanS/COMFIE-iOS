@testable import COMFIE
import CoreLocation
import SwiftUI
import Testing
import UIKit

private final class MemoRepositorySpy: MemoRepositoryProtocol {
    var savedMemos: [Memo] = []
    var updatedMemos: [Memo] = []
    var memos: [Memo] = []

    func save(memo: Memo) -> Result<Void, Error> {
        savedMemos.append(memo)
        memos.append(memo)
        return .success(())
    }

    func fetchAllMemos() -> Result<[Memo], Error> {
        .success(memos)
    }

    func update(memo: Memo) -> Result<Void, Error> {
        updatedMemos.append(memo)
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index] = memo
        }
        return .success(())
    }

    func delete(memo: Memo) -> Result<Void, Error> {
        memos.removeAll { $0.id == memo.id }
        return .success(())
    }

    func deleteAll() {
        memos.removeAll()
    }
}

private struct TestComfieZoneRepository: ComfieZoneRepositoryProtocol {
    func fetchComfieZone() -> ComfieZone? { nil }
    func saveComfieZone(_ comfieZone: ComfieZone) {}
    func deleteComfieZone() {}
}

private final class AlwaysInComfieZoneLocationUseCase: LocationUseCase {
    override func isInComfieZone(_ location: CLLocation?) -> Bool { true }
}

@MainActor
private struct MemoInputCoordinatorHarness {
    let coordinator: MemoInputUITextView.Coordinator
    let textView: UITextView
    let placeholderLabel: UILabel
    let store: MemoStore
}

struct MemoStoreInputSnapshotTests {

    @Test func syncInputSnapshotUpdatesStateAndDomainSnapshot() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        store.handleIntent(.memoInput(.syncInputSnapshot(originalText: "ab", emojiText: "😀b")))

        #expect(store.state.inputOriginalText == "ab")
        #expect(store.state.inputMemoText == "😀b")
        #expect(store.state.emojiString.getOriginalString() == "ab")
        #expect(store.state.emojiString.getEmojiString() == "😀b")
    }

    @Test func saveFinalizesUnconvertedCharactersFromSnapshot() async throws {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository)

        store.handleIntent(.memoInput(.syncInputSnapshot(originalText: "a1", emojiText: "a1")))
        store.handleIntent(.memoInput(.memoInputButtonTapped))

        try await waitUntil(timeoutTick: 40) {
            repository.savedMemos.count == 1
        }

        let savedMemo = try #require(repository.savedMemos.first)
        let savedEmojiCharacters = Array(savedMemo.emojiText)

        #expect(savedMemo.originalText == "a1")
        #expect(savedEmojiCharacters.count == 2)
        #expect(savedEmojiCharacters[0] != "a")
        #expect(savedEmojiCharacters[1] == "1")
        #expect(store.state.inputMemoText.isEmpty)
        #expect(store.state.inputOriginalText.isEmpty)
    }

    @Test func plainModeSnapshotSyncKeepsExistingEmojiForUntouchedCharacters() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository, isInComfieZone: true)

        store.handleIntent(.memoInput(.syncInputSnapshot(originalText: "ab!", emojiText: "😀😃😄")))
        store.handleIntent(.memoInput(.syncInputSnapshot(originalText: "ab!", emojiText: "ab!")))

        #expect(store.state.inputOriginalText == "ab!")
        #expect(store.state.inputMemoText == "😀😃😄")
    }

    @Test func plainModeSnapshotSyncPreservesUntouchedEmojiWhenTextChanges() {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository, isInComfieZone: true)

        store.handleIntent(.memoInput(.syncInputSnapshot(originalText: "abc", emojiText: "😀😃😄")))
        store.handleIntent(.memoInput(.syncInputSnapshot(originalText: "abxc", emojiText: "abxc")))

        #expect(store.state.inputOriginalText == "abxc")
        #expect(store.state.inputMemoText == "😀😃x😄")
    }

    @Test func updateLegacyMismatchMemoNormalizesLengthWithoutCorruptingOriginal() async throws {
        let repository = MemoRepositorySpy()
        let legacyMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "abcd",
            emojiText: "😀😃"
        )
        repository.memos = [legacyMemo]

        let store = makeMemoStore(repository: repository)
        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(legacyMemo)))
        store.handleIntent(.memoInput(.memoInputButtonTapped))

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        #expect(updatedMemo.originalText == "abcd")
        #expect(updatedMemo.emojiText.count == 4)
    }

    @Test func updatedLegacyMemoRemainsNormalizedAfterRefetch() async throws {
        let repository = MemoRepositorySpy()
        let legacyMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "abcd",
            emojiText: "😀😃"
        )
        repository.memos = [legacyMemo]

        let editorStore = makeMemoStore(repository: repository)
        editorStore.handleIntent(.onAppear)
        editorStore.handleIntent(.memoCell(.editButtonTapped(legacyMemo)))
        editorStore.handleIntent(.memoInput(.memoInputButtonTapped))

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let refetchStore = makeMemoStore(repository: repository)
        refetchStore.handleIntent(.onAppear)
        let fetchedMemo = try #require(refetchStore.state.memos.first(where: { $0.id == legacyMemo.id }))

        #expect(fetchedMemo.originalText == "abcd")
        #expect(fetchedMemo.emojiText.count == 4)
        #expect(fetchedMemo.emojiText.hasPrefix("😀😃"))
    }

    @Test func plainModeEditingPreservesExistingEmojiMappingOnUpdate() async throws {
        let repository = MemoRepositorySpy()
        let existingMemo = Memo(
            id: UUID(),
            createdAt: .now,
            originalText: "ab",
            emojiText: "😀😃"
        )
        repository.memos = [existingMemo]

        let store = makeMemoStore(repository: repository, isInComfieZone: true)
        store.handleIntent(.onAppear)
        store.handleIntent(.memoCell(.editButtonTapped(existingMemo)))

        store.handleIntent(.memoInput(.syncInputSnapshot(originalText: "abc", emojiText: "abc")))
        store.handleIntent(.memoInput(.memoInputButtonTapped))

        try await waitUntil(timeoutTick: 40) {
            repository.updatedMemos.count == 1
        }

        let updatedMemo = try #require(repository.updatedMemos.first)
        let emojiCharacters = Array(updatedMemo.emojiText)

        #expect(updatedMemo.originalText == "abc")
        #expect(emojiCharacters.count == 3)
        #expect(emojiCharacters[0] == "😀")
        #expect(emojiCharacters[1] == "😃")
        #expect(emojiCharacters[2] != "c")
    }

    @MainActor
    @Test func imeMarkedRangeConvertsOnlyBeforeComposingRange() {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        textView.attributedText = NSAttributedString(string: "가나")

        coordinator.handleMarkedRange(in: textView, marked: NSRange(location: 1, length: 1))

        let firstAttachment = textView.textStorage.attribute(.attachment, at: 0, effectiveRange: nil)
        let secondAttachment = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)

        #expect(firstAttachment is NSTextAttachment)
        #expect(secondAttachment == nil)
    }

    @MainActor
    @Test func imeMultiCharacterInsertTokenizesInsertedRange() {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        let store = harness.store
        textView.text = "ab"

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 2, length: 0),
            replacementText: "xy"
        )
        textView.text = "abxy"
        textView.selectedRange = NSRange(location: 4, length: 0)

        coordinator.textViewDidChange(textView)

        let secondAttachment = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        let thirdAttachment = textView.textStorage.attribute(.attachment, at: 2, effectiveRange: nil)
        let fourthAttachment = textView.textStorage.attribute(.attachment, at: 3, effectiveRange: nil)

        #expect(secondAttachment is NSTextAttachment)
        #expect(thirdAttachment is NSTextAttachment)
        #expect(fourthAttachment is NSTextAttachment)
        #expect(store.state.inputOriginalText == "abxy")
    }

    @MainActor
    @Test func imeCursorMoveFlushesPendingSingleInsertConversion() {
        let harness = makeMemoInputCoordinator()
        let coordinator = harness.coordinator
        let textView = harness.textView
        let store = harness.store
        textView.text = "ab"

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 2, length: 0),
            replacementText: "c"
        )
        textView.text = "abc"
        textView.selectedRange = NSRange(location: 3, length: 0)

        coordinator.textViewDidChangeSelection(textView)

        let secondAttachment = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)

        #expect(secondAttachment is NSTextAttachment)
        #expect(store.state.inputOriginalText == "abc")
    }

    private func makeMemoStore(repository: MemoRepositoryProtocol, isInComfieZone: Bool = false) -> MemoStore {
        let locationUseCase: LocationUseCase
        if isInComfieZone {
            locationUseCase = AlwaysInComfieZoneLocationUseCase(
                locationService: LocationService(),
                comfiZoneRepository: TestComfieZoneRepository()
            )
        } else {
            locationUseCase = LocationUseCase(
                locationService: LocationService(),
                comfiZoneRepository: TestComfieZoneRepository()
            )
        }

        return MemoStore(
            router: Router(),
            memoRepository: repository,
            locationUseCase: locationUseCase
        )
    }

    @MainActor
    private func makeMemoInputCoordinator(isInComfieZone: Bool = false) -> MemoInputCoordinatorHarness {
        let repository = MemoRepositorySpy()
        let store = makeMemoStore(repository: repository, isInComfieZone: isInComfieZone)

        var dynamicHeight: CGFloat = 40
        let dynamicHeightBinding = Binding<CGFloat>(
            get: { dynamicHeight },
            set: { dynamicHeight = $0 }
        )
        let intentBinding = Binding<MemoStore>(
            get: { store },
            set: { _ in }
        )

        let parent = MemoInputUITextView(
            "placeholder",
            dynamicHeight: dynamicHeightBinding,
            intent: intentBinding
        )
        let coordinator = MemoInputUITextView.Coordinator(parent: parent, intent: intentBinding)
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        textView.font = parent.comfieUIBodyFont
        textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 8)
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        let placeholderLabel = UILabel()
        coordinator.textView = textView
        coordinator.placeholderLabel = placeholderLabel
        let heightConstraint = textView.heightAnchor.constraint(lessThanOrEqualToConstant: 120)
        heightConstraint.isActive = true
        coordinator.textViewHeightConstraint = heightConstraint

        return MemoInputCoordinatorHarness(
            coordinator: coordinator,
            textView: textView,
            placeholderLabel: placeholderLabel,
            store: store
        )
    }

    private func waitUntil(timeoutTick: Int, condition: @escaping () -> Bool) async throws {
        for _ in 0..<timeoutTick {
            if condition() { return }
            await Task.yield()
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        Issue.record("Timed out waiting for async state update")
    }
}
