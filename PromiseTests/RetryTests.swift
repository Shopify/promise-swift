//
//  RetryTests.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-08-21.
//  Copyright © 2017 Shopify. All rights reserved.
//

import XCTest
import Promise

class RetryTests: XCTestCase {

    func makeFailingPromiseGenerator(fails count: Int) -> (() -> Promise<Int, TestError>) {
        var runningCount = count
        func makeFailingPromise() -> Promise<Int, TestError> {
            return Promise { resolver in
                if (runningCount > 0) {
                    runningCount -= 1
                    resolver.reject(with: .error1)
                } else {
                    resolver.resolve(with: 42)
                }
            }
        }
        return makeFailingPromise
    }
    
    func testRetry() {
        
        let p1 = Promise.attempt(times: 5, promiseGenrator: makeFailingPromiseGenerator(fails: 3))
        XCTAssertPromiseResult(p1, result: .success(42), after: 2)
        
        let p2 = Promise.attempt(times: 2, promiseGenrator: makeFailingPromiseGenerator(fails: 3))
        XCTAssertPromiseResult(p2, result: .error(.error1), after: 2)
    }
    
}
