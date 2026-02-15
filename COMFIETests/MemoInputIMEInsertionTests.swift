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
        onDraftAvailabilityChanged: { _, _ in },
        onFinalSnapshotReady: { _, _ in },
        onFinalSnapshotFailed: { _ in }
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
