//
//  ObserverProxy.swift
//  CacheKit
//
//  Created by Ryosuke Sasaki on 2015/04/01.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

import Foundation

class ObserverProxy: NSObject {
    
    // MARK: - Properties
    
    let name: String
    let object: AnyObject?
    let callback: (NSNotification) -> Void
   
    
    // MARK: - Initializers
    
    init(name: String, object: AnyObject?, callback: (NSNotification) -> Void) {
        self.name = name
        self.callback = callback
        self.object = object

        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(ObserverProxy.handleNotification(_:)),
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
