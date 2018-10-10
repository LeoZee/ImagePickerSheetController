//
//  AppDelegate.swift
//  Example
//
//  Created by Laurin Brandner on 26/05/15.
//  Copyright (c) 2015 Laurin Brandner. All rights reserved.
//

import UIKit
import Photos

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow? = {
		let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        
        return window
    }()
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		window?.rootViewController = ViewController()
		window?.makeKeyAndVisible()
		
		let photos = PHPhotoLibrary.authorizationStatus()
		if photos == .notDetermined {
			PHPhotoLibrary.requestAuthorization({status in
				if status == .authorized{
					
				} else {
					
				}
			})
		}
		
		return true
	}
    
	private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
    
}
