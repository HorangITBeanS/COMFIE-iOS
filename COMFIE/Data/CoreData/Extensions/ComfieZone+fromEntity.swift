//
//  ComfieZone+fromEntity.swift
//  COMFIE
//
//  Created by zaehorang on 3/11/25.
//

import CoreData

extension ComfieZone {
    static func fromEntity(_ entity: ComfieZoneEntity) -> Result<ComfieZone, Error> {
        guard
            let id = entity.id,
            let name = entity.name
        else {
            return .failure(CoreDataError.mapFromEntityFailed)
        }
        let (latitude, longitude) = (entity.latitude, entity.longitude)
        
        let comfieZone = ComfieZone(
            id: id,
            longitude: longitude,
            latitude: latitude,
            name: name
        )
        
        return .success(comfieZone)
    }
}
