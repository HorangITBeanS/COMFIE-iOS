//
//  MemoRepositoryProtocol.swift
//  COMFIE
//
//  Created by zaehorang on 4/2/25.
//

protocol MemoRepositoryProtocol {
    func save(memo: Memo) -> Result<Void, Error>
    func fetchAllMemos() -> Result<[Memo], Error>
    func update(memo: Memo) -> Result<Void, Error>
    func delete(memo: Memo) -> Result<Void, Error>
    func deleteAll()
}
