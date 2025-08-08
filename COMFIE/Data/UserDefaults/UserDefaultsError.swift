//
//  UserDefaultsError.swift
//  COMFIE
//
//  Created by Anjin on 3/6/25.
//

import Foundation

enum UserDefaultsError: LocalizedError {
  case keyNotFound(key: String)
  
  var errorDescription: String? {
    switch self {
    case .keyNotFound(let key):
      return "UserDefaults에 찾으려는 key \(key)가 없습니다"
    }
  }
}
