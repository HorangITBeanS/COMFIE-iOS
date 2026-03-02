import Combine
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
    // 시나리오: retrospectionTapIsIgnoredWhileSaveInProgress 동작을 검증합니다.
    @Test func retrospectionTapIsIgnoredWhileSaveInProgress() {
        let router = Router()
        let store = MemoStore(
            router: router,
            memoRepository: MockMemoRepository(),
            locationUseCase: StaticComfieZoneLocationUseCase()
        )
        let memo = Memo(id: UUID(), createdAt: .now, originalText: "a", emojiText: "😀")

        store.handleIntent(.memoInput(.draftAvailabilityChanged(isEmpty: false)))
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        guard case .awaitingFinalSync = store.state.savePhase else {
            Issue.record("savePhase should be awaitingFinalSync before navigation guard check")
            return
        }

        store.handleIntent(.memoCell(.retrospectionButtonTapped(memo)))

        #expect(router.path.isEmpty)
    }

    // 시나리오: deleteTapIsIgnoredWhileSaveInProgress 동작을 검증합니다.
    @Test func deleteTapIsIgnoredWhileSaveInProgress() {
        let store = MemoStore(
            router: Router(),
            memoRepository: MockMemoRepository(),
            locationUseCase: StaticComfieZoneLocationUseCase()
        )
        let memo = Memo(id: UUID(), createdAt: .now, originalText: "a", emojiText: "😀")

        store.handleIntent(.memoInput(.draftAvailabilityChanged(isEmpty: false)))
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        guard case .awaitingFinalSync = store.state.savePhase else {
            Issue.record("savePhase should be awaitingFinalSync before delete guard check")
            return
        }

        store.handleIntent(.memoCell(.deleteButtonTapped(memo)))

        #expect(store.state.deletingMemo == nil)
    }

    // 시나리오: comfieZoneSettingTapIsIgnoredWhileSaveInProgress 동작을 검증합니다.
    @Test func comfieZoneSettingTapIsIgnoredWhileSaveInProgress() {
        let router = Router()
        let store = MemoStore(
            router: router,
            memoRepository: MockMemoRepository(),
            locationUseCase: StaticComfieZoneLocationUseCase()
        )

        store.handleIntent(.memoInput(.draftAvailabilityChanged(isEmpty: false)))
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        guard case .awaitingFinalSync = store.state.savePhase else {
            Issue.record("savePhase should be awaitingFinalSync before comfieZoneSetting guard check")
            return
        }

        store.handleIntent(.comfieZoneSettingButtonTapped)

        #expect(router.path.isEmpty)
    }

    // 시나리오: moreTapIsIgnoredWhileSaveInProgress 동작을 검증합니다.
    @Test func moreTapIsIgnoredWhileSaveInProgress() {
        let router = Router()
        let store = MemoStore(
            router: router,
            memoRepository: MockMemoRepository(),
            locationUseCase: StaticComfieZoneLocationUseCase()
        )

        store.handleIntent(.memoInput(.draftAvailabilityChanged(isEmpty: false)))
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        guard case .awaitingFinalSync = store.state.savePhase else {
            Issue.record("savePhase should be awaitingFinalSync before more guard check")
            return
        }

        store.handleIntent(.moreButtonTapped)

        #expect(router.path.isEmpty)
    }

    // 시나리오: backgroundTapIsIgnoredWhileSaveInProgress 동작을 검증합니다.
    @Test func backgroundTapIsIgnoredWhileSaveInProgress() {
        let store = MemoStore(
            router: Router(),
            memoRepository: MockMemoRepository(),
            locationUseCase: StaticComfieZoneLocationUseCase()
        )
        var cancellables = Set<AnyCancellable>()
        var resignSideEffectCount = 0

        store.uiSideEffectPublisher
            .sink { sideEffect in
                if case .resignInputFocusWithSyncInput = sideEffect {
                    resignSideEffectCount += 1
                }
            }
            .store(in: &cancellables)

        store.handleIntent(.memoInput(.draftAvailabilityChanged(isEmpty: false)))
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        guard case .awaitingFinalSync = store.state.savePhase else {
            Issue.record("savePhase should be awaitingFinalSync before background tap guard check")
            return
        }

        store.handleIntent(.backgroundTapped)

        #expect(resignSideEffectCount == 0)
        _ = cancellables
    }

    // 시나리오: confirmDeletePopupIsIgnoredWhileSaveInProgress 동작을 검증합니다.
    @Test func confirmDeletePopupIsIgnoredWhileSaveInProgress() {
        let store = MemoStore(
            router: Router(),
            memoRepository: MockMemoRepository(),
            locationUseCase: StaticComfieZoneLocationUseCase()
        )
        let memo = Memo(id: UUID(), createdAt: .now, originalText: "a", emojiText: "😀")

        store.handleIntent(.memoCell(.deleteButtonTapped(memo)))
        #expect(store.state.deletingMemo?.id == memo.id)

        store.handleIntent(.memoInput(.draftAvailabilityChanged(isEmpty: false)))
        store.handleIntent(.memoInput(.memoInputButtonTapped))
        guard case .awaitingFinalSync = store.state.savePhase else {
            Issue.record("savePhase should be awaitingFinalSync before popup confirm guard check")
            return
        }

        store.handleIntent(.deletePopup(.confirmDeleteButtonTapped))

        #expect(store.state.deletingMemo?.id == memo.id)
    }
}
