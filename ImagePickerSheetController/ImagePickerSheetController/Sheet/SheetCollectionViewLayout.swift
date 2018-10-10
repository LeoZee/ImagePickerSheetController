//
//  SheetCollectionViewLayout.swift
//  ImagePickerSheetController
//
//  Created by Laurin Brandner on 26/08/15.
//  Copyright © 2015 Laurin Brandner. All rights reserved.
//

import UIKit

class SheetCollectionViewLayout: UICollectionViewLayout {

    private var layoutAttributes = [[UICollectionViewLayoutAttributes]]()
    private var invalidatedLayoutAttributes: [[UICollectionViewLayoutAttributes]]?
    private var contentSize = CGSize.zero
    
    // MARK: - Layout
    
	override func prepare() {
		super.prepare()
        
		layoutAttributes.removeAll(keepingCapacity: false)
        contentSize = CGSize.zero
        
        if let collectionView = collectionView,
			let dataSource = collectionView.dataSource,
			let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
			let sections = dataSource.numberOfSections?(in: collectionView) ?? 0
                var origin = CGPoint()
                
                for section in 0 ..< sections {
                    var sectionAttributes = [UICollectionViewLayoutAttributes]()
                    let items = dataSource.collectionView(collectionView, numberOfItemsInSection: section)
					let indexPaths = (0 ..< items).map { NSIndexPath(item: $0, section: section) }
                    
                    for indexPath in indexPaths {
						let size = delegate.collectionView!(collectionView, layout: self, sizeForItemAt: indexPath as IndexPath)
						
						let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath as IndexPath)
                        attributes.frame = CGRect(origin: origin, size: size)
                        
                        sectionAttributes.append(attributes)
                        origin.y = attributes.frame.maxY
                    }

                    layoutAttributes.append(sectionAttributes)
                }
                
                contentSize = CGSize(width: collectionView.frame.width, height: origin.y)
        }
    }
    
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func invalidateLayout() {
        invalidatedLayoutAttributes = layoutAttributes
        super.invalidateLayout()
    }
	
	override var collectionViewContentSize: CGSize {
		return contentSize
	}
	
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttributes.reduce([], +)
			.filter { rect.intersects($0.frame) }
    }
    
    private func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, allAttributes: [[UICollectionViewLayoutAttributes]]) -> UICollectionViewLayoutAttributes? {
        guard allAttributes.count > indexPath.section && allAttributes[indexPath.section].count > indexPath.item else {
            return nil
        }
        
        return allAttributes[indexPath.section][indexPath.item]
    }
    
    private func invalidatedLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard let invalidatedLayoutAttributes = invalidatedLayoutAttributes else {
            return nil
        }
        
		return layoutAttributesForItemAtIndexPath(indexPath: indexPath, allAttributes: invalidatedLayoutAttributes)
    }
	
	override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return layoutAttributesForItemAtIndexPath(indexPath: indexPath as NSIndexPath, allAttributes: layoutAttributes)
	}
	
	override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return invalidatedLayoutAttributesForItemAtIndexPath(indexPath: itemIndexPath as NSIndexPath) ?? layoutAttributesForItemAtIndexPath(indexPath: itemIndexPath as NSIndexPath, allAttributes: layoutAttributes)
	}
	
	override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return layoutAttributesForItemAtIndexPath(indexPath: itemIndexPath as NSIndexPath, allAttributes: layoutAttributes)
	}
	
}
