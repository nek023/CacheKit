//
//  Cache.swift
//  CacheKit
//
//  Created by Katsuma Tanaka on 2015/03/12.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

import Foundation

public protocol Cache {
    
    associatedtype CacheObject
    
    func setObject(object: CacheObject, forKey key: String)
    func objectForKey(key: String) -> CacheObject?
    func removeObjectForKey(key: String) throws
    func removeAllObjects() throws
    func hasObjectForKey(key: String) -> Bool
    
    subscript(key: String) -> CacheObject? { get set }
    
    var count: UInt { get }
    var countLimit: UInt  { get set }

}
