//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Artyom Sadyrin on 11/23/18.
//  Copyright © 2018 Artyom Sadyrin. All rights reserved.
//

import UIKit

class EmojiArtView: UIView
{
    
    // MARK: Properties
    
    var backgroundImage: UIImage? {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        // Drawing code
        backgroundImage?.draw(in: bounds)
    }

}
