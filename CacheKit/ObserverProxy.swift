//
//  ObserverProxy.swift
//  CacheKit
//
//  Created by Ryosuke Sasaki on 4/1/15.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

import Foundation

@objc class ObserverProxy {
    let callback: (NSNotification) -> Void
    let name: String
    let object: AnyObject?
   
    init(_ name: String, callback: (NSNotification) -> Void, object: AnyObject?) {
        self.name = name
        self.callback = callback
        self.object = object
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "handleNotification:",
            name: name,
            object: object)
    }
    
    convenience init(_ name: String, callback: (NSNotification) -> Void) {
        self.init(name, callback: callback, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleNotification(notification: NSNotification) {
        callback(notification)
    }
}
