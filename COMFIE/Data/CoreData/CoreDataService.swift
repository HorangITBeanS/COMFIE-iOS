//
//  CoreDataService.swift
//  COMFIE
//
//  Created by zaehorang on 3/10/25.
//

import CoreData

struct CoreDataService {
    let persistentContainer: NSPersistentCloudKitContainer
    
    init() {
        persistentContainer = NSPersistentCloudKitContainer(name: "UserRecordModel")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}

// MARK: - CREATE
extension CoreDataService {
    func saveComfieZone(_ comfieZone: ComfieZone) -> Result<Void, Error> {
        _ = ComfieZone
            .toEntity(
                context: self.context,
                comfieZone: comfieZone
            )
        do {
            try self.context.save()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func saveMemo(_ memo: Memo) -> Result<Void, Error> {
        _ = Memo
            .toEntity(
                context: self.context,
                memo: memo
            )
        
        do {
            try self.context.save()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - READ
extension CoreDataService {
    func getMemos() -> Result<[Memo], Error> {
        let request: NSFetchRequest<MemoEntity> = MemoEntity.fetchRequest()
        
        do {
            let entities = try self.context.fetch(request)
            let memos = try entities.map {
                try Memo.fromEntity($0).get()
            }
            return .success(memos)
        } catch {
            return .failure(error)
        }
    }
    
    func getComfieZone() -> Result<ComfieZone, Error> {
        let request: NSFetchRequest<ComfieZoneEntity> = ComfieZoneEntity.fetchRequest()
        
        do {
            // 현재 로직상 comfieZone은 한 개
            guard let entity = try self.context.fetch(request).first else {
                return .failure(CoreDataError.entityNotFound)
            }
            let comfieZone = try ComfieZone.fromEntity(entity).get()
            return .success(comfieZone)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - DELETE
extension CoreDataService {
    func deleteMemo(by id: UUID) -> Result<Void, Error> {
        let request: NSFetchRequest<MemoEntity> = MemoEntity.fetchRequest()
        
        // id를 기준으로 데이터를 필터링
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let memos = try context.fetch(request)
            guard let memo = memos.first else {
                return .failure(CoreDataError.deleteFailed)
            }
            
            self.context.delete(memo)
            
            // context 저장
            do {
                try self.context.save()
                return .success(())
            } catch {
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
    
    func deleteAllMemos() {
        let request: NSFetchRequest<NSFetchRequestResult> = MemoEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest) // 모든 레코드 삭제
            try context.save()
            print("All memo records deleted successfully.")
        } catch {
            print("Failed to delete all memo records: \(error)")
        }
    }
    
    func deleteAllComfieZone() {
        let request: NSFetchRequest<NSFetchRequestResult> = ComfieZoneEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest) // 모든 레코드 삭제
            try context.save()
            print("All comfieZone records deleted successfully.")
        } catch {
            print("Failed to delete all comfieZone records: \(error)")
        }
    }
}
