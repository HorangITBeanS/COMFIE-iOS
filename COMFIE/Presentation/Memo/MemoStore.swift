//
//  MemoStore.swift
//  COMFIE
//
//  Created by zaehorang on 3/6/25.
//

import UIKit

@Observable
class MemoStore: IntentStore {
    private(set) var state: State = .init()
    
    struct State {
        var memos: [Memo] = []
        // 사용자가 텍스트 필드에 입력하는 메모
        var newMemo: String = ""
    }
    
    enum Intent {
        case comfieZoneSettingButtonTapped
        
        case retrospectionButtonTapped(Memo)
        case deleteMemoButtonTapped(Memo)
        case editMemoButtonTapped(Memo)
        
        case memoInputButtonTapped
        case updateNewMemo(String)
        
        case onAppear
        case onTapGesture
    }
    
    enum Action {
        case navigateToRetrospectionView(Memo)  // 회고 화면으로
        case navigateToComfieZoneSettingView  // 컴피존 설정 화면으로
        case saveMemo
        case fetchMemos
        case deleteMemo(Memo)
        case editMemo(Memo)
        case setNewMemo(String)
        case hideKeyboard
    }
    
    // 화면 전환을 위한 router
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
    
    func handleIntent(_ intent: Intent) {
        switch intent {
        case .retrospectionButtonTapped(let memo):
            state = handleAction(state, .navigateToRetrospectionView(memo))
        case .comfieZoneSettingButtonTapped:
            state = handleAction(state, .navigateToComfieZoneSettingView)
        case .memoInputButtonTapped:
            state = handleAction(state, .saveMemo)
            // 키보드 내리기
            _ = handleAction(state, .hideKeyboard)
        case .onAppear:
            state = handleAction(state, .fetchMemos)
        case .updateNewMemo(let newText):
            state = handleAction(state, .setNewMemo(newText))
        case .onTapGesture:
            _ = handleAction(state, .hideKeyboard)
        case .deleteMemoButtonTapped(let memo):
            state = handleAction(state, .deleteMemo(memo))
        case .editMemoButtonTapped(let memo):
            _ = handleAction(state, .editMemo(memo))
        }
    }
    
    // State가 불변 상태를 유지할 수 있도록 - 새로운 객체를 생성하여 대체한다
    // 이전 상태와 액션을 입력 받아 새로운 상태를 반환
    private func handleAction(_ state: State, _ action: Action) -> State {
        var newState = state
        
        switch action {
        case .navigateToRetrospectionView:
            // TODO: 메모 데이터 주입해주기
            router.push(.retrospection)
            print("회고 화면으로 넘어가기")
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
        case .hideKeyboard:
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        case .deleteMemo(let memo):
            print("delete: \(memo.originalText)")
        case .editMemo(let memo):
            print("edit: \(memo.originalText)")
        }
        return newState
    }
}
