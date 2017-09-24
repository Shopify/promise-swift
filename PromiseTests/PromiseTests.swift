//
//  PromiseTests.swift
//  PromiseTests
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import XCTest
import Promise

extension Result where T: Equatable, E: Equatable {
  func isEqual(to result: Result) -> Bool {
    switch (self, result) {
    case (.success(let lhs), .success(let rhs)): return lhs == rhs
    case (.error(let lhs), .error(let rhs)): return lhs == rhs
    default: return false
    }
  }
}

enum TestError: Error {
  case error1, error2
}


extension TestError: Equatable {
  static func ==(lhs: TestError, rhs: TestError) -> Bool {
    switch (lhs, rhs) {
    case (.error1, .error1), (.error2, .error2): return true
    default: return false
    }
  }
}


extension Array where Element: Equatable {
  public func isEqual(to another: Array<Element>) -> Bool {
    guard self.count == another.count else { return false }
    
    return zip(self, another).filter { $0.0 != $0.1 }.count == 0
  }
}

func makeAsyncPromise<V>(result: Result<V, TestError>, delay: DispatchTimeInterval) -> Promise<V, TestError> {
  return Promise<V, TestError> { resolver in
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      resolver.complete(result)
    }
  }
}


class PromiseTests: XCTestCase {
  
  func XCTAssertPromiseResult<V: Equatable, E: Equatable>(
    _ promise: Promise<V, E>,
    result: Result<V, E>,
    after delay: TimeInterval,
    file: StaticString = #file,
    line: UInt = #line) {
    
    let exp = expectation(description: "")
    var expected: Result<V, E>?
    promise.whenComplete { result in
      expected = result
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: delay)
    XCTAssert(expected?.isEqual(to: result) ?? false, file: file, line: line)
    
  }
  
  
  func XCTAssertPromiseValue<V: Equatable, E: Equatable>(_ promise:Promise<V, E>, value:V, after delay: TimeInterval, file: StaticString = #file, line: UInt = #line) {
    XCTAssertPromiseResult(promise, result: .success(value), after: delay, file: file, line: line)
  }
  
  func XCTAssertPromiseError<V: Equatable, E: Equatable>(_ promise:Promise<V, E>, error: E, after delay: TimeInterval, file: StaticString = #file, line: UInt = #line) {
    XCTAssertPromiseResult(promise, result: .error(error), after: delay, file: file, line: line)
  }
  
  
  func testPromiseUnit() {
    
    XCTAssertPromiseValue(Promise<Int, TestError>(value: 42), value: 42, after: 0)
    
    XCTAssertPromiseError(Promise<Int, TestError>(error: .error2), error: .error2, after: 0)
  }
  
  func testPromiseAsync() {
    let promise = makeAsyncPromise(result: .success(42), delay: .milliseconds(100))
    
    XCTAssertPromiseValue(promise, value: 42, after: 101)
  }
  
  func testPsomiseRetainValue() {
    
    let promise = makeAsyncPromise(result: .success(42), delay: .milliseconds(100))
    
    
    promise.whenComplete {_ in}
    
    let exp = expectation(description: "delay")
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
      exp.fulfill()
    }
    
