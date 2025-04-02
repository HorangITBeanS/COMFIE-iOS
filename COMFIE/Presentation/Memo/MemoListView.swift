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
    // TODO: isUserInComfieZone 변경 필요
    @Binding var isUserInComfieZone: Bool
    
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
        if intent.state.memos.isEmpty {
            ZStack(alignment: .center) {
                Rectangle()
                    .foregroundStyle(.keyBackground) // 탭 액션을 위해 컬러 추가
                
                Text(strings.emptyMemoDescription.localized)
                    .comfieFont(.body)
                    .foregroundStyle(.textDarkgray)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(groupedMemos, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.date)
                                .comfieFont(.systemBody)
                                .foregroundStyle(.textDarkgray)
                            
                            ForEach(group.memos) { memo in
                                MemoCell(
                                    memo: memo,
                                    isUserInComfieZone: isUserInComfieZone,
                                    onEdit: { memo in
                                        intent(.memoCell(.editButtonTapped(memo)))
                                    },
                                    onRetrospect: { memo in
                                        intent(.memoCell(.retrospectionButtonTapped(memo)))
                                    },
                                    onDelete: { memo in
                                        intent(.memoCell(.deleteButtonTapped(memo)))
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    @Previewable @State var intent = MemoStore(router: Router(), memoRepository: MockMemoRepository())
    @Previewable @State var isUserInComfieZone = false
    
    MemoListView(intent: $intent, isUserInComfieZone: $isUserInComfieZone)
        .onAppear {
            intent(.onAppear)
        }
}
