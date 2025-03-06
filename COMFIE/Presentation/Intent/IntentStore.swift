//
//  Intent.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import Foundation

protocol IntentStore {
    associatedtype State
    associatedtype Intent
    associatedtype Action
    
    func intent(_ action: Intent)
    mutating func callAsFunction(_ action: Intent)
}

extension IntentStore {
    mutating func callAsFunction(_ action: Self.Intent) {
        intent(action)
    }
}
