//
//  MemoryCache.swift
//  CacheKit
//
//  Created by Katsuma Tanaka on 2015/03/12.
//  Copyright (c) 2015年 Katsuma Tanaka. All rights reserved.
//

    import Foundation

#if os(iOS)
    import UIKit
#endif

public class MemoryCache<T: AnyObject>: Cache {
    
    typealias CacheObject = T
    
    
    // MARK: - Properties
    
    private let cache: NSCache
    
    public private(set) var count: UInt = 0
    
    public var countLimit: UInt {
        set {
            cache.countLimit = Int(newValue)
        }
        
        get {
            return UInt(cache.countLimit)
        }
    }
    
    
    // MARK: - Initializers
    
    public init() {
        cache = NSCache()
        cache.evictsObjectsWithDiscardedContent = false
        
#if os(iOS)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "removeAllObjects",
            name: UIApplicationDidReceiveMemoryWarningNotification,
            object: nil
        )
#endif
    }
    
    deinit {
#if os(iOS)
        NSNotificationCenter.defaultCenter().removeObserver(self)
#endif
    }
    
    
    // MARK: - Caching
    
    public func setObject(object: CacheObject, forKey key: String) {
        cache.setObject(object, forKey: key)
        
        if countLimit > 0 {
            count = min(count + 1, countLimit)
        } else {
            count++
        }
    }
    
    public func objectForKey(key: String) -> CacheObject? {
        return cache.objectForKey(key) as? CacheObject
    }
    
    public func removeObjectForKey(key: String) {
        if hasObjectForKey(key) {
            cache.removeObjectForKey(key)
            count--
        }
    }
    
    public func removeAllObjects() {
        cache.removeAllObjects()
        count = 0
    }
    
    public func hasObjectForKey(key: String) -> Bool {
        return (objectForKey(key) != nil)
    }
    
    public subscript(key: String) -> CacheObject? {
        get {
            return objectForKey(key)
        }
        
        set {
            if let object = newValue {
                setObject(object, forKey: key)
            } else {
                removeObjectForKey(key)
            }
        }
    }
    
}
