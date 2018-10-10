//
//  ViewController.swift
//  Example
//
//  Created by Laurin Brandner on 26/05/15.
//  Copyright (c) 2015 Laurin Brandner. All rights reserved.
//

import UIKit
import Photos
import ImagePickerSheetController

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: View Lifecycle
    var imageView: UIImageView?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.presentImagePickerSheet(gestureRecognizer:)))
        view.addGestureRecognizer(tapRecognizer)
        
        imageView = UIImageView(frame: self.view.bounds);
        self.view.addSubview(imageView!)
    }
    
    // MARK: Other Methods
    
	@objc func presentImagePickerSheet(gestureRecognizer: UITapGestureRecognizer) {
				
        
//		let presentImagePickerController: (UIImagePickerController.SourceType) -> () = { source in
//			let controller = UIImagePickerController()
//            controller.delegate = self
//            var sourceType = source
//            if (!UIImagePickerController.isSourceTypeAvailable(sourceType)) {
//				sourceType = .photoLibrary
//                print("Fallback to camera roll as a source since the simulator doesn't support taking pictures")
//            }
//            controller.sourceType = sourceType
//
//			self.present(controller, animated: true, completion: nil)
//        }
		
        let controller = ImagePickerSheetController(mediaType: .Image)
        controller.maximumSelection = 3
		
		controller.addAction(action: ImagePickerAction(title: NSLocalizedString("Take Photo Or Video", comment: "Action Title"), secondaryTitle: { _ -> String in
			NSLocalizedString("Add comment", comment: "Action Title")
		}, style: ImagePickerActionStyle.Default, handler: { _ in
			self.presentImagePickerController(.camera)
		}, secondaryHandler: { (_,_) in
			print("Send \(controller.selectedImageAssets)")
		}))
		
		controller.addAction(action: ImagePickerAction(title: NSLocalizedString("Photo Library", comment: "Action Title"), secondaryTitle: { NSString.localizedStringWithFormat(NSLocalizedString("ImagePickerSheet.button1.Send %lu Photo", comment: "Action Title") as NSString, $0) as String}, handler: { _ in
			self.presentImagePickerController(.photoLibrary)
        }, secondaryHandler: { _, numberOfPhotos in
            
            print("Send \(controller.selectedImageAssets)")
        }))

        controller.enableEnlargedPreviews = false;

		controller.addAction(action: ImagePickerAction(cancelTitle: NSLocalizedString("Cancel", comment: "Action Title")))

		if UIDevice.current.userInterfaceIdiom == .pad {
			controller.modalPresentationStyle = .popover
			controller.popoverPresentationController?.sourceView = view
			controller.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize())
		}
        
		present(controller, animated: true, completion: nil)
    }
	
	private func presentImagePickerController(_ source: UIImagePickerController.SourceType) {
		
		let controller = UIImagePickerController()
		controller.delegate = self
		var sourceType = source
		if (!UIImagePickerController.isSourceTypeAvailable(sourceType)) {
			sourceType = .photoLibrary
			print("Fallback to camera roll as a source since the simulator doesn't support taking pictures")
		}
		controller.sourceType = sourceType
		
		self.present(controller, animated: true, completion: nil)
	}
    
    // MARK: UIImagePickerControllerDelegate
    
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
    }
    
}
