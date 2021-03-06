//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Artyom Sadyrin on 11/23/18.
//  Copyright © 2018 Artyom Sadyrin. All rights reserved.
//

import UIKit

class EmojiArtView: UIView, UIDropInteractionDelegate
{
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addInteraction(UIDropInteraction(delegate: self))
    }
    
    
    // MARK: Properties
    
    var backgroundImage: UIImage? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Methods

    override func draw(_ rect: CGRect) {
        // Drawing code
        backgroundImage?.draw(in: bounds)
    }
    
    private var labelObservations = [UIView:NSKeyValueObservation]()
    
    func addLabel(with attributedString: NSAttributedString, centeredAt point: CGPoint) {
        let label = UILabel()
        label.backgroundColor = .clear
        label.attributedText = attributedString
        label.sizeToFit()
        label.center = point
        addEmojiArtGestureRecognizers(to: label)
        addSubview(label)
        labelObservations[label] = label.observe(\.center) { (label, change) in
            NotificationCenter.default.post(name: .EmojiArtViewDidChange, object: self)
        }
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        if labelObservations[subview] != nil {
            labelObservations[subview] = nil
        }
    }
    
    // MARK: Drop from Collection View Methods
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSAttributedString.self) { (providers) in
            let dropPoint = session.location(in: self)
            for attributedString in providers as? [NSAttributedString] ?? [] {
                self.addLabel(with: attributedString, centeredAt: dropPoint)
                NotificationCenter.default.post(name: .EmojiArtViewDidChange, object: self)
            }
        }
    }
    
}

extension Notification.Name {
    static let EmojiArtViewDidChange = Notification.Name("EmojiArtViewDidChange")
}
