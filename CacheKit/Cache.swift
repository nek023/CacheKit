//
//  Cache.swift
//  CacheKit
//
//  Created by Katsuma Tanaka on 2015/03/12.
//  Copyright (c) 2015年 Katsuma Tanaka. All rights reserved.
//

import Foundation

public protocol Cache {
    
    typealias CacheObject
    
    func setObject(object: CacheObject, forKey key: String)
    func objectForKey(key: String) -> CacheObject?
    func removeObjectForKey(key: String)
    func removeAllObjects()
    func hasObjectForKey(key: String) -> Bool
    
    subscript(key: String) -> CacheObject? { get set }

}
