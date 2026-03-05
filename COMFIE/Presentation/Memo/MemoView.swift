//
//  MemoView.swift
//  COMFIE
//
//  Created by zaehorang on 3/23/25.
//

import SwiftUI

struct MemoView: View {
    private let strings = StringLiterals.Memo.self

    @State var intent: MemoStore
    @State private var memoInputUIEvent: MemoInputUIEvent?
    var isUserInComfieZone: Bool {
        intent.state.isInComfieZone
    }

    private var isEditingMemo: Bool {

        intent.state.editingMemo != nil
    }

    var body: some View {
        ZStack {
            Color.keyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .top) {

                    MemoListView(intent: $intent, isUserInComfieZone: isUserInComfieZone)
                        .onTapGesture {
                            intent(.backgroundTapped)
                        }
                        .padding(.top, 56)

                    if isEditingMemo {

                        VStack {
                            Spacer()
                            editingCancelButton
                                .padding(.bottom, 10)
                        }
                    }

                    navigationBarView
                        .onTapGesture {
                            intent(.backgroundTapped)
                        }
                }
                memoInputView
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }

            if intent.state.showTutorial {
                Image(.tutorial)
                    .resizable()
                    .ignoresSafeArea()
                    .onTapGesture {
                        intent(.tutorialTapped)
                    }
            }

            if intent.state.deletingMemo != nil {

                CFPopupView(type: .deleteMemo) {
                    intent(.deletePopup(.confirmDeleteButtonTapped))
                } rightButtonAction: {
                    intent(.deletePopup(.cancelDeleteButtonTapped))
                }
            }
        }
        .onAppear {
            intent(.onAppear)
        }
        .onReceive(intent.uiSideEffectPublisher) { sideEffect in
            memoInputUIEvent = MemoInputUIEvent(command: mapMemoInputUICommand(sideEffect))
        }
    }

    // MARK: - View Property
    private var navigationBarView: some View {
        HStack(spacing: 0) {
            Button {
                intent(.comfieZoneSettingButtonTapped)
            } label: {
                HStack(spacing: 8) {
                    Image(isUserInComfieZone ? .icComfie : .icUncomfie)
                        .resizable()
                        .frame(width: isUserInComfieZone ? 84 : 115, height: 25)
                    Image(.icLocation)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .uiTestAccessibilityIdentifier(AccessibilityID.Memo.comfieZoneSettingButton)
            Spacer()

            Button {
                intent(.moreButtonTapped)
            } label: {
                Image(.icHamburger)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .symbolRenderingMode(.monochrome)
                    .tint(.cfBlack)
            }
            // 릴리즈에서는 no-op이고, Debug UITest 세션에서만 식별자를 부여한다.
            .uiTestAccessibilityIdentifier(AccessibilityID.Memo.moreButton)
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 16)
        .background(.cfWhite)
        .shadow(color: Color.black.opacity(0.04),
                radius: 12,
                x: 0,
                y: 8)
    }

    private var memoInputView: some View {
        HStack(alignment: .top, spacing: 12) {
            MemoInputTextView(
                strings.textfieldPlaceholder.localized,
                inputSeed: intent.state.inputSeed,
                isEmojiPresentationEnabled: intent.state.isEmojiPresentationEnabled,
                uiCommandEvent: memoInputUIEvent,
                onOutputEvent: { outputEvent in
                    intent(.memoInput(mapMemoInputOutputEvent(outputEvent)))
                }
            )

            Button {
                // 저장/수정 버튼 탭을 Store로 전달하면, Store가 final sync 트랜잭션을 시작합니다.
                intent(.memoInput(.memoInputButtonTapped))
            } label: {
                Image(isEditingMemo ? .icCheck : .icSend)
                    .resizable()
                    .foregroundStyle(.cfWhite)
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(
                        intent.state.isInputEmpty
                        ? .keyDeactivated
                        : .keyPrimary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .uiTestAccessibilityIdentifier(AccessibilityID.Memo.sendButton)
            .disabled(intent.state.isInputEmpty)
        }
        .padding(16)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                topTrailingRadius: 16,
                style: .continuous
            )
            .foregroundStyle(.cfWhite)
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: -4)
            .ignoresSafeArea()
        }
    }

    private var editingCancelButton: some View {
        Button {
            intent(.memoCell(.editingCancelButtonTapped))
        } label: {
            Text(strings.editingCancelButtonTitle.localized)
                .comfieFont(.body)
                .foregroundStyle(.destructiveRed)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(.cfWhite)
                .clipShape(RoundedRectangle(cornerRadius: 212))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 0)
        }
        .uiTestAccessibilityIdentifier(AccessibilityID.Memo.editingCancelButton)
    }

    private func mapMemoInputUICommand(_ sideEffect: MemoStore.SideEffect.MemoInput) -> MemoInputUICommand {
        switch sideEffect {
        case .resignInputFocusWithSyncInput:
            return .resignWithSync
        case .resignInputFocusWithoutSync:
            return .resignWithoutSync
        case .requestFinalSyncAndResign(let requestID):
            return .requestFinalSyncAndResign(requestID: requestID)
        case .setMemoInputFocus:
            return .setFocus
        }
    }

    private func mapMemoInputOutputEvent(_ outputEvent: MemoInputOutputEvent) -> MemoStore.Intent.MemoInputIntent {
        switch outputEvent {
        case .draftAvailabilityChanged(let isEmpty):
            return .draftAvailabilityChanged(isEmpty: isEmpty)
        case .finalSnapshotReady(let requestID, let snapshot):
            return .finalSyncCompleted(requestID: requestID, snapshot: snapshot)
        case .finalSnapshotFailed(let requestID):
            return .finalSyncFailed(requestID: requestID)
        }
    }
}

#Preview {
    MemoView(
        intent: MemoStore(
            router: Router(),
            memoRepository: MockMemoRepository(),
            locationUseCase: LocationUseCase(locationService: LocationService(), comfiZoneRepository: ComfieZoneRepository())
        )
    )
}
