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
    let isEditing: Bool
    
    let isUserInComfieZone: Bool
    
    let isMemoHidden: Bool
    let toggleMemoVisibility: (Memo) -> Void
    
    let onEdit: (Memo) -> Void
    let onRetrospect: (Memo) -> Void
    let onDelete: (Memo) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                
                HStack(spacing: 4) {
                    Text(memo.createdAt.hourAndMinuteString)
                        .comfieFont(.systemBody)
                        .foregroundStyle(Color.textDarkgray)
                    
                    if memo.retrospectionText != nil {
                        Button {
                            withAnimation(.easeIn(duration: 0.2)) {
                                toggleMemoVisibility(memo)
                            }
                        } label: {
                            Image(.icBack)
                                .resizable()
                                .frame(width: 9, height: 14)
                                .rotationEffect(.degrees(isMemoHidden ? 270 : 180))
                        }
                        .padding(.vertical, 1)
                    }
                }
                .padding(.vertical, 2)
                
                Spacer()
                
                menuButton
            }
            .padding(.bottom, 4)
            
            if isMemoHidden || memo.retrospectionText == nil {
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
                    onEdit(memo)
                } label: {
                    Label(strings.editButtonTitle.localized, systemImage: "pencil")
                }
            } else {
                // 회고하기
                Button {
                    onRetrospect(memo)
                } label: {
                    Label(strings.retrospectionButtonTitle.localized, systemImage: "ellipsis.message")
                        .foregroundStyle(.red)
                }
            }
            
            // 삭제하기
            Button(role: .destructive) {
                onDelete(memo)
            } label: {
                Label(strings.deleteButtonTitle.localized, systemImage: "trash")
            }
            
        } label: {
            Image("icEllipsis")
                .frame(width: 19, height: 20)
        }
    }
}

#Preview {
    let memo = Memo.sampleMemos[1]
    var isMemoHidden = false
    
    MemoCell(
        memo: memo,
        isEditing: false,
        isUserInComfieZone: false,
        isMemoHidden: isMemoHidden,
        toggleMemoVisibility: { _ in
            isMemoHidden.toggle()
        },
        onEdit: { _ in
            print("onEdit")
        },
        onRetrospect: { _ in
            print("onRetrospect")
        },
        onDelete: { _ in
            print("onDelete")
        }
    )
}
