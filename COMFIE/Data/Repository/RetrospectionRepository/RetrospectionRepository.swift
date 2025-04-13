//
//  RetrospectionRepository.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 4/13/25.
//

final class RetrospectionRepository: RetrospectionRepsitoryProtocol {
    private let coreDataService: CoreDataService
    
    init(coreDataService: CoreDataService = CoreDataService()) {
        self.coreDataService = coreDataService
    }
    
    func update(memo: Memo) -> Result<Void, any Error> {
        coreDataService.saveRetrospection(memo)
    }
    
    func delete(memo: Memo) -> Result<Void, any Error> {
        coreDataService.deleteRetrospectionText(for: memo)
    }
}
