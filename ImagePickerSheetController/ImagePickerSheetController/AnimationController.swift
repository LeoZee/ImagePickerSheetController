//
//  AnimationController.swift
//  ImagePickerSheet
//
//  Created by Laurin Brandner on 25/05/15.
//  Copyright (c) 2015 Laurin Brandner. All rights reserved.
//

import UIKit

class AnimationController: NSObject {
    
    let imagePickerSheetController: ImagePickerSheetController
    let presenting: Bool
    
    // MARK: - Initialization
    
    init(imagePickerSheetController: ImagePickerSheetController, presenting: Bool) {
        self.imagePickerSheetController = imagePickerSheetController
        self.presenting = presenting
    }
    
    // MARK: - Animation
    
    private func animatePresentation(context: UIViewControllerContextTransitioning) {
		let containerView = context.containerView
        
        containerView.addSubview(imagePickerSheetController.view)
        
        let sheetOriginY = imagePickerSheetController.sheetCollectionView.frame.origin.y
        imagePickerSheetController.sheetCollectionView.frame.origin.y = containerView.bounds.maxY
        imagePickerSheetController.backgroundView.alpha = 0
		
		UIView.animate(withDuration: transitionDuration(using: context), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.9, options: .beginFromCurrentState, animations: {
			self.imagePickerSheetController.sheetCollectionView.frame.origin.y = sheetOriginY
			self.imagePickerSheetController.backgroundView.alpha = 1
		}) { _ in
			context.completeTransition(true)
		}
    }
    
    private func animateDismissal(context: UIViewControllerContextTransitioning) {
		let containerView = context.containerView
		
		UIView.animate(withDuration: transitionDuration(using: context), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: {
			self.imagePickerSheetController.sheetCollectionView.frame.origin.y = containerView.bounds.maxY
			self.imagePickerSheetController.backgroundView.alpha = 0
		}) { _ in
			self.imagePickerSheetController.view.removeFromSuperview()
			context.completeTransition(true)
		}
    }
    
}

// MARK: - UIViewControllerAnimatedTransitioning
extension AnimationController: UIViewControllerAnimatedTransitioning {
    
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if presenting {
			animatePresentation(context: transitionContext)
        }
        else {
			animateDismissal(context: transitionContext)
        }
    }
    
}
