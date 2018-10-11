//
//  SheetController.swift
//  ImagePickerSheetController
//
//  Created by Laurin Brandner on 27/08/15.
//  Copyright © 2015 Laurin Brandner. All rights reserved.
//

import UIKit

private let defaultInset: CGFloat = 10

class SheetController: NSObject {
    
    var displayPreview: Bool = true;
    
    private(set) lazy var sheetCollectionView: UICollectionView = {
        let layout = SheetCollectionViewLayout()
        let collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "ImagePickerSheet"
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false
		collectionView.register(SheetPreviewCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(SheetPreviewCollectionViewCell.self))
		collectionView.register(SheetActionCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(SheetActionCollectionViewCell.self))
        
        return collectionView
    }()
    
    var previewCollectionView: PreviewCollectionView
    
    private(set) var actions = [ImagePickerAction]()
    
    var actionHandlingCallback: (() -> ())?
    
    private(set) var previewHeight: CGFloat = 0
    var numberOfSelectedImages = 0
    
    var preferredSheetHeight: CGFloat {
		return allIndexPaths().compactMap({ self.sizeForSheetItemAtIndexPath(indexPath: $0).height }).reduce(0, +)
    }
    
    var preferredSheetWidth: CGFloat {
        guard #available(iOS 9, *) else {
            return sheetCollectionView.bounds.width
        }
        return sheetCollectionView.bounds.width - 2 * defaultInset
    }
    
    // MARK: - Initialization
    
    init(previewCollectionView: PreviewCollectionView) {
        self.previewCollectionView = previewCollectionView
        
        super.init()
    }
    
    // MARK: - Data Source
    // These methods are necessary so that no call cycles happen when calculating some design attributes
    
    private func numberOfSections() -> Int {
        return 2
    }
    
    private func numberOfItemsInSection(section: Int) -> Int {
        if section == 0 {
            return 1
        }
        
        return actions.count
    }
    
    private func allIndexPaths() -> [NSIndexPath] {
        let s = numberOfSections()
		return (0 ..< s).map { (self.numberOfItemsInSection(section: $0), $0) }
            .flatMap { numberOfItems, section in
				(0 ..< numberOfItems).map { NSIndexPath(item: $0, section: section) }
        }
    }
    
    private func sizeForSheetItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        let height: CGFloat = {
            if indexPath.section == 0 {
                return previewHeight
            }
            
            let actionItemHeight: CGFloat
            
            if #available(iOS 9, *) {
                actionItemHeight = 57
            }
            else {
                actionItemHeight = 50
            }
            
			let insets = attributesForItemAtIndexPath(indexPath: indexPath).backgroundInsets
            return actionItemHeight + insets.top + insets.bottom
        }()
        
        return CGSize(width: sheetCollectionView.bounds.width, height: height)
    }
    
    // MARK: - Design
    
    private func attributesForItemAtIndexPath(indexPath: NSIndexPath) -> (corners: RoundedCorner, backgroundInsets: UIEdgeInsets) {
        guard #available(iOS 9, *) else {
            return (.None, UIEdgeInsets())
        }
        
        let cornerRadius: CGFloat = 13
        let innerInset: CGFloat = 4
        var indexPaths = allIndexPaths()
        
        guard indexPaths.first != indexPath else {
            return (.Top(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: 0, right: defaultInset))
        }
		
		let cancelIndexPath = actions.lastIndex(where: { $0.style == ImagePickerActionStyle.Cancel }).map({ NSIndexPath(item: $0, section: 1) })
        
        if let cancelIndexPath = cancelIndexPath {
            if cancelIndexPath == indexPath {
                return (.All(cornerRadius), UIEdgeInsets(top: innerInset, left: defaultInset, bottom: defaultInset, right: defaultInset))
            }
            
            indexPaths.removeLast()
            
            if indexPath == indexPaths.last {
                return (.Bottom(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: innerInset, right: defaultInset))
            }
        }
        else if indexPath == indexPaths.last {
            return (.Bottom(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: defaultInset, right: defaultInset))
        }
        
        
        if indexPath == indexPaths[1] && !displayPreview {
            return (.Top(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: 0, right: defaultInset))
        }
        
        return (.None, UIEdgeInsets(top: 0, left: defaultInset, bottom: 0, right: defaultInset))
    }
    
    private func fontForAction(action: ImagePickerAction) -> UIFont {
        guard #available(iOS 9, *), action.style == .Cancel else {
			return UIFont.systemFont(ofSize: 21)
        }
        
		return UIFont.boldSystemFont(ofSize: 21)
    }
    
    // MARK: - Actions
    func reloadActionItems() {
		sheetCollectionView.reloadSections(NSIndexSet(index: 1) as IndexSet)
    }
    
    func addAction(action: ImagePickerAction) {
        if action.style == .Cancel {
            actions = actions.filter { $0.style != .Cancel }
        }
        
        actions.append(action)
        
        if let index = actions.firstIndex(where: { $0.style == ImagePickerActionStyle.Cancel }) {
            let cancelAction = actions.remove(at: index)
            actions.append(cancelAction)
        }
        
        reloadActionItems()
    }
    
    private func handleAction(action: ImagePickerAction) {
        actionHandlingCallback?()
		action.handle(numberOfImages: numberOfSelectedImages)
    }
    
    func handleCancelAction() {
        
        if let cancelAction = (actions.filter { $0.style == ImagePickerActionStyle.Cancel }).first {
			handleAction(action: cancelAction)
        }
        else {
            actionHandlingCallback?()
        }
    }
    
    // MARK: -
    
    func setPreviewHeight(height: CGFloat, invalidateLayout: Bool) {
        previewHeight = height
        if invalidateLayout {
            sheetCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
}

extension SheetController: UICollectionViewDataSource {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return numberOfSections()
	}
	
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return numberOfItemsInSection(section: section)
    }
    
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SheetCollectionViewCell
        
        if indexPath.section == 0 {
			let previewCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SheetPreviewCollectionViewCell.self), for: indexPath as IndexPath) as! SheetPreviewCollectionViewCell
            previewCell.collectionView = previewCollectionView
            
            cell = previewCell
        }
        else {
            let action = actions[indexPath.item]
			let actionCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SheetActionCollectionViewCell.self), for: indexPath as IndexPath) as! SheetActionCollectionViewCell
			actionCell.textLabel.font = fontForAction(action: action)
            actionCell.textLabel.text = numberOfSelectedImages > 0 ? action.secondaryTitle(numberOfSelectedImages) : action.title
            
            cell = actionCell
        }
        
        cell.separatorVisible = (indexPath.section == 1)
        
        // iOS specific design
		(cell.roundedCorners, cell.backgroundInsets) = attributesForItemAtIndexPath(indexPath: indexPath as NSIndexPath)
        if #available(iOS 9, *) {
            cell.normalBackgroundColor = UIColor(white: 0.97, alpha: 1)
            cell.highlightedBackgroundColor = UIColor(white: 0.92, alpha: 1)
            cell.separatorColor = UIColor(white: 0.84, alpha: 1)
        }
        else {
			cell.normalBackgroundColor = .white
            cell.highlightedBackgroundColor = UIColor(white: 0.85, alpha: 1)
            cell.separatorColor = UIColor(white: 0.784, alpha: 1)
        }
        
        return cell
    }
    
}

extension SheetController: UICollectionViewDelegate {
    
	func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
        
		handleAction(action: actions[indexPath.item])
    }
    
}

extension SheetController: UICollectionViewDelegateFlowLayout {
    
	func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return sizeForSheetItemAtIndexPath(indexPath: indexPath as NSIndexPath)
    }
    
}
