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
    
    func handleIntent(_ intent: Intent)
    func callAsFunction(_ intent: Intent)
}

extension IntentStore {
    func callAsFunction(_ intent: Self.Intent) {
        handleIntent(intent)
    }
}
