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

    var document: EmojiArtDocument? {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func updateUI() {
        if sizeLabel != nil, createdLabel != nil, let url = document?.fileURL, let attrubites = try? FileManager.default.attributesOfItem(atPath: url.path), let created = attrubites[.creationDate] as? Date {
            sizeLabel.text = "\(attrubites[.size] ?? "unknown") bytes"
            createdLabel.text = shortDateFormatter.string(from: created)
        }
        
        if thunmnailImageView != nil, let thumnnail = document?.thumbnail {
            thunmnailImageView.image = thumnnail
        }
    }
    
    @IBOutlet weak var thunmnailImageView: UIImageView!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    
    @IBAction func done(_ sender: UIButton) {
        presentingViewController?.dismiss(animated: true)
    }
    
    
}
