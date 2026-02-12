@testable import COMFIE
import CoreLocation
import Testing

private struct EmptyComfieZoneRepository: ComfieZoneRepositoryProtocol {
    func fetchComfieZone() -> ComfieZone? { nil }
    func saveComfieZone(_ comfieZone: ComfieZone) {}
    func deleteComfieZone() {}
}

private final class StaticComfieZoneLocationUseCase: LocationUseCase {
    init() {
        super.init(locationService: LocationService(), comfiZoneRepository: EmptyComfieZoneRepository())
    }

    override func isInComfieZone(_ location: CLLocation?) -> Bool { true }
}

@MainActor
struct MemoStoreSavePhaseNavigationTests {
    @Test func retrospectionTapIsIgnoredWhileSaveInProgress() {
        let router = Router()
        let store = MemoStore(
            router: router,
            memoRepository: MockMemoRepository(),
            locationUseCase: StaticComfieZoneLocationUseCase()
        )
        let memo = Memo(id: UUID(), createdAt: .now, originalText: "a", emojiText: "😀")

        store.handleIntent(.memoInput(.draftAvailabilityChangedWithRevision(isEmpty: false, revision: 1)))
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        guard case .awaitingFinalSync = store.state.savePhase else {
            Issue.record("savePhase should be awaitingFinalSync before navigation guard check")
            return
        }

        store.handleIntent(.memoCell(.retrospectionButtonTapped(memo)))

        #expect(router.path.isEmpty)
    }
}
