//
//  MemoCell.swift
//  COMFIE
//
//  Created by zaehorang on 4/2/25.
//

import SwiftUI

struct MemoCell: View {
    private let strings = StringLiterals.Memo.self
    
    let memo: Memo
    
    @State private var isMemoHidden: Bool = false
    
    @Binding var intent: MemoStore
    
    let isUserInComfieZone: Bool
    
    private var isEditing: Bool {

        intent.state.isEditingMemo(memo)
    }
    
    private var hasRetrospection: Bool {
        memo.originalRetrospectionText != nil
    }
    
    private var shouldShowMemo: Bool {
        !isMemoHidden || !hasRetrospection
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                
                Button {

                    withAnimation(.easeIn(duration: 0.2)) {
                        isMemoHidden.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(memo.createdAt.hourAndMinuteString)
                            .comfieFont(.systemBody)
                            .foregroundStyle(Color.textDarkgray)
                        
                        if hasRetrospection {
                            Image(.icBack)
                                .resizable()
                                .frame(width: 9, height: 14)
                                .padding(.vertical, 1)
                                .rotationEffect(.degrees(isMemoHidden ? 180 : 270))
                        }
                    }
                }
                .padding(.vertical, 2)
                .disabled(!hasRetrospection)
                
                Spacer()
                menuButton
            }
            .padding(.bottom, 4)
            
            if shouldShowMemo {
                Text(isUserInComfieZone ? memo.originalText : memo.emojiText)
                    .comfieFont(.body)
                    .foregroundStyle(Color.textBlack)
                    // 릴리즈에서는 no-op이고, Debug UITest 세션에서만 식별자를 부여한다.
                    .uiTestAccessibilityIdentifier(AccessibilityID.Memo.cellContentText)
            }
            
            if let originalRetrospectionText = memo.originalRetrospectionText,
               let emojiRetrospectionText = memo.emojiRetrospectionText {
                HStack {
                    Text(isUserInComfieZone ? originalRetrospectionText : emojiRetrospectionText)
                        .lineLimit(3)
                    Spacer()
                }
                .comfieFont(.body)
                .foregroundStyle(Color.textBlack)
                .padding(10)
                .background(Color.keyBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 8)
            }
        }
        .padding(12)
        .background(isEditing ? Color.keySecondary : Color.cfWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var menuButton: some View {
        Menu {
            if !isUserInComfieZone {
                Button {
                    intent(.memoCell(.editButtonTapped(memo)))
                } label: {
                    Label(strings.editButtonTitle.localized, systemImage: "pencil")
                }
                .uiTestAccessibilityIdentifier(AccessibilityID.Memo.cellMenuEditButton)
            } else {
                Button {
                    intent(.memoCell(.retrospectionButtonTapped(memo)))
                } label: {
                    Label(strings.retrospectionButtonTitle.localized, systemImage: "ellipsis.message")
                        .foregroundStyle(.red)
                }
                .uiTestAccessibilityIdentifier(AccessibilityID.Memo.cellMenuRetrospectionButton)
            }
            
            Button(role: .destructive) {
                intent(.memoCell(.deleteButtonTapped(memo)))
            } label: {
                Label(strings.deleteButtonTitle.localized, systemImage: "trash")
            }
            .uiTestAccessibilityIdentifier(AccessibilityID.Memo.cellMenuDeleteButton)
            
        } label: {
            Image(.icEllipsis)
                .resizable()
                .frame(width: 19, height: 20)
        }
        .uiTestAccessibilityIdentifier(AccessibilityID.Memo.cellMenuButton)
    }
}

#Preview {
    @Previewable @State var intent = MemoStore(
        router: Router(),
        memoRepository: MockMemoRepository(),
        locationUseCase: LocationUseCase(locationService: LocationService(), comfiZoneRepository: ComfieZoneRepository())
    )
    
    MemoCell(
        memo: intent.state.memos[3],
        intent: $intent,
        isUserInComfieZone: false
    )
}
