import SwiftUI

struct MemoCell: View {
    let memo: Memo
    let isUserInComfieZone: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(memo.createdAt.hourAndMinuteString)
                    .comfieFont(.systemBody)
                    .foregroundStyle(Color.textDarkgray)
                
                Spacer()
                
                Button {
                    // TODO: 옵션 기능 추가 예정
                } label: {
                    Image("icEllipsis")
                        .frame(width: 19, height: 20)
                }
            }
            .padding(.bottom, 4)
            
            Text(isUserInComfieZone ? memo.originalText : memo.emojiText)
                .comfieFont(.body)
                .foregroundStyle(Color.textBlack)
            
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 8)
            }
        }
        .padding(12)
        .background(Color.cfWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let memo = Memo(
        id: UUID(),
        createdAt: .now,
        originalText: "ddd",
        emojiText: "ddd",
        retrospectionText: "ddddddddddddddddddddddddddddddddddddd\ndddddddddddddddddddddddddddddddddddddddddddddddddddddd"
    )
    MemoCell(memo: memo, isUserInComfieZone: true)
}
