//
//  Intent.swift
//  COMFIE
//
//  Created by Anjin on 3/5/25.
//

import Foundation

protocol IntentContainer {
    associatedtype State
    associatedtype Intent
    associatedtype Action
    
    func intent(_ action: Intent)
    mutating func callAsFunction(_ action: Intent)
}

extension IntentContainer {
    mutating func callAsFunction(_ action: Self.Intent) {
        intent(action)
    }
}
