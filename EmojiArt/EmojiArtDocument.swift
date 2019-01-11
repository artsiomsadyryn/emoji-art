//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Artyom Sadyrin on 1/11/19.
//  Copyright © 2019 Artyom Sadyrin. All rights reserved.
//

import UIKit

class EmojiArtDocument: UIDocument {
    
    var emojiArt: EmojiArt?
    
    override func contents(forType typeName: String) throws -> Any {
        
        return emojiArt?.json ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let json = contents as? Data {
            emojiArt = EmojiArt(json: json)
        }
    }
}

