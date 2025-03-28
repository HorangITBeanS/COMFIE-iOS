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
        var inputMemoText: String = ""
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
    private let memoRepository: MemoRepository
    
    init(router: Router, memoRepository: MemoRepository) {
        self.router = router
        self.memoRepository = memoRepository
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
                originalText: newState.inputMemoText,
                emojiText: "🐯🐯🐯🐯"
            )
            
            switch memoRepository.save(memo: newMemo) {
            case .success:
                newState.memos.append(newMemo)
                newState.inputMemoText = ""
            case .failure(let error):
                print("메모 저장 실패: \(error)")
            }

        case .fetchMemos:
            switch memoRepository.fetchAllMemos() {
            case .success(let memos):
                newState.memos = memos
            case .failure(let error):
                print("메모 불러오기 실패: \(error)")
            }
        case .setNewMemo(let text):
            newState.inputMemoText = text
        case .hideKeyboard:
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        case .deleteMemo(let memo):
            switch memoRepository.delete(memo: memo) {
            case .success:
                newState.memos.removeAll { $0.id == memo.id }
            case .failure(let error):
                print("메모 삭제 실패: \(error)")
            }
        case .editMemo(let memo):
            print("edit: \(memo.originalText)")
        }
        return newState
    }
}
