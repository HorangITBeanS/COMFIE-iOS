//
//  EmogiPool.swift
//  COMFIE
//
//  Created by zaehorang on 4/15/25.
//

struct EmogiPool {
    static let emojiPool: [Character] = [
        "🍕", "🐶", "🌈", "🎉", "✨", "🧡", "🌟", "🚀", "😎", "🦄",
        "🍓", "💡", "📚", "🧸", "🎨", "🍀", "🐱", "🌼", "🎁", "🔥"
    ]
    
    static func getRandomEmoji() -> Character {
        emojiPool.randomElement() ?? "🐯"
    }
}