    waitForExpectations(timeout: 301)
    self.XCTAssertPromiseValue(promise, value: 42, after: 101)
  }
  
  func testNonCancellablePromiseCancel() {
    let promise = makeAsyncPromise(result: .success(42), delay: .milliseconds(100))
    var received = false
    promise.whenComplete { _ in received = true }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
      promise.cancel()
    }
    
    //wait for 200 ms and check if callback called
    let exp = expectation(description: "")
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
      exp.fulfill()
    }
    waitForExpectations(timeout: 0.21)
    XCTAssertFalse(received)
  }
  
  func testCancellablePromiseCancel() {
    var cancelled = false
    let promise = Promise<Void, TestError> { resolver in
      resolver.onCancel = { cancelled = true }
    }
    
    //start
    promise.whenComplete {_ in }
    promise.cancel()
    
    XCTAssertTrue(cancelled)
  }
  
  func verifytCancelled<T, E>(promise: Promise<T, E>,
                              after delay: DispatchTimeInterval,
                              file: StaticString = #file,
                              line: UInt = #line) {
    
    promise.cancel()
    var recevied = false
    promise.whenComplete { _ in
      recevied = true
    }
    
    let exp = expectation(description: "delay")
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      exp.fulfill()
    }
    
    waitForExpectations(timeout: 10)
    XCTAssertFalse(recevied, file: file, line: line)
  }
  
  func testCancelledPromiseSubscribe() {
    
    
    verifytCancelled(promise: Promise<Int, NoError>(value: 42), after: .milliseconds(10))
    verifytCancelled(promise: Promise<Int, TestError>(error: .error1), after: .milliseconds(10))
    verifytCancelled(
      promise: makeAsyncPromise(result: .success(42), delay: .milliseconds(1)),
      after: .milliseconds(10))
  }
  
  func testThen() {
    let p1 = makeAsyncPromise(result: .success(42), delay: .milliseconds(100))
    let p2 = {(v: Int) in
      makeAsyncPromise(result: .success(v + 10), delay: .milliseconds(100))
    }
    
    let promise = p1.then(transform: p2)
    
    XCTAssertPromiseValue(promise, value: 52, after: 0.300)
  }
  
  func testIfErrorThen() {
    let promise = makeAsyncPromise(result: .error(.error1), delay: .milliseconds(100))
      .ifErrorThen { _ in
        return makeAsyncPromise(result: .success(42), delay: .milliseconds(100))
    }
    
    XCTAssertPromiseValue(promise, value: 42, after: 0.300)
  }
  
  func testThenCancellation() {
    var thenPromiseCalled = false
    let promise: Promise<Int, TestError> = makeAsyncPromise(result: .success(42), delay: .milliseconds(100))
      .then { _ in
        thenPromiseCalled = true
        return Promise<Int, TestError>(value: 42)
    }
    
    
    //start
    promise.whenComplete {_ in }
    promise.cancel()
    
    let exp = expectation(description: "")
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(101)) {
      exp.fulfill()
    }
    waitForExpectations(timeout: 0.2)
    XCTAssertFalse(thenPromiseCalled)
  }
  
  func testPromiseAllSuccess() {
    
    let promises: [Promise<Int, TestError>] = [200, 150, 300, 250, 100]
      .enumerated()
      .map { index, delay in
        makeAsyncPromise(result: .success(index), delay: .milliseconds(delay))
    }
    
    let all = Promise.all(promises).map(transform: EquatableArray.init)
    XCTAssertPromiseValue(all, value: EquatableArray([0, 1, 2, 3, 4]), after: 0.400)
  }
  
  func testPromiseAllFail() {
    
    let promises: [Promise<Int, TestError>] = [200, 150, 300, 250, 100]
      .enumerated()
      .map { index, delay in
        makeAsyncPromise(result: .success(index), delay: .milliseconds(delay))
    }
    let failePromise: Promise<Int, TestError> = makeAsyncPromise(result: .error(.error1), delay: .milliseconds(50))
    
    let all = Promise.all([promises, [failePromise]].joined()).map(transform: EquatableArray.init)
    XCTAssertPromiseError(all, error: .error1, after: 0.100)
  }
  
  func testPromiseAllCancelOnFail() {
    let exp = expectation(description: "cancelled called")
    let successPromise = Promise<Int, TestError> { resolver in
      resolver.onCancel = {
        exp.fulfill()
      }
    }
    let failPromise: Promise<Int, TestError> = makeAsyncPromise(result: .error(.error1), delay: .milliseconds(50))
    
    
    let all = Promise.all([successPromise, failPromise])
    all.whenComplete {_ in }
    waitForExpectations(timeout: 0.100)
  }
  
  
  func testPromiseAllHeterogeneous2() {
    
    let all = Promise<Void, TestError>.all(
      makeAsyncPromise(result: .success(42), delay: .milliseconds(100)),
      makeAsyncPromise(result: .success("42"), delay: .milliseconds(100))
      )
      .map(transform: TupleBox2.init)
    
    
    
    XCTAssertPromiseValue(all, value: TupleBox2(42, "42"), after: 0.200)
  }
  
  func testPromiseAllHeterogeneous3() {
    
    let all = Promise<Void, TestError>.all(
      makeAsyncPromise(result: .success(42), delay: .milliseconds(100)),
      makeAsyncPromise(result: .success("42"), delay: .milliseconds(100)),
      makeAsyncPromise(result: .success(false), delay: .milliseconds(100))
      )
      .map(transform: TupleBox3.init)
    
    
    
    XCTAssertPromiseValue(all, value: TupleBox3(42, "42", false), after: 0.200)
  }
  
  func testPromiseAllHeterogeneous4() {
    
    let all = Promise<Void, TestError>.all(
      makeAsyncPromise(result: .success(42), delay: .milliseconds(100)),
      makeAsyncPromise(result: .success("42"), delay: .milliseconds(100)),
      makeAsyncPromise(result: .success(false), delay: .milliseconds(100)),
      makeAsyncPromise(result: .success(24), delay: .milliseconds(100))
      )
      .map(transform: TupleBox4.init)
    
    
    
    XCTAssertPromiseValue(all, value: TupleBox4(42, "42", false, 24), after: 0.200)
  }
  
  
  struct EquatableArray<T: Equatable>: Equatable {
    private let array: [T]
    init(_ array: [T]) {
      self.array = array
    }
    
    static func ==(lhs: EquatableArray, rhs: EquatableArray) -> Bool {
      return lhs.array.isEqual(to: rhs.array)
    }
  }
  
  
  struct TupleBox2<T1: Equatable, T2: Equatable>: Equatable {
    private var v1: T1
    private var v2: T2
    init(_ v1: T1, _ v2: T2) {
      self.v1 = v1
      self.v2 = v2
    }
    
    public static func ==(lhs: TupleBox2, rhs: TupleBox2) -> Bool {
      return lhs.v1 == rhs.v1 && lhs.v2 == rhs.v2
    }
  }
  
  struct TupleBox3<T1: Equatable, T2: Equatable, T3: Equatable>: Equatable {
    private var v1: T1
    private var v2: T2
    private var v3: T3
    init(_ v1: T1, _ v2: T2, _ v3: T3) {
      self.v1 = v1
      self.v2 = v2
      self.v3 = v3
    }
    
    public static func ==(lhs: TupleBox3, rhs: TupleBox3) -> Bool {
      return lhs.v1 == rhs.v1 && lhs.v2 == rhs.v2 && lhs.v3 == rhs.v3
    }
  }
  
  struct TupleBox4<T1: Equatable, T2: Equatable, T3: Equatable, T4: Equatable>: Equatable {
    private var v1: T1
    private var v2: T2
    private var v3: T3
    private var v4: T4
    init(_ v1: T1, _ v2: T2, _ v3: T3, _ v4: T4) {
      self.v1 = v1
      self.v2 = v2
      self.v3 = v3
      self.v4 = v4
    }
    
    public static func ==(lhs: TupleBox4, rhs: TupleBox4) -> Bool {
      return lhs.v1 == rhs.v1 && lhs.v2 == rhs.v2 && lhs.v3 == rhs.v3 && lhs.v4 == rhs.v4
    }
  }
  
}
