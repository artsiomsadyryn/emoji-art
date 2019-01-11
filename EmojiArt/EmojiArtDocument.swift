//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Artyom Sadyrin on 1/11/19.
//  Copyright © 2019 Artyom Sadyrin. All rights reserved.
//

import UIKit

class EmojiArtDocument: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

