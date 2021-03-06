//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Artyom Sadyrin on 11/22/18.
//  Copyright © 2018 Artyom Sadyrin. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UIPopoverPresentationControllerDelegate
{
    
    // MARK: Model
    
    var emojiArt: EmojiArt? {
        get {
            if let url = emojiArtBackgroundImage.url {
                let emojis = emojiArtView.subviews.flatMap { $0 as? UILabel }.flatMap { EmojiArt.EmojiInfo(label: $0) }
                return EmojiArt(url: url, emojis: emojis)
            }
            else {
                return nil
            }
        }
        set {
            emojiArtBackgroundImage = (nil, nil)
            emojiArtView.subviews.flatMap { $0 as? UILabel}.forEach { $0.removeFromSuperview() }
            
            if let url = newValue?.url {
                imageFetcher = ImageFetcher(fetch: url) { (url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach {
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Properties
    
    lazy var emojiArtView = EmojiArtView()
    
    @IBOutlet weak var dropZone: UIView! {
        didSet {
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    private var _emojiArtBackgroundImageURL: URL?
    
    var emojiArtBackgroundImage: (url: URL?, image: UIImage?) {
        get {
            return (_emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
        }
        set {
            _emojiArtBackgroundImageURL = newValue.url
            scrollView.zoomScale = 1
            emojiArtView.backgroundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView.contentSize = size
            scrollViewHeight.constant = size.height
            scrollViewWidth.constant = size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            }
        }
    }
    
    @IBOutlet weak var emojiCollectionView: UICollectionView! {
        didSet {
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            emojiCollectionView.dragInteractionEnabled = true
        }
    }
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var embeddedDocInfoHeight: NSLayoutConstraint!
    @IBOutlet weak var embeddedDocInfoWidth: NSLayoutConstraint!
    
    
    
    var emojis = "😀🎁✈️🌍👍⚽️🐝🎱🍎🐼🐵💼👩💪📌❤️".map { String($0)}
    
    private var font: UIFont { // font for compatible with Accessibility
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64))
    }
    
    var document: EmojiArtDocument?
    private var embeddedDocInfo: DocumentInfoViewController?
    
    private var documentObserver: NSObjectProtocol?
    private var emojiArtViewObserver: NSObjectProtocol?
    
    // MARK: General Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        documentObserver = NotificationCenter.default.addObserver(
            forName: UIDocument.stateChangedNotification,
            object: document,
            queue: OperationQueue.main,
            using: { notification in
                print("documentState changed to \(self.document!.documentState)")
                if self.document!.documentState == .normal, let docInfoVC = self.embeddedDocInfo {
                    docInfoVC.document = self.document
                    self.embeddedDocInfoWidth.constant = docInfoVC.preferredContentSize.width
                    self.embeddedDocInfoHeight.constant = docInfoVC.preferredContentSize.height
                }
        }
        )
        
        document?.open { success in
            if success {
                self.title = self.document?.localizedName
                self.emojiArt = self.document?.emojiArt
                self.emojiArtViewObserver = NotificationCenter.default.addObserver(
                    forName: .EmojiArtViewDidChange,
                    object: self.emojiArtView,
                    queue: OperationQueue.main,
                    using: { notification in
                        self.documentChanged()
                }
                )
            }
        }
    }
    
    // MARK: Document Handling
    
    private func documentChanged() {
        document?.emojiArt = emojiArt
        if document?.emojiArt != nil {
            document?.updateChangeCount(.done)
            print("Saved succesfully!")
        }
    }
    
    @IBAction func close(_ sender: UIBarButtonItem? = nil) {
        if let observer = emojiArtViewObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        documentChanged()
        
        if document?.emojiArt != nil {
            document?.thumbnail = emojiArtView.snapshot
        }
        
        presentingViewController?.dismiss(animated: true) {
            self.document?.close { success in
                if let observer = self.documentObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
    
    
    // MARK: Scroll View Methods
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewWidth.constant = scrollView.contentSize.width
        scrollViewHeight.constant = scrollView.contentSize.height
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    // MARK: Add New Emoji Methods
    
    private var addingEmoji = false
    
    @IBAction func addEmoji() {
        addingEmoji = true
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
    }
    
    // MARK: Collection View Data Source Methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
            case 0: return 1
            case 1: return emojis.count
            default: return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
            if let cell = cell as? EmojiCollectionViewCell {
                let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
                cell.emojiLabel.attributedText = text
            }
            return cell
        }
        else if addingEmoji {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
            if let inputCell = cell as? TextFieldCollectionViewCell {
                inputCell.resignationHandler = { [weak self, unowned inputCell] in
                    if let text = inputCell.textField.text {
                        self?.emojis = (text.map { String($0) } + self!.emojis).uniquified
                    }
                    self?.addingEmoji = false
                    self?.emojiCollectionView.reloadData()
                }
            }
            
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
            return cell
        }
    }
    
    // MARK: Collection View Delegate Flow Layout Methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if addingEmoji && indexPath.section == 0 {
            return CGSize(width: 300, height: 80)
        }
        else {
            return CGSize(width: 80, height: 80)
        }
    }
    
    // MARK: Collection View Delegate
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell {
            inputCell.textField.becomeFirstResponder()
        }
    }
    
    // MARK: Drop Image from Web Methods
    
    var imageFetcher: ImageFetcher!
    
    private var supressBadURLWarnings = false
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    private func presentBadURLWarning(for url: URL?) {
        if !supressBadURLWarnings {
            let alert = UIAlertController(
                title: "Image Transfer Failed",
                message: "Couldn't transfer image for its source./nShow this warning in the future?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "Keep Warning",
                style: .default
            ))
            
            alert.addAction(UIAlertAction(
                title: "Stop Warning",
                style: .destructive,
                handler: { action in
                    self.supressBadURLWarnings = true
            }))
            
            present(alert, animated: true)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url, image)
            }
        }
        
        session.loadObjects(ofClass: NSURL.self) { nsurls in
            if let url = nsurls.first as? URL {
                //self.imageFetcher.fetch(url)
                DispatchQueue.global(qos: .userInitiated).async {
                    if let imageData = try? Data(contentsOf: url.imageURL), let image = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            self.emojiArtBackgroundImage = (url, image)
                        }
                    }
                    else {
                        self.presentBadURLWarning(for: url)
                    }
                }
            }
        }
        
        session.loadObjects(ofClass: UIImage.self) { images in
            if let image = images.first as? UIImage {
                self.imageFetcher.backup = image
            }
        }
        
    }
    
    // MARK: Drag Emojis Methods
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView // in case if we want change the order of emojis
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if !addingEmoji, let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.emojiLabel.attributedText { // getting needed to us data with help of indexPath
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return [dragItem]
        }
        else {
            return []
        }
    }
    
    // MARK: Drop Emojis Methods
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 1 {
            let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView // with this we undestand if droping emoji perform in the same collection view
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
        }
        else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destionationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath { // drop from the web to imageView
                if let attributedString = item.dragItem.localObject as? NSAttributedString {
                    collectionView.performBatchUpdates({ // always do multiple changes in collection view with performBatchUpdates
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destionationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destionationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destionationIndexPath)
                }
            }
            else { // drop from the web to collectionView
                let placeholder = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destionationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                // get data async
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self, completionHandler: { (provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString {
                            placeholder.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        }
                        else {
                            placeholder.deletePlaceholder()
                        }
                    }
                })
            }
            
        }
        
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Document Info" {
            if let destination = segue.destination.contents as? DocumentInfoViewController {
                document?.thumbnail = emojiArtView.snapshot
                destination.document = document
                if let ppc = destination.popoverPresentationController {
                    ppc.delegate = self
                }
            }
        } else if segue.identifier == "Embed Document Info", let destination = segue.destination.contents as? DocumentInfoViewController {
            embeddedDocInfo = destination
        }
    }
    
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    @IBAction func close(bySegue: UIStoryboardSegue) {
        close()
    }
    
}

// MARK: Extension

extension EmojiArt.EmojiInfo
{
    init?(label: UILabel) {
        if let attributedText = label.attributedText, let font = attributedText.font {
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedText.string
            size = Int(font.pointSize)
        }
        else {
            return nil
        }
    }
}
