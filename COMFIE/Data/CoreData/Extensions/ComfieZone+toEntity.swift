//
//  ComfieZone+toEntity.swift
//  COMFIE
//
//  Created by zaehorang on 3/10/25.
//

import CoreData

extension ComfieZone {
    static func toEntity(context: NSManagedObjectContext, comfieZone: ComfieZone) -> ComfieZoneEntity {
        let entity = ComfieZoneEntity(context: context)
        entity.id = comfieZone.id
        entity.name = comfieZone.name
        entity.longitude = comfieZone.longitude
        entity.latitude = comfieZone.latitude
        
        return entity
    }
}
