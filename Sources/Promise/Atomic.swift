//
//  Atomic.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

final class Atomic<Value> {
  private let lock = NSLock()
  private var _value: Value
  private let didSetCallback: ((Value, Value) -> Void)?
  
  public init(_ value: Value, didSet: @escaping (Value, Value) -> Void) {
    _value = value
    didSetCallback = didSet
  }
  
  public init(_ value: Value) {
    _value = value
    didSetCallback = nil
  }
  
  
  @discardableResult
  public func modify<Result>(_ action: (inout Value) throws -> Result) rethrows -> Result {
    let oldValue = _value
    lock.lock()
    defer {
      lock.unlock()
      didSetCallback?(oldValue, _value)
    }
    
    return try action(&_value)
  }
  
  @discardableResult
  public func withValue<Result>(_ action: (Value) throws -> Result) rethrows -> Result {
    lock.lock()
    defer { lock.unlock() }
    
    return try action(_value)
  }
}
