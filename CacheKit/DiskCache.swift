//
//  DiskCache.swift
//  CacheKit
//
//  Created by Katsuma Tanaka on 2015/03/13.
//  Copyright (c) 2015年 Katsuma Tanaka. All rights reserved.
//

import Foundation

public class DiskCache<T: NSCoding>: Cache {
    
    typealias CacheObject = T
    
    
    // MARK: - Properties
    
    private let semaphore: dispatch_semaphore_t
    private var entries: [(String, NSDate)] = []
    
    public let directoryPath: String
    
    public var count: UInt {
        return UInt(entries.count)
    }
    
    public var countLimit: UInt = 0 {
        didSet {
            removeLeastRecentlyUsedObjects()
        }
    }
    
    
    // MARK: - Initializers
    
    public init(directoryPath: String) {
        self.semaphore = dispatch_semaphore_create(1)
        self.directoryPath = directoryPath
        
        // Create directory if necessary
        let fileManager = NSFileManager.defaultManager()
        
        if !fileManager.fileExistsAtPath(directoryPath) {
            var error: NSError?
            if !fileManager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil, error: &error) {
                NSException.raise(error!.domain, format: "Error: %@", arguments: getVaList([error!.localizedDescription]))
            }
        }
        
        // Get file list
        let enumerator = fileManager.enumeratorAtURL(
            NSURL(fileURLWithPath: directoryPath)!,
            includingPropertiesForKeys: [NSURLPathKey],
            options: .SkipsHiddenFiles,
            errorHandler: { (URL: NSURL!, error: NSError!) -> Bool in
                NSException.raise(error!.domain, format: "Error: %@", arguments: getVaList([error!.localizedDescription]))
                return false
            }
        )!
        
        while let fileURL = enumerator.nextObject() as? NSURL {
            let filePath = fileURL.path!
            let attributes = fileManager.attributesOfItemAtPath(filePath, error: nil)!
            let modificationDate = attributes[NSFileModificationDate] as NSDate
            
            entries.append((filePath.lastPathComponent, modificationDate))
        }
        
        entries.sort { return ($0.1.compare($1.1) == .OrderedAscending) }
    }
    
    public convenience init(directoryURL: NSURL) {
        self.init(directoryPath: directoryURL.path!)
    }
    
    public convenience init() {
        var directoryPath = NSTemporaryDirectory()
        if let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier {
            directoryPath = directoryPath.stringByAppendingPathComponent(bundleIdentifier)
        }
        
        self.init(directoryPath: directoryPath)
    }
    
    
    // MARK: - Caching
    
    public func setObject(object: CacheObject, forKey key: String) {
        let filePath = directoryPath.stringByAppendingPathComponent(key)
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        // Save to file
        let data = NSKeyedArchiver.archivedDataWithRootObject(object)
        data.writeToFile(filePath, atomically: true)
        
        // Add entry
        entries = entries.filter { $0.0 != key }
        let entry = (key, NSDate())
        entries.append(entry)
        
        dispatch_semaphore_signal(semaphore)
        
        removeLeastRecentlyUsedObjects()
    }
    
    public func objectForKey(key: String) -> CacheObject? {
        let filePath = directoryPath.stringByAppendingPathComponent(key)
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        // Load file
        let object = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? CacheObject
        
        dispatch_semaphore_signal(semaphore)
        
        return object
    }
    
    public func removeObjectForKey(key: String) {
        let filePath = directoryPath.stringByAppendingPathComponent(key)
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        // Remove file
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(filePath) {
            var error: NSError?
            if !fileManager.removeItemAtPath(filePath, error: &error) {
                NSException.raise(error!.domain, format: "Error: %@", arguments: getVaList([error!.localizedDescription]))
            }
        }
        
        // Remove entry
        entries = entries.filter { $0.0 != key }
        
        dispatch_semaphore_signal(semaphore)
    }
    
    public func removeAllObjects() {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        // Remove all files
        let fileManager = NSFileManager.defaultManager()
        
        let enumerator = fileManager.enumeratorAtURL(
            NSURL(fileURLWithPath: directoryPath)!,
            includingPropertiesForKeys: [NSURLPathKey],
            options: .SkipsHiddenFiles,
            errorHandler: { (URL: NSURL!, error: NSError!) -> Bool in
                NSException.raise(error!.domain, format: "Error: %@", arguments: getVaList([error!.localizedDescription]))
                return false
            }
        )!
        
        while let fileURL = enumerator.nextObject() as? NSURL {
            var error: NSError?
            if !fileManager.removeItemAtPath(fileURL.path!, error: &error) {
                NSException.raise(error!.domain, format: "Error: %@", arguments: getVaList([error!.localizedDescription]))
            }
        }
        
        // Remove all entries
        entries.removeAll(keepCapacity: false)
        
        dispatch_semaphore_signal(semaphore)
    }
    
    public func hasObjectForKey(key: String) -> Bool {
        return (objectForKey(key) != nil)
    }
    
    public subscript(key: String) -> T? {
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
            for index in 0..<Int(count - countLimit) {
                removeObjectForKey(entries[index].0)
            }
        }
    }

}
