//
//  MemoView.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import SwiftUI

struct MemoView: View {
    @State var intent: MemoStore
    
    var body: some View {
        Text("메모 View")
        
        Button {
            intent(.showRetrospectionView)
        } label: {
            Text("회고 화면으로")
        }
        
        Button {
            intent(.showComfieZoneSettingView)
        } label: {
            Text("컴피존 설정 화면으로")
        }
    }
}

#Preview {
    MemoView(
        intent: MemoStore(
            router: Router()
        )
    )
}
