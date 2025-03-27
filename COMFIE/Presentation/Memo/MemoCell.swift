import SwiftUI

struct MemoCell: View {
    let memo: Memo
    let isUserInComfieZone: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(
                    memo.createdAt
                        .formatted(
                            Date.FormatStyle()
                                .hour(.twoDigits(amPM: .omitted))
                                .minute(.twoDigits)
                        )
                )
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
                .padding(.bottom, 8)

            // 회고가 없는 경우도 있음
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
