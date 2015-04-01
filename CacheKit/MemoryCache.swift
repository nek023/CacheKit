//
//  MemoryCache.swift
//  CacheKit
//
//  Created by Katsuma Tanaka on 2015/03/12.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Foundation
#endif

public class MemoryCache<T>: Cache {
    
    typealias CacheObject = T
    
    
    // MARK: - Properties
    
    private let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(1)
    private var entries: Dictionary<String, (T, Int)> = [:]
    private var sequenceNumber: UInt = 0
    
#if os(iOS)
    private var memoryWarningObserver: ObserverProxy!
#endif
    
    public var count: UInt {
        return UInt(entries.count)
    }
    
    public var countLimit: UInt = 0 {
        didSet {
            removeLeastRecentlyUsedObjects()
        }
    }
    
    
    // MARK: - Initializers
    
    public init() {
#if os(iOS)
    memoryWarningObserver = ObserverProxy(name: UIApplicationDidReceiveMemoryWarningNotification) { [weak self] _ in
            self?.removeAllObjects()
            return
        }
#endif
    }
    
    
    // MARK: - Caching
    
    public func setObject(object: CacheObject, forKey key: String) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        entries[key] = (object, Int(sequenceNumber))
        sequenceNumber++
        if sequenceNumber == UInt.max {
            resequence()
        }
        
        dispatch_semaphore_signal(semaphore)
        
        removeLeastRecentlyUsedObjects()
    }
    
    private func resequence() {
        sequenceNumber = 0
        for key in entries.keys {
            if let entry = entries[key] {
                entries[key] = (entry.0, Int(sequenceNumber++))
            }
        }
    }
    
    public func objectForKey(key: String) -> CacheObject? {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        let object = entries[key]?.0
        
        dispatch_semaphore_signal(semaphore)
        
        return object
    }
    
    public func removeObjectForKey(key: String) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        entries.removeValueForKey(key)
        
        dispatch_semaphore_signal(semaphore)
    }
    
    public func removeAllObjects() {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        entries.removeAll(keepCapacity: false)
        
        dispatch_semaphore_signal(semaphore)
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
    
    private func removeLeastRecentlyUsedObjects() {
        if 0 < countLimit && countLimit < count {
            var keys = entries.keys.array.sorted { (key1: String, key2: String) in
                return self.entries[key1]!.1 < self.entries[key2]!.1
            }
            
            for index in 0..<(keys.count - Int(countLimit)) {
                entries.removeValueForKey(keys[index])
            }
        }
    }
    
}
