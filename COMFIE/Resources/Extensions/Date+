//
//  Date+String.swift
//  COMFIE
//
//  Created by zaehorang on 3/27/25.
//

import Foundation

extension Date {
    var hourAndMinuteString: String {
        formatted(
            Date.FormatStyle()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
    }
    
    var dotYMDFormat: String {
        self.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
    }
}
