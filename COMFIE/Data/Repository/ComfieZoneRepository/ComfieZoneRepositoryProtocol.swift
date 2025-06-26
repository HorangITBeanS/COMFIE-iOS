//
//  ComfieZoneRepositoryProtocol.swift
//  COMFIE
//
//  Created by Anjin on 5/26/25.
//

import Foundation

protocol ComfieZoneRepositoryProtocol {
    func fetchComfieZone() -> ComfieZone?
    func saveComfieZone(_ comfieZone: ComfieZone)
    func deleteComfieZone()
}
