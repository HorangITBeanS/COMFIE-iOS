//
//  Date+.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 3/26/25.
//

import Foundation

extension Date {
    func toFormattedDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
