//
//  MemoListView.swift
//  COMFIE
//
//  Created by zaehorang on 3/27/25.
//

import SwiftUI

struct MemoListView: View {
    private let strings = StringLiterals.Memo.self
    
    @Binding var intent: MemoStore
    
    // createdAt 날짜 문자열(dotYMDFormat 기준)로 메모들을 그룹화하고 정렬한 결과
    private var groupedMemos: [(date: String, memos: [Memo])] {
        let grouped = Dictionary(grouping: intent.state.memos) { memo in
            memo.createdAt.dotYMDFormat
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (key, value) in (date: key, memos: value) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groupedMemos, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.date)
                            .comfieFont(.systemBody)
                            .foregroundStyle(.textDarkgray)
                        
                        ForEach(group.memos) { memo in
                            // TODO: isUserInComfieZone 변경 필요
                            MemoCell(
                                memo: memo,
                                isUserInComfieZone: true,
                                onEdit: { memo in
                                    intent(.editMemoButtonTapped(memo))
                                },
                                onRetrospect: { memo in
                                    intent(.retrospectionButtonTapped(memo))
                                },
                                onDelete: { memo in
                                    intent(.deleteMemoButtonTapped(memo))
                                }
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .center) {
            if intent.state.memos.isEmpty {
                Text(strings.emptyMemoDescription.localized)
            }
        }
    }
}

#Preview {
    @Previewable @State var intent = MemoStore(router: Router())
    
    MemoListView(intent: $intent)
        .onAppear {
            intent(.onAppear)
        }
}
