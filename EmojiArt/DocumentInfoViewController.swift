//
//  DocumentInfoViewController.swift
//  EmojiArt
//
//  Created by Artyom Sadyrin on 2/3/19.
//  Copyright © 2019 Artyom Sadyrin. All rights reserved.
//

import UIKit

class DocumentInfoViewController: UIViewController
{
    
    // MARK: Properties

    var document: EmojiArtDocument? {
        didSet {
            updateUI()
        }
    }
    
    
    @IBOutlet weak var thumbnailAspectRatio: NSLayoutConstraint!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy HH:mm"
        return formatter
    }()
    
    private func updateUI() {
        if sizeLabel != nil, createdLabel != nil, let url = document?.fileURL, let attrubites = try? FileManager.default.attributesOfItem(atPath: url.path), let created = attrubites[.creationDate] as? Date {
            sizeLabel.text = "\(attrubites[.size] ?? "unknown") bytes"
            createdLabel.text = shortDateFormatter.string(from: created)
        }
        
        if thumbnailImageView != nil, thumbnailAspectRatio != nil, let thumbnnail = document?.thumbnail {
            thumbnailImageView.image = thumbnnail
            thumbnailImageView.removeConstraint(thumbnailAspectRatio)
            thumbnailAspectRatio = NSLayoutConstraint.init(
                item: thumbnailImageView,
                attribute: .width,
                relatedBy: .equal,
                toItem: thumbnailImageView,
                attribute: .height,
                multiplier: thumbnnail.size.width / thumbnnail.size.height,
                constant: 0
            )
            thumbnailImageView.addConstraint(thumbnailAspectRatio)
            
        }
    }
    
    @IBAction func done(_ sender: UIButton) {
        presentingViewController?.dismiss(animated: true)
    }
    
    
}
