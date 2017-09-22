//
//  PrimseSideEffects.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-18.
//  Copyright © 2017 Shopify. All rights reserved.
//

import XCTest
import Promise

class PrimseSideEffects: XCTestCase {
  
  func verifyOnStart<T, E>(for promise: Promise<T,E>, file: StaticString = #file, line:UInt = #line) {
    var called = false
    promise
      .onStart {_ in called = true }
      .whenComplete {_ in }
    XCTAssertTrue(called, file: file, line: line)
  }
  
  func verifyOnComplete<T, E>(called: Bool, for promise: Promise<T,E>, timeout: DispatchTimeInterval = .milliseconds(0), file: StaticString = #file, line:UInt = #line) {
    var actualCalled = false
    let exp = expectation(description: "waiting")
    promise
      .onComplete {_ in actualCalled = true }
      .whenComplete {_ in }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
      exp.fulfill()
    }
    wait(for: [exp], timeout: 10)
    XCTAssertEqual(actualCalled, called, file: file, line: line)
  }
  
  enum CallResut<T: Equatable>: Equatable {
    case called(T)
    case notCalled
    
    static func==(lhs: CallResut, rhs: CallResut) -> Bool {
      switch (lhs, rhs) {
      case (.called(let lhsValue), .called(let rhsValue)): return lhsValue == rhsValue
      case (.notCalled, .notCalled): return true
      default: return false
      }
    }
  }
  
  
  func verifyOnSuccess<T, E>(_ called: CallResut<T>, for promise: Promise<T,E>, timeout: DispatchTimeInterval = .milliseconds(0), file: StaticString = #file, line:UInt = #line) {
    var actualValue: CallResut<T> = .notCalled
    let exp = expectation(description: "waiting")
    promise
      .onSuccess { value in actualValue = .called(value) }
      .whenComplete {_ in }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
      exp.fulfill()
    }
    wait(for: [exp], timeout: 10)
    XCTAssertEqual(actualValue, called, file: file, line: line)
  }
  
  func verifyOnError<T, E>(_ called: CallResut<E>, for promise: Promise<T,E>, timeout: DispatchTimeInterval = .milliseconds(0), file: StaticString = #file, line:UInt = #line) {
    var actualValue: CallResut<E> = .notCalled
    let exp = expectation(description: "waiting")
    promise
      .onError { value in actualValue = .called(value) }
      .whenComplete {_ in }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
      exp.fulfill()
    }
    wait(for: [exp], timeout: 10)
    XCTAssertEqual(actualValue, called, file: file, line: line)
  }
  
  func testOnStart() {
    verifyOnStart(for: Promise<Int, NoError>(value: 42))
    verifyOnStart(for: Promise<Int, TestError>(error: .error1))
    verifyOnStart(for: makeAsyncPromise(result: .success(42), delay: .milliseconds(10)))
  }
  
  func testOnComplete() {
    verifyOnComplete(called: true, for: Promise<Int, NoError>(value: 42))
    verifyOnComplete(called: true, for: Promise<Int, TestError>(error: .error1))
    verifyOnComplete(called: false, for: Promise<Int, NoError>.never())
    verifyOnComplete(called: true, for: makeAsyncPromise(result: .success(42), delay: .milliseconds(10)), timeout: .milliseconds(20))
  }
  
  func testOnSuccess() {
    verifyOnSuccess(.called(42), for: Promise<Int, NoError>(value: 42))
    verifyOnSuccess(.notCalled, for: Promise<Int, TestError>(error: .error1))
    verifyOnSuccess(.notCalled, for: Promise<Int, NoError>.never())
    verifyOnSuccess(.called(42), for: makeAsyncPromise(result: .success(42), delay: .milliseconds(10)), timeout: .milliseconds(20))
  }
  
  func testOnError() {
    verifyOnError(.notCalled, for: Promise<Int, TestError>(value: 42))
    verifyOnError(.called(TestError.error1), for: Promise<Int, TestError>(error: .error1))
    verifyOnError(.notCalled, for: Promise<Int, TestError>.never())
    verifyOnError(.notCalled, for: makeAsyncPromise(result: .success(42), delay: .milliseconds(10)), timeout: .milliseconds(20))
  }
  
}
