//
//  EmogiString.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//

struct EmogiString {
    var characters: [EmogiCharacter] = .init()
    
    mutating func putOriginalString(at index: Int, _ originalString: String) {
        var newCharacters: [EmogiCharacter] = []
        
        let originalCharacters = Array(originalString)
        
        // MARK: characters.count는 originalString.count보다 무조건 작다.
        var originalIndex = 0
        
        for i in 0..<characters.count {
            var emogiCharacter = characters[i]

            /// 원본과 다른게 추가되면 들어가는 반복문
            while originalIndex < originalCharacters.count &&
                    originalCharacters[originalIndex] != emogiCharacter.emogiCharacter ?? emogiCharacter.originalCharacter {
                
                let originalCharacter = originalCharacters[originalIndex]
                
                var newEmogiCharacter = EmogiCharacter(originalCharacter: originalCharacter)
                
                // 트리거 이하 인덱스만 이모지 추가
                if originalIndex <= index {
                    newEmogiCharacter.setEmogiCharacter()
                }

                newCharacters.append(newEmogiCharacter)
                originalIndex += 1
            }
            
            /// 원본과 같은 경우
            guard originalCharacters[originalIndex] == emogiCharacter.emogiCharacter ?? emogiCharacter.originalCharacter else {
                print("putOriginalString Problem")
                return
            }
            
            // 트리거 이하 인덱스만 이모지 추가
            if originalIndex <= index && emogiCharacter.emogiCharacter == nil {
                emogiCharacter.setEmogiCharacter()
            }
            
            newCharacters.append(emogiCharacter)

            originalIndex += 1
        }
        
        if originalIndex < originalCharacters.count {
            for i in originalIndex..<originalCharacters.count {
                let originalCharacter = originalCharacters[i]
                var newEmogiCharacter = EmogiCharacter(originalCharacter: originalCharacter)
                
                if i <= index {
                    newEmogiCharacter.setEmogiCharacter()
                }

                newCharacters.append(newEmogiCharacter)
            }
        }

        characters = newCharacters
    }
    
    // EmogiCharacter에서 이모지가 추가되어 있는 것은 이모지로, 아니면 텍스트로 합쳐서 리턴
    // 이모지만을 보여줘야 하는 상황도 이거 쓰면 될 듯?
        // 이모지만 보여야 하는 상황인데 이모지가 없는 경우도 이상함
    func getEmogiString() -> String {
        characters
            .map { String($0.emogiCharacter ?? $0.originalCharacter) }
            .joined()
    }
    
    func getEmogiString(to index: Int) -> String {
        var string = ""
        guard index >= 0 && index < characters.count else {
            print("getEmogiString(to:) index out of range.: \(index)")
            return string
        }
        
        for i in 0...index {
            let chracter = characters[i]
            
            string += String(chracter.emogiCharacter ?? chracter.originalCharacter)
        }
        return string
    }
    
    // 원본 리턴
    func getOriginalString() -> String {
        characters
            .map { String($0.originalCharacter) }
            .joined()
    }
    
    // 비워진 이모지 채우기
    mutating func setEmogiString() {
        // 전체 채우기
        for i in 0..<characters.count {
            self.characters[i].setEmogiCharacter()
        }
    }
    
    mutating func deleteEmogiString(from startIndex: Int, to endIndex: Int) {
        guard startIndex > 0 && endIndex < characters.count else {
            print("deleteEmogiString(from:to:) 인덱스 문제: \(startIndex),\(endIndex)")
            return
        }
        
        (startIndex...endIndex).forEach { characters.remove(at: $0) }
    }
    
    mutating func deleteEmogiString(at index: Int) {
        guard index >= 0 && index < characters.count else {
            print("deleteEmogiString(at:) 인덱스 문제: \(index)")
            return
        }
        characters.remove(at: index)
    }
    
}
