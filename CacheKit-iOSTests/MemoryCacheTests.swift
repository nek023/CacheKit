//
//  MemoryCacheTests.swift
//  CacheKit
//
//  Created by Katsuma Tanaka on 2015/03/12.
//  Copyright (c) 2015年 Katsuma Tanaka. All rights reserved.
//

import Foundation
import XCTest
import CacheKit

class MemoryCacheTests: XCTestCase {
    
    private var cache: MemoryCache<String>!
    
    override func setUp() {
        super.setUp()
        
        cache = MemoryCache<String>()
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
        
        cache.removeObjectForKey("hoge")
        
        XCTAssertEqual(cache.count, UInt(1))
        
        cache.removeObjectForKey("piyo")
        
        XCTAssertEqual(cache.count, UInt(0))
        
        cache.removeObjectForKey("piyo")
        
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
            let object = cache.objectForKey("key\(number)")
            
            XCTAssertEqual(object ?? "", "value\(number)")
        }
    }
    
    func testCachingWithCountLimit() {
        cache.countLimit = 20
        
        for number in 0..<100 {
            cache["key\(number)"] = "value\(number)"
        }
        
        XCTAssertEqual(cache.count, UInt(20))
        
        for number in 80..<100 {
            let object = cache.objectForKey("key\(number)")
            
            XCTAssertEqual(object ?? "", "value\(number)")
        }
    }
    
    
    // MARK: - Performance Tests
    
    private var numberOfElements = 100
    
    func testNSCacheWritingPerformance() {
        let cache = NSCache()
        
        measureBlock {
            for number in 0..<self.numberOfElements {
                cache.setObject("\(number)", forKey: "\(number)")
            }
        }
    }
    
    func testWritingPerformance() {
        measureBlock {
            for number in 0..<self.numberOfElements {
                self.cache.setObject("\(number)", forKey: "\(number)")
            }
        }
    }
    
    func testNSCacheReadingPerformance() {
        let cache = NSCache()
        for number in 0..<numberOfElements {
            cache.setObject("\(number)", forKey: "\(number)")
        }
        
        measureBlock {
            for number in 0..<self.numberOfElements {
                if let object = cache.objectForKey("\(number)") as? NSString {
                    XCTAssertEqual(object, "\(number)")
                } else {
                    XCTFail()
                }
            }
        }
    }
    
    func testReadingPerformance() {
        for number in 0..<numberOfElements {
            cache.setObject("\(number)", forKey: "\(number)")
        }
        
        measureBlock {
            for number in 0..<self.numberOfElements {
                if let object = self.cache.objectForKey("\(number)") {
                    XCTAssertEqual(object, "\(number)")
                } else {
                    XCTFail()
                }
            }
        }
    }

}
