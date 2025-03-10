//
//  ComfieZone.swift
//  COMFIE
//
//  Created by Anjin on 3/7/25.
//

import Foundation

// 컴피존 위치
struct ComfieZone {
    let id: UUID
    let longitude: Double
    let latitude: Double
    // 이름 변경하는 기능 없으면 let으로 변경
    var name: String
}
