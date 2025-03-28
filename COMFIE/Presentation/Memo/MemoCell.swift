import SwiftUI

struct MemoCell: View {
    private let strings = StringLiterals.Memo.self
    
    let memo: Memo
    let isUserInComfieZone: Bool
    
    let onEdit: (Memo) -> Void
    let onRetrospect: (Memo) -> Void
    let onDelete: (Memo) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(memo.createdAt.hourAndMinuteString)
                    .comfieFont(.systemBody)
                    .foregroundStyle(Color.textDarkgray)
                
                Spacer()
                
                menuButton
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
    
    private var menuButton: some View {
        Menu {
            Section {
                if !isUserInComfieZone {
                    Button {
                        onEdit(memo)
                    } label: {
                        Label(strings.editButtonTitle.localized, systemImage: "pencil")
                    }
                }
                
                Button {
                    onRetrospect(memo)
                } label: {
                    Label(strings.retrospectionButtonTitle.localized, systemImage: "ellipsis.message")
                        .foregroundStyle(.red)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    onDelete(memo)
                } label: {
                    Label(strings.deleteButtonTitle.localized, systemImage: "trash")
                }
            }
            
        } label: {
            Image("icEllipsis")
                .frame(width: 19, height: 20)
        }
    }
}

#Preview {
    let memo = Memo.sampleMemos[0]
    MemoCell(
        memo: memo,
        isUserInComfieZone: true,
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
