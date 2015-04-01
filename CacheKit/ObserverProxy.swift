//
//  ObserverProxy.swift
//  CacheKit
//
//  Created by Ryosuke Sasaki on 2015/04/01.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

import Foundation

@objc class ObserverProxy {
    
    // MARK: - Properties
    
    let name: String
    let object: AnyObject?
    let callback: (NSNotification) -> Void
   
    
    // MARK: - Initializers
    
    init(name: String, object: AnyObject?, callback: (NSNotification) -> Void) {
        self.name = name
        self.callback = callback
        self.object = object
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "handleNotification:",
            name: name,
            object: object
        )
    }
    
    convenience init(name: String, callback: (NSNotification) -> Void) {
        self.init(name: name, object: nil, callback: callback)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: - Handling Notifications
    
    func handleNotification(notification: NSNotification) {
        callback(notification)
    }
    
}
