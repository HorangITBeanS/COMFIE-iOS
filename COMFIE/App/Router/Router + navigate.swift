//
//  Router + navigate.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import Foundation

extension Router {
    func push(_ route: Route) {
        self.path.append(route)
    }
    
    func pop() {
        if self.path.isEmpty == false {
            self.path.removeLast()
        }
    }
    
    func popToRoot() {
        self.path.removeAll()
    }
}
