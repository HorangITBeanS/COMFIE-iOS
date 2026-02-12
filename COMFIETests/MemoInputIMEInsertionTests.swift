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
    @Test func singleCharacterInsertTokenizesInsertedCharacterOnChange() {
        let (coordinator, textView, placeholderLabel) = makeIMECoordinator()
        textView.text = "ab"

        _ = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 2, length: 0),
            replacementText: "c"
        )
        textView.text = "abc"
        textView.selectedRange = NSRange(location: 3, length: 0)
        coordinator.textViewDidChange(textView)

        let insertedAttachment = textView.textStorage.attribute(.attachment, at: 2, effectiveRange: nil)
        #expect(insertedAttachment is NSTextAttachment)
        _ = placeholderLabel
    }
}

@MainActor
private func makeIMECoordinator() -> (MemoInputUITextView.Coordinator, UITextView, UILabel) {
    let store = MemoStore(
        router: Router(),
        memoRepository: MockMemoRepository(),
        locationUseCase: StaticLocationUseCaseForIME()
    )

    var dynamicHeight: CGFloat = 40
    let dynamicHeightBinding = Binding<CGFloat>(
        get: { dynamicHeight },
        set: { dynamicHeight = $0 }
    )
    let intentBinding = Binding<MemoStore>(get: { store }, set: { _ in })
    let parent = MemoInputUITextView("placeholder", dynamicHeight: dynamicHeightBinding, intent: intentBinding)
    let coordinator = MemoInputUITextView.Coordinator(parent: parent, intent: intentBinding)

    let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
    textView.font = parent.comfieUIBodyFont
    textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 8)
    textView.delegate = coordinator
    coordinator.textView = textView
    let placeholderLabel = UILabel()
    coordinator.placeholderLabel = placeholderLabel

    return (coordinator, textView, placeholderLabel)
}
