//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Artyom Sadyrin on 1/7/19.
//  Copyright © 2019 Artyom Sadyrin. All rights reserved.
//

import Foundation

struct EmojiArt
{
    var url: URL
    var emojis = [EmojiInfo]()
    
    struct EmojiInfo {
        let x: Int
        let y: Int
        let text: String
        let size: Int
    }
    
    init(url: URL, emojis: [EmojiInfo]) {
        self.url = url
        self.emojis = emojis
    }
}
