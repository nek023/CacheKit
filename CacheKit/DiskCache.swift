//
//  DiskCache.swift
//  CacheKit
//
//  Created by Katsuma Tanaka on 2015/03/13.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

import Foundation

public class DiskCache<CacheObject: NSCoding>: Cache {
    
    // MARK: - Properties
    
    private let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(1)
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
    
    public init(directoryPath: String) throws {
        self.directoryPath = directoryPath
        
        // Create directory if necessary
        let fileManager = NSFileManager.defaultManager()

        if !fileManager.fileExistsAtPath(directoryPath) {
            try fileManager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
        }

        // Get file list
        let enumerator = fileManager.enumeratorAtURL(
            NSURL(fileURLWithPath: directoryPath),
            includingPropertiesForKeys: [NSURLPathKey],
            options: .SkipsHiddenFiles,
            errorHandler: { (URL: NSURL, error: NSError) -> Bool in
                return false
            }
        )!
        
        while let fileURL = enumerator.nextObject() as? NSURL {
            let filePath = fileURL.path!
            let attributes = try fileManager.attributesOfItemAtPath(filePath)
            if let modificationDate = attributes[NSFileModificationDate] as? NSDate {
                entries.append((filePath.lastPathComponent, modificationDate))
            } else {
                let date = NSDate()
                entries.append((filePath.lastPathComponent, date))
            }
        }
        
        entries.sortInPlace { return ($0.1.compare($1.1) == .OrderedAscending) }

    }

    public convenience init(directoryURL: NSURL) throws {
        try self.init(directoryPath: directoryURL.path!)
    }
    
    public convenience init() throws {
        var directoryPath = NSTemporaryDirectory()
        if let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier {
            directoryPath = directoryPath.stringByAppendingPathComponent(bundleIdentifier)
        }
        
        try self.init(directoryPath: directoryPath)
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
        if !hasObjectForKey(key) {
            return nil
        }
        
        let filePath = directoryPath.stringByAppendingPathComponent(key)
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        // Load file
        let object = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? CacheObject
        
        dispatch_semaphore_signal(semaphore)
        
        return object
    }
    
    public func removeObjectForKey(key: String) throws {
        if !hasObjectForKey(key) {
            return
        }
        
        let filePath = directoryPath.stringByAppendingPathComponent(key)
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        defer { dispatch_semaphore_signal(semaphore) }
        
        // Remove file
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(filePath) {
            try fileManager.removeItemAtPath(filePath)
        }
        
        // Remove entry
        entries = entries.filter { $0.0 != key }
    }
    
    public func removeAllObjects() throws {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        defer { dispatch_semaphore_signal(semaphore) }
        
        // Remove all files
        let fileManager = NSFileManager.defaultManager()
        
        for entry in entries {
            let filePath = directoryPath.stringByAppendingPathComponent(entry.0)
            try fileManager.removeItemAtPath(filePath)
        }
        
        // Remove all entries
        entries.removeAll(keepCapacity: false)
    }
    
    public func hasObjectForKey(key: String) -> Bool {
        for entry in entries {
            if entry.0 == key {
                return true
            }
        }
        
        return false
    }
    
    public subscript(key: String) -> CacheObject? {
        get {
            return objectForKey(key)
        }
        
        set {
            if let object = newValue {
                setObject(object, forKey: key)
            } else {
                _ = try? removeObjectForKey(key)
            }
        }
    }
    
    private func removeLeastRecentlyUsedObjects() {
        if 0 < countLimit && countLimit < count {
            for index in 0..<Int(count - countLimit) {
                _ = try? removeObjectForKey(entries[index].0)
            }
        }
    }

}

// MARK: String Extension (Private)

extension String {

    private var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }

    private func stringByAppendingPathComponent(str: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(str)
    }

}
