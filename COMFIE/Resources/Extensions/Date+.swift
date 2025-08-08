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
    
    /// 날짜를 로컬 포맷(연-월-일)으로 문자열로 반환합니다.
    /// 예: 한국어 설정 시 "2024년 5월 11일", 영어 설정 시 "May 11, 2024"
    var yyyyMMddString: String {
        self.formatted(
            .dateTime
                .year()
                .month()
                .day()
        )
    }

    func toFormattedDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
