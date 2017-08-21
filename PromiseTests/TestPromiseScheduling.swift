//
//  TestPromiseScheduling.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-08-08.
//  Copyright © 2017 Shopify. All rights reserved.
//

import XCTest
import Promise

class TestPromiseScheduling: XCTestCase {
    
    struct TestQueue: DispatchQueueType {
        
        let asyncFunc: (DispatchWorkItem) -> Void
        let asyncAfterFunc: (DispatchTime, DispatchWorkItem) -> Void
        
        init(async: @escaping (DispatchWorkItem) -> Void, asyncAfter: @escaping (DispatchTime, DispatchWorkItem) -> Void) {
            asyncFunc = async
            asyncAfterFunc = asyncAfter
        }
        
        func async(execute work: DispatchWorkItem) {
            asyncFunc(work)
        }
        
        func asyncAfter(deadline: DispatchTime, execute work: DispatchWorkItem) {
            asyncAfterFunc(deadline, work)
        }
    }
    
    func testStartOn() {
        let p: Promise<Int, TestError> = makeAsyncPromise(result: .success(42), delay: .milliseconds(200))
        
        var onExecuted = false
        let observableQueue = TestQueue(async: { work in
            onExecuted = true
            DispatchQueue.main.async(execute: work)
        }, asyncAfter: { deadline, work in
            DispatchQueue.main.asyncAfter(deadline: deadline, execute: work)
        })
        
        let exp = expectation(description: "")
        p.startOn(queue: observableQueue).whenComplete { _ in exp.fulfill() }
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(onExecuted)
    }
    
}
