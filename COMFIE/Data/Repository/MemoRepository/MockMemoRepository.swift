//
//  MockMemoRepository.swift
//  COMFIE
//
//  Created by zaehorang on 4/2/25.
//

import Foundation

final class MockMemoRepository: MemoRepositoryProtocol {
    private var mockMemos: [Memo] = Memo.sampleMemos

    func save(memo: Memo) -> Result<Void, Error> {
        mockMemos.append(memo)
        return .success(())
    }

    func fetchAllMemos() -> Result<[Memo], Error> {
        return .success(mockMemos)
    }

    func update(memo: Memo) -> Result<Void, Error> {
        if let index = mockMemos.firstIndex(where: { $0.id == memo.id }) {
            mockMemos[index] = memo
            return .success(())
        }
        return .failure(NSError(domain: "MockMemoRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Memo not found."]))
    }

    func delete(memo: Memo) -> Result<Void, Error> {
        mockMemos.removeAll { $0.id == memo.id }
        return .success(())
    }

    func deleteAll() {
        mockMemos.removeAll()
    }
}
