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
    let isUserInComfieZone: Bool
    
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
                    ForEach(intent.state.groupedMemos, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.date)
                                .comfieFont(.systemBody)
                                .foregroundStyle(.textDarkgray)
                            
                            ForEach(group.memos) { memo in
                                MemoCell(
                                    memo: memo,
                                    intent: $intent,
                                    isUserInComfieZone: isUserInComfieZone
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
    @Previewable @State var intent = MemoStore(
        router: Router(),
        memoRepository: MockMemoRepository(),
        locationUseCase: LocationUseCase(locationService: LocationService(), comfiZoneRepository: ComfieZoneRepository())
    )
    @Previewable @State var isUserInComfieZone = false
    
    MemoListView(intent: $intent, isUserInComfieZone: isUserInComfieZone)
        .onAppear {
            intent(.onAppear)
        }
}
