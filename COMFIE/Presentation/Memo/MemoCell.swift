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
    
    @State private var isMemoHidden: Bool = true
    
    @Binding var intent: MemoStore
    
    // TODO: isUserInComfieZone 변경 필요
    let isUserInComfieZone: Bool
    
    private var isEditing: Bool {
        intent.state.isEditingMemo(memo)
    }
    
    private var hasRetrospection: Bool {
        memo.retrospectionText != nil
    }
    
    private var shouldShowMemo: Bool {
        // 회고가 없으면 무조건 메모를 보여주고,
        // 회고가 있는 경우엔 사용자가 펼쳤을 때만 보여준다
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
            }
            
            // 회고가 있는 경우
            if let retrospectionText = memo.retrospectionText {
                HStack {
                    Text(isUserInComfieZone ? retrospectionText : memo.emojiText)
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
                // 수정하기
                Button {
                    intent(.memoCell(.editButtonTapped(memo)))
                } label: {
                    Label(strings.editButtonTitle.localized, systemImage: "pencil")
                }
            } else {
                // 회고하기
                Button {
                    intent(.memoCell(.retrospectionButtonTapped(memo)))
                } label: {
                    Label(strings.retrospectionButtonTitle.localized, systemImage: "ellipsis.message")
                        .foregroundStyle(.red)
                }
            }
            
            // 삭제하기
            Button(role: .destructive) {
                intent(.memoCell(.deleteButtonTapped(memo)))
            } label: {
                Label(strings.deleteButtonTitle.localized, systemImage: "trash")
            }
            
        } label: {
            Image(.icEllipsis)
                .frame(width: 19, height: 20)
        }
    }
}

#Preview {
    @Previewable @State var intent = MemoStore(memoRepository: MockMemoRepository())
    
    MemoCell(
        memo: intent.state.memos[3],
        intent: $intent,
        isUserInComfieZone: false
    )
}
