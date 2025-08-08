//
//  MemoInputTextView.swift
//  COMFIE
//
//  Created by zaehorang on 4/14/25.
//

import SwiftUI

struct MemoInputTextView: View {
    let placeholder: String
    
    @State private var dynamicHeight: CGFloat = 40
    
    @Binding private var intent: MemoStore

    init(_ placeholder: String = "",
         memoStore: Binding<MemoStore>
    ) {
        self.placeholder = placeholder
        self._intent = memoStore
    }
    
    var body: some View {
        MemoInputUITextView(
            placeholder,
            dynamicHeight: $dynamicHeight,
            intent: $intent)
        .frame(height: dynamicHeight)
    }
}
