//
//  MemoRepository.swift
//  COMFIE
//
//  Created by zaehorang on 3/28/25.
//

final class MemoRepository: MemoRepositoryProtocol {
    private let coreDataService: CoreDataService

    init(coreDataService: CoreDataService = CoreDataService()) {
        self.coreDataService = coreDataService
    }

    func save(memo: Memo) -> Result<Void, Error> {
        return coreDataService.saveMemo(memo)
    }

    func fetchAllMemos() -> Result<[Memo], Error> {
        return coreDataService.getMemos()
    }

    func update(memo: Memo) -> Result<Void, Error> {
        return coreDataService.updateMemo(newMemo: memo)
    }

    func delete(memo: Memo) -> Result<Void, Error> {
        return coreDataService.deleteMemo(by: memo.id)
    }

    func deleteAll() {
        coreDataService.deleteAllMemos()
    }
}
