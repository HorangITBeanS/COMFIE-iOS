//
//  ComfieZoneRepository.swift
//  COMFIE
//
//  Created by Anjin on 5/26/25.
//

import Foundation

final class ComfieZoneRepository: ComfieZoneRepositoryProtocol {
    private let coreDataService: CoreDataService

    init(coreDataService: CoreDataService = CoreDataService()) {
        self.coreDataService = coreDataService
    }

    func fetchComfieZone() -> ComfieZone? {
        let result = coreDataService.getComfieZone()
        switch result {
        case .success(let comfieZone):
            return comfieZone
        case .failure(let error):
            // FIXME: 현재 컴피존이 없으면 error 반환 -> 컴피존이 없는 것과 오류를 분명하게 분리할 것
            return nil
        }
    }
    
    func saveComfieZone(_ comfieZone: ComfieZone) {
        let result = coreDataService.saveComfieZone(comfieZone)
        switch result {
        case .success:
            print("\(#function) success")
        case .failure(let failure):
            print("\(#function) fail \(failure)")
        }
    }
    
    func deleteComfieZone() {
        coreDataService.deleteAllComfieZone()
    }
}
