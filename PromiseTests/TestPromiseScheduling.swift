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
        var onExecuted = false
        let observableQueue = TestQueue(async: { work in
            onExecuted = true
            DispatchQueue.main.async(execute: work)
        }, asyncAfter: { deadline, work in
            DispatchQueue.main.asyncAfter(deadline: deadline, execute: work)
        })

        let p: Promise<Int, NoError> = Promise { resolver in
            // see if onStarted action has been already been executed.
            XCTAssertTrue(onExecuted)
            resolver.resolve(with: 42)
        }
        
        let exp = expectation(description: "")
        p.startOn(queue: observableQueue).whenComplete { _ in exp.fulfill() }
        waitForExpectations(timeout: 1.0)
    }
    
    func testCompleteOn() {

        enum Resolution { case resolved, rejected }
        
        func testCompleteOn(with resolution: Resolution) {
            var onExecuted = false
            let observableQueue = TestQueue(async: { work in
                onExecuted = true
                DispatchQueue.main.async(execute: work)
            }, asyncAfter: { deadline, work in
                DispatchQueue.main.asyncAfter(deadline: deadline, execute: work)
            })
            
            let p: Promise<Int, TestError> = Promise { resolver in
                // see if onCompleted action only executed _after_ this promise completed
                XCTAssertFalse(onExecuted)
                switch resolution {
                case .resolved: resolver.resolve(with: 42)
                case .rejected: resolver.reject(with: .error1)
                }
                
                XCTAssertTrue(onExecuted)
            }
            
            let exp = expectation(description: "")
            p.completeOn(queue: observableQueue).whenComplete { _ in exp.fulfill() }
            waitForExpectations(timeout: 1.0)
            
        }
        
        testCompleteOn(with: .resolved)
        testCompleteOn(with: .rejected)
        
    }
    
}
