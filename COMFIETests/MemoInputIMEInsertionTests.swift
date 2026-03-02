@testable import COMFIE
import CoreLocation
import SwiftUI
import Testing
import UIKit

private struct EmptyComfieZoneRepositoryForIME: ComfieZoneRepositoryProtocol {
    func fetchComfieZone() -> ComfieZone? { nil }
    func saveComfieZone(_ comfieZone: ComfieZone) {}
    func deleteComfieZone() {}
}

private final class StaticLocationUseCaseForIME: LocationUseCase {
    init() {
        super.init(locationService: LocationService(), comfiZoneRepository: EmptyComfieZoneRepositoryForIME())
    }

    override func isInComfieZone(_ location: CLLocation?) -> Bool { false }
}

@MainActor
struct MemoInputIMEInsertionTests {
    // 시나리오: singleCharacterTypingConvertsPreviousCharacterAndDefersCurrentCharacter 동작을 검증합니다.
    @Test func singleCharacterTypingConvertsPreviousCharacterAndDefersCurrentCharacter() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()
        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 0, length: 0),
            replacementText: "a"
        )
        textView.text = "a"
        textView.selectedRange = NSRange(location: 1, length: 0)
        coordinator.textViewDidChange(textView)
        let firstAfterA = textView.textStorage.attribute(.attachment, at: 0, effectiveRange: nil)
        #expect(firstAfterA == nil)

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementText: "b"
        )
        textView.text = "ab"
        textView.selectedRange = NSRange(location: 2, length: 0)
        coordinator.textViewDidChange(textView)
        let firstAfterB = textView.textStorage.attribute(.attachment, at: 0, effectiveRange: nil)
        let secondAfterB = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        #expect(firstAfterB is NSTextAttachment)
        #expect(secondAfterB == nil)

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 2, length: 0),
            replacementText: "c"
        )
        textView.text = "abc"
        textView.selectedRange = NSRange(location: 3, length: 0)
        coordinator.textViewDidChange(textView)
        let secondAfterC = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        let thirdAfterC = textView.textStorage.attribute(.attachment, at: 2, effectiveRange: nil)
        #expect(secondAfterC is NSTextAttachment)
        #expect(thirdAfterC == nil)
        _ = placeholderLabel
    }

    // 시나리오: hangulCompositionConvertsPreviousSyllableWhenNextInputStarts 동작을 검증합니다.
    @Test func hangulCompositionConvertsPreviousSyllableWhenNextInputStarts() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()
        textView.attributedText = NSAttributedString(string: "밖ㅇ")
        textView.selectedRange = NSRange(location: 2, length: 0)

        coordinator.handleMarkedRange(in: textView, marked: NSRange(location: 1, length: 1))

        let firstAttachment = textView.textStorage.attribute(.attachment, at: 0, effectiveRange: nil)
        let secondAttachment = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        #expect(firstAttachment is NSTextAttachment)
        #expect(secondAttachment == nil)
        _ = placeholderLabel
    }

    // 시나리오: middleCursorSingleTypingUsesSameDeferredRule 동작을 검증합니다.
    @Test func middleCursorSingleTypingUsesSameDeferredRule() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()
        textView.text = "ab"

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementText: "x"
        )
        textView.text = "axb"
        textView.selectedRange = NSRange(location: 2, length: 0)
        coordinator.textViewDidChange(textView)

        let firstAfterX = textView.textStorage.attribute(.attachment, at: 0, effectiveRange: nil)
        let insertedX = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        #expect(firstAfterX is NSTextAttachment)
        #expect(insertedX == nil)

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 2, length: 0),
            replacementText: "y"
        )
        textView.text = "axyb"
        textView.selectedRange = NSRange(location: 3, length: 0)
        coordinator.textViewDidChange(textView)

        let xAfterY = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        let insertedY = textView.textStorage.attribute(.attachment, at: 2, effectiveRange: nil)
        #expect(xAfterY is NSTextAttachment)
        #expect(insertedY == nil)
        _ = placeholderLabel
    }

    // 시나리오: singleGraphemeWithMultipleScalarsStillUsesDeferredRule 동작을 검증합니다.
    @Test func singleGraphemeWithMultipleScalarsStillUsesDeferredRule() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()
        let decomposedGrapheme = "e\u{0301}"

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 0, length: 0),
            replacementText: decomposedGrapheme
        )
        textView.text = decomposedGrapheme
        textView.selectedRange = NSRange(location: (decomposedGrapheme as NSString).length, length: 0)
        coordinator.textViewDidChange(textView)

        #expect(attachmentCount(in: textView.textStorage) == 0)

        let appendedText = decomposedGrapheme + "b"
        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: (decomposedGrapheme as NSString).length, length: 0),
            replacementText: "b"
        )
        textView.text = appendedText
        textView.selectedRange = NSRange(location: (appendedText as NSString).length, length: 0)
        coordinator.textViewDidChange(textView)

        #expect(attachmentCount(in: textView.textStorage) == 1)
        let lastAttribute = textView.textStorage.attribute(
            .attachment,
            at: textView.textStorage.length - 1,
            effectiveRange: nil
        )
        #expect(lastAttribute == nil)
        _ = placeholderLabel
    }

    // 시나리오: unicodePunctuationStillFollowsDeferredConversionRule 동작을 검증합니다.
    @Test func unicodePunctuationStillFollowsDeferredConversionRule() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 0, length: 0),
            replacementText: "。"
        )
        textView.text = "。"
        textView.selectedRange = NSRange(location: 1, length: 0)
        coordinator.textViewDidChange(textView)
        let firstAfterPunctuation = textView.textStorage.attribute(.attachment, at: 0, effectiveRange: nil)
        #expect(firstAfterPunctuation == nil)

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementText: "a"
        )
        textView.text = "。a"
        textView.selectedRange = NSRange(location: 2, length: 0)
        coordinator.textViewDidChange(textView)
        let punctuationAfterSecondInput = textView.textStorage.attribute(.attachment, at: 0, effectiveRange: nil)
        let secondCharacterAfterInput = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        #expect(punctuationAfterSecondInput is NSTextAttachment)
        #expect(secondCharacterAfterInput == nil)
        _ = placeholderLabel
    }

    // 시나리오: endEditingFlushesDeferredLastCharacter 동작을 검증합니다.
    @Test func endEditingFlushesDeferredLastCharacter() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 0, length: 0),
            replacementText: "a"
        )
        textView.text = "a"
        textView.selectedRange = NSRange(location: 1, length: 0)
        coordinator.textViewDidChange(textView)

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementText: "b"
        )
        textView.text = "ab"
        textView.selectedRange = NSRange(location: 2, length: 0)
        coordinator.textViewDidChange(textView)

        let secondBeforeEndEditing = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        #expect(secondBeforeEndEditing == nil)

        coordinator.textViewDidEndEditing(textView)

        let secondAfterEndEditing = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        #expect(secondAfterEndEditing is NSTextAttachment)
        _ = placeholderLabel
    }

    // 시나리오: nilFinalSyncRequestDoesNotLeakSkipOnceToNextEndEditing 동작을 검증합니다.
    @Test func nilFinalSyncRequestDoesNotLeakSkipOnceToNextEndEditing() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 0, length: 0),
            replacementText: "a"
        )
        textView.text = "a"
        textView.selectedRange = NSRange(location: 1, length: 0)
        coordinator.textViewDidChange(textView)

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementText: "b"
        )
        textView.text = "ab"
        textView.selectedRange = NSRange(location: 2, length: 0)
        coordinator.textViewDidChange(textView)

        let secondBeforeFinalSync = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        #expect(secondBeforeFinalSync == nil)

        coordinator.textView = nil
        var dynamicHeight: CGFloat = 40
        let dynamicHeightBinding = Binding<CGFloat>(
            get: { dynamicHeight },
            set: { dynamicHeight = $0 }
        )
        coordinator.parent = MemoInputUITextView(
            "placeholder",
            dynamicHeight: dynamicHeightBinding,
            inputSeed: .empty,
            isEmojiPresentationEnabled: true,
            uiCommandEvent: MemoInputUIEvent(command: .requestFinalSyncAndResign(requestID: UUID())),
            onOutputEvent: { _ in }
        )
        coordinator.applyStateToTextView(force: false)

        coordinator.textView = textView
        coordinator.textViewDidEndEditing(textView)

        let secondAfterEndEditing = textView.textStorage.attribute(.attachment, at: 1, effectiveRange: nil)
        #expect(secondAfterEndEditing is NSTextAttachment)
        _ = placeholderLabel
    }

    // 시나리오: plainModeShouldChangeClearsDeferredChangeQueue 동작을 검증합니다.
    @Test func plainModeShouldChangeClearsDeferredChangeQueue() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()
        coordinator.debugInjectChangeForTesting(
            range: NSRange(location: 0, length: 1),
            replacementLength: 2,
            asDeferred: true
        )
        #expect(coordinator.debugHasPendingOrDeferredChangeForTesting())

        var dynamicHeight: CGFloat = 40
        let dynamicHeightBinding = Binding<CGFloat>(
            get: { dynamicHeight },
            set: { dynamicHeight = $0 }
        )
        coordinator.parent = MemoInputUITextView(
            "placeholder",
            dynamicHeight: dynamicHeightBinding,
            inputSeed: .empty,
            isEmojiPresentationEnabled: false,
            uiCommandEvent: nil,
            onOutputEvent: { _ in }
        )
        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 0, length: 0),
            replacementText: "x"
        )
        #expect(!coordinator.debugHasPendingOrDeferredChangeForTesting())

        coordinator.parent = MemoInputUITextView(
            "placeholder",
            dynamicHeight: dynamicHeightBinding,
            inputSeed: .empty,
            isEmojiPresentationEnabled: true,
            uiCommandEvent: nil,
            onOutputEvent: { _ in }
        )
        textView.text = "ab"
        textView.selectedRange = NSRange(location: 2, length: 0)
        coordinator.textViewDidChange(textView)
        #expect(!coordinator.debugHasPendingOrDeferredChangeForTesting())
        _ = placeholderLabel
    }
}

@MainActor
private func makeIMECoordinator() -> (MemoInputUITextView.Coordinator, UITextView, UILabel) {
    var dynamicHeight: CGFloat = 40
    let dynamicHeightBinding = Binding<CGFloat>(
        get: { dynamicHeight },
        set: { dynamicHeight = $0 }
    )
    let parent = MemoInputUITextView(
        "placeholder",
        dynamicHeight: dynamicHeightBinding,
        inputSeed: .empty,
        isEmojiPresentationEnabled: true,
        uiCommandEvent: nil,
        onOutputEvent: { _ in }
    )
    let coordinator = MemoInputUITextView.Coordinator(parent: parent)

    let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
    textView.font = parent.comfieUIBodyFont
    textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 8)
    textView.delegate = coordinator
    coordinator.textView = textView
    let placeholderLabel = UILabel()
    coordinator.placeholderLabel = placeholderLabel

    return (coordinator, textView, placeholderLabel)
}

private func attachmentCount(in storage: NSAttributedString) -> Int {
    guard storage.length > 0 else { return 0 }
    var count = 0
    for index in 0..<storage.length {
        if storage.attribute(.attachment, at: index, effectiveRange: nil) is NSTextAttachment {
            count += 1
        }
    }
    return count
}
