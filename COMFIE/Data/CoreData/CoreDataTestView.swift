//
//  CoreDataTestView.swift
//  COMFIE
//
//  Created by zaehorang on 3/19/25.
//

import SwiftUI

struct CoreDataTestView: View {
    let coreDataService = CoreDataService()
    
    // Memo 관련 상태 변수
    @State private var memos: [Memo] = []
    @State private var newMemoText: String = ""
    
    // ComfieZone 관련 상태 변수
    @State private var comfieZone: ComfieZone?
    @State private var newComfieZoneName: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Memo 입력 및 목록
                VStack(alignment: .leading, spacing: 10) {
                    Text("📝 Memo 테스트")
                        .font(.headline)
                    
                    HStack {
                        TextField("새 메모 입력", text: $newMemoText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: addMemo) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                    
                    List {
                        ForEach(memos, id: \.id) { memo in
                            HStack {
                                Text(memo.originalText)
                                Spacer()
                                Button { deleteMemo(id: memo.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // ComfieZone 입력 및 상태 표시
                VStack(alignment: .leading, spacing: 10) {
                    Text("📍 ComfieZone 테스트")
                        .font(.headline)
                    
                    HStack {
                        TextField("새 ComfieZone 이름 입력", text: $newComfieZoneName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button {
                            saveComfieZone()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                    
                    if let zone = comfieZone {
                        Text("현재 ComfieZone: \(zone.name)")
                            .font(.subheadline)
                            .padding(.top, 5)
                        
                        Button {
                            deleteComfieZone()
                        } label: {
                            Text("ComfieZone 삭제")
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("저장된 ComfieZone 없음")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            .navigationTitle("CoreData 테스트")
            .onAppear {
                fetchMemos()
                fetchComfieZone()
            }
        }
    }
    
    // MARK: - Memo 관련 메서드
    private func fetchMemos() {
        let result = coreDataService.getMemos()
        switch result {
        case .success(let fetchedMemos):
            memos = fetchedMemos
        case .failure(let error):
            print("메모 불러오기 실패: \(error)")
        }
    }
    
    private func addMemo() {
        guard !newMemoText.isEmpty else { return }
        
        let newMemo = Memo(id: UUID(), createdAt: .now, originalText: newMemoText, emojiText: "😊", retrospectionText: "회고")
        let result = coreDataService.saveMemo(newMemo)
        
        switch result {
        case .success:
            newMemoText = ""
            fetchMemos()
        case .failure(let error):
            print("메모 저장 실패: \(error)")
        }
    }
    
    private func deleteMemo(id: UUID) {
        let result = coreDataService.deleteMemo(by: id)
        switch result {
        case .success:
            fetchMemos()
        case .failure(let error):
            print("메모 삭제 실패: \(error)")
        }
    }
    
    // MARK: - ComfieZone 관련 메서드
    private func fetchComfieZone() {
        let result = coreDataService.getComfieZone()
        switch result {
        case .success(let zone):
            comfieZone = zone
        case .failure:
            comfieZone = nil
        }
    }
    
    private func saveComfieZone() {
        guard !newComfieZoneName.isEmpty else { return }
        
        let newZone = ComfieZone(id: UUID(), longitude: 1.1, latitude: 1.3, name: newComfieZoneName)
        let result = coreDataService.saveComfieZone(newZone)
        
        switch result {
        case .success:
            newComfieZoneName = ""
            fetchComfieZone()
        case .failure(let error):
            print("ComfieZone 저장 실패: \(error)")
        }
    }
    
    private func deleteComfieZone() {
        coreDataService.deleteAllComfieZone()
        fetchComfieZone()
    }
}

#Preview {
    CoreDataTestView()
}
