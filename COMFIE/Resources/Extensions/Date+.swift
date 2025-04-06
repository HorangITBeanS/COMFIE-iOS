//
//  Date+.swift
//  COMFIE
//
//  Created by zaehorang on 3/27/25.
//

import Foundation

extension Date {
    var hourAndMinuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    var dotYMDFormat: String {
        self.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
    }

    func toFormattedDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}