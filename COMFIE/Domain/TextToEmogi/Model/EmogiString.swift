//
//  EmogiString.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//

struct EmogiString {
    private var emogiCharacters: [EmogiCharacter] = []
    
    /// index 위치까지 이모지를 적용한 문자열을 설정합니다.
    mutating func applyEmogiString(at index: Int, _ newString: String) {
        syncWithNewString(newString)
        changeEmogi(upTo: index)
    }
    
    /// 변경된 문자열과 emogiCharacters를 동기화합니다.
    /// - Note: newString에 문자가 **추가된 경우**에만 실행됩니다.
    mutating func syncWithNewString(_ newString: String) {
        let originalCharacters = Array(newString)
        var originalIndex = 0
        
        guard newString.count > emogiCharacters.count else { return}
        
        var newCharacters: [EmogiCharacter] = []

        for i in 0..<emogiCharacters.count {
            let emogiCharacter = emogiCharacters[i]
            let currentChar = emogiCharacter.emogiCharacter ?? emogiCharacter.originalCharacter
            let updatedChar = originalCharacters[originalIndex]
            
            if updatedChar != currentChar {
                while originalCharacters[originalIndex] != currentChar {
                    newCharacters.append(
                        EmogiCharacter(originalCharacter: originalCharacters[originalIndex])
                    )
                    originalIndex += 1
                }
            }
            
            newCharacters.append(emogiCharacter)
            originalIndex += 1
        }
        
        // 나머지 추가된 문자 반영
        if originalIndex < originalCharacters.count {
            originalCharacters[originalIndex...].forEach {
                    newCharacters.append(EmogiCharacter(originalCharacter: $0))
                }
        }

        emogiCharacters = newCharacters
    }
    
    /// index 위치까지 모든 character에 이모지를 적용합니다.
    mutating private func changeEmogi(upTo index: Int) {
        guard emogiCharacters.count > index && index > 0 else { return }
        (0...index).forEach { emogiCharacters[$0].setEmogiCharacter() }
    }
    
    /// 현재 이모지 적용 상태의 문자열을 반환합니다.
    func getEmogiString() -> String {
        emogiCharacters
            .map { String($0.emogiCharacter ?? $0.originalCharacter) }
            .joined()
    }
    
    /// index 위치까지의 이모지 적용 문자열을 반환합니다.
    func getEmogiString(to index: Int) -> String {
        var string = ""
        guard index >= 0 && index < emogiCharacters.count else {
            print("getEmogiString(to:) index out of range.: \(index)")
            return string
        }
        
        for i in 0...index {
            let chracter = emogiCharacters[i]
            
            string += String(chracter.emogiCharacter ?? chracter.originalCharacter)
        }
        return string
    }
    
    /// 원본 문자열을 반환합니다.
    func getOriginalString() -> String {
        emogiCharacters
            .map { String($0.originalCharacter) }
            .joined()
    }
    
    /// 비워진 이모지를 전체 적용합니다.
    mutating func setEmogiString() {
        // 전체 채우기
        for i in emogiCharacters.indices {
            emogiCharacters[i].setEmogiCharacter()
        }
    }
    
    /// 지정된 범위의 이모지 문자열을 삭제합니다.
    mutating func deleteEmogiString(from start: Int, to end: Int? = nil) {
        let toIndex = end ?? start
        
        guard start >= 0, toIndex < emogiCharacters.count, start <= toIndex else {
            print("deleteEmogiString(start:end:) 인덱스 문제: \(start), \(String(describing: end))")
            return
        }

        emogiCharacters.removeSubrange(start...toIndex)
    }
}
