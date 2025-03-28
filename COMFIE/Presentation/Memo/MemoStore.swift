//
//  MemoStore.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import Foundation

@Observable
class MemoStore: IntentStore {
    private(set) var state: State = .init()
    
    struct State {
        var memos: [Memo] = []
        // 사용자가 텍스트 필드에 입력하는 메모
        var newMemo: String = ""
    }
    
    enum Intent {
        case showRetrospectionView      // 회고 화면으로
        case comfieZoneSettingButtonTapped
        
        case memoInputButtonTapped
        case updateNewMemo(String)
        case onAppear
    }
    
    enum Action {
        case navigateToRetrospectionView  // 회고 화면으로
        case navigateToComfieZoneSettingView  // 컴피존 설정 화면으로
        case saveMemo
        case fetchMemos
        case setNewMemo(String)
    }
    
    // 화면 전환을 위한 router
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .showRetrospectionView:
            state = handleAction(state, .navigateToRetrospectionView)
        case .comfieZoneSettingButtonTapped:
            state = handleAction(state, .navigateToComfieZoneSettingView)
        case .memoInputButtonTapped:
            state = handleAction(state, .saveMemo)
        case .onAppear:
            state = handleAction(state, .fetchMemos)
        case .updateNewMemo(let newText):
            state = handleAction(state, .setNewMemo(newText))
        }
    }
    
    // State가 불변 상태를 유지할 수 있도록 - 새로운 객체를 생성하여 대체한다
    // 이전 상태와 액션을 입력 받아 새로운 상태를 반환
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        
        switch action {
        case .navigateToRetrospectionView:
            router.push(.retrospection)
        case .navigateToComfieZoneSettingView:
            router.push(.comfieZoneSetting)
        case .saveMemo:
            let newMemo = Memo(
                id: UUID(),
                createdAt: .now,
                originalText: newState.newMemo,
                emojiText: "🐯🐯🐯🐯"
            )
            
            newState.memos.append(newMemo)
            newState.newMemo = ""
        case .fetchMemos:
            // TODO: 이후에 수정 필요
            newState.memos = Memo.sampleMemos
        case .setNewMemo(let text):
            newState.newMemo = text
        }
        return newState
    }
}
