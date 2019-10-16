//
//  PromiseNoError.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

extension Promise where E == NoError {
  
  
  /// Subscribes to `Promise` result unwrapping the value.
  ///
  /// This method invokes `whenComplete` e.g. autostarts Promise if it hasnt' been started yet.
  /// Since this `Promise`type guarantees it never rejects, this method automatically unwraps 
  /// `result` type etracting resolution value.
  ///
  /// - Parameter callback: subscription callback to invoked when `Promise` completes.
  /// - Parameter value: value `Promise` has been resolved with.
  /// - Returns: returns `self` instance of current `Promise`, useful for call chaining purposes.
  
  @discardableResult
  public func whenSuccess(_ callback: @escaping (_ value: T) -> Void) -> Self {
    return self.whenComplete { result in
      switch result {
      case .success(let v): callback(v)
      case .error: fatalError()
      }
    }
  }
  
  
  /// Transforms `Promise` type.
  ///
  /// Creates new `Promise` is typed as possibly rejecting with error of given type.
  /// As current `Promise` never rejects (type `NoError` guarantees that)
  /// new `Promise` is in fact never rejects as well, but type is not `NoError` and doesn't guarantee that.
  /// Such type transforming is useful when non-rejecting `Promise` has be to chained or combined with other
  /// rejecting `Promise` (as error types have to match).
  ///
  /// - Returns: new `Promise` instance
  public func promoteErrors<En: Error>() -> Promise<T, En> {
    return self.mapError {_ in
      //will never get there
      fatalError()
    }
  }
  
}

extension Promise {
  
  /// Ignores any rejection in the `Promise`
  ///
  /// Creates new `Promise` that ignores any error completion and does nothing in that case.
  /// E.g. it eats errors.
  /// In case current `Promise` resolves, resulting `Promise` behaviour is equivalent to current one.
  ///
  /// - Returns: new `Promise` instance
  
  public func ignoreErrors() -> Promise<T, NoError> {
    return self.ifErrorThen { _ in
      return Promise<T, NoError>.never()
    }
  }
  
  
  /// Promise that never completes (neither resolves nor rejects)
  ///
  /// Useful for chaning/combining algorithms
  ///
  /// - Returns: new `Promise` instance
  public static func never() -> Promise {
    return Promise {_ in }
  }
}
