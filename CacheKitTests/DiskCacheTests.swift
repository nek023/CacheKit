//
//  DiskCacheTests.swift
//  CacheKit
//
//  Created by Katsuma Tanaka on 2015/03/13.
//  Copyright (c) 2015 Katsuma Tanaka. All rights reserved.
//

import Foundation
import XCTest
import CacheKit

class DiskCacheTests: XCTestCase {
    
    private var cache: DiskCache<NSString>!
    
    override func setUp() {
        super.setUp()
        
        cache = try! DiskCache<NSString>(directoryPath: directoryPath)
    }
    
    override func tearDown() {
        try! cache.removeAllObjects()
        
        super.tearDown()
    }
    
    var directoryPath: String {
        var directoryPath = NSTemporaryDirectory()
        if let bundleIdentifier = NSBundle(forClass: self.dynamicType).bundleIdentifier {
            directoryPath = (directoryPath as NSString).stringByAppendingPathComponent(bundleIdentifier)
        }
        
        return directoryPath
    }

    func testInitialization() {
        XCTAssertEqual(cache.count, UInt(0))
        XCTAssertEqual(cache.countLimit, UInt(0))
    }
    
    func testAccessors() {
        cache.setObject("piyo", forKey: "hoge")
        let object = cache.objectForKey("hoge")
        
        XCTAssertEqual(object ?? "", "piyo")
    }
    
    func testSubscription() {
        cache["hoge"] = "piyo"
        let object = cache["hoge"]
        
        XCTAssertEqual(object ?? "", "piyo")
    }
    
    func testCount() {
        cache["hoge"] = "hoge"
        cache["piyo"] = "piyo"
        
        XCTAssertEqual(cache.count, UInt(2))
        
        try! cache.removeObjectForKey("hoge")
        
        XCTAssertEqual(cache.count, UInt(1))
        
        try! cache.removeObjectForKey("piyo")
        
        XCTAssertEqual(cache.count, UInt(0))
        
        try! cache.removeObjectForKey("piyo")
        
        XCTAssertEqual(cache.count, UInt(0))
    }
    
    func testCountLimit() {
        cache.countLimit = 2
        
        cache["0"] = "0"
        cache["1"] = "1"
        cache["2"] = "2"
        
        XCTAssertEqual(cache.count, UInt(2))
        XCTAssertFalse(cache.hasObjectForKey("0"))
        XCTAssertTrue(cache.hasObjectForKey("1"))
        XCTAssertTrue(cache.hasObjectForKey("2"))
    }
    
    func testCaching() {
        for number in 0..<100 {
            cache["key\(number)"] = "value\(number)"
        }
        
        XCTAssertEqual(cache.count, UInt(100))
        
        for number in 0..<100 {
            if let object = cache.objectForKey("key\(number)") {
                XCTAssertTrue(object.isEqualToString("value\(number)"))
            } else {
                XCTFail()
            }
        }
    }
    
    func testCachingWithCountLimit() {
        cache.countLimit = 20
        
        for number in 0..<100 {
            cache["key\(number)"] = "value\(number)"
        }
        
        XCTAssertEqual(cache.count, UInt(20))
        
        for number in 80..<100 {
            if let object = cache.objectForKey("key\(number)") {
                XCTAssertTrue(object.isEqualToString("value\(number)"))
            } else {
                XCTFail()
            }
        }
    }

}
