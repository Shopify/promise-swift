//
//  PromiseExtensions.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

extension Promise {
  
  private func commonThen<T1, E1>(transform: @escaping (Result<T, E>) -> Promise<T1, E1>) -> Promise<T1, E1> {
    return Promise<T1, E1> { resolver in
      let serialQueue = DispatchQueue(label: "serialiazation")
      
      var innerCancel: PromiseCancelFunction = {}
      var cancelled = false
      self.whenComplete { result in
        var safeCancelled: Bool!
        serialQueue.sync { safeCancelled = cancelled }
        
        guard safeCancelled == false else { return }
        
        let innerPromise = transform(result)
        serialQueue.sync { innerCancel = innerPromise.cancel }
        innerPromise.whenComplete(callback: resolver.complete)
        
      }
      resolver.onCancel = {
        serialQueue.sync {
          cancelled = true
          innerCancel()
        }
      }
    }
  }
  
  
  /// Promise transformation using asynchronous value transformation
  /// 
  /// Creates a `Promise` that represents a sequence of async computations.
  /// When current `Promise` resolves with value (not rejects with error) `transform` is called 
  /// to create another `Promise` representing next asynchronous operation, which is automatically
  /// subscribed to. Complete event of that `Promise` is a complete event of `Promise` returned by 
  /// this method (either success or error).
  /// When current `Promise` rejects, `Promise` returned by this method rejects immediately 
  /// and `transform` is not called.
  ///
  /// - Parameters:
  ///   - transform: function creating next `Promise` in the sequence.
  /// - Returns: `Promise` instance that represents result of sequence of async operations.
  
  public func then<V>(transform: @escaping (T) -> Promise<V, E>) -> Promise<V, E> {
    
    return self.commonThen { result in
      switch result {
      case .success(let value):
        return transform(value)
      case .error(let e):
        return Promise<V, E>(error: e)
      }
    }
  }
  
  
  /// romise transformation using asynchronous error transformation
  ///
  /// Technically, this chaning works the same way as `then` except in case current `Promise` rejects with error
  /// In practice, this could be used as async computation failure recovery. 
  /// Resulting `Promise` will not fail right away, instead will try to recover from error 
  /// by invoking computation of another `Promise`.
  /// In case current `Promise` resolves with success value — that value is directly forwarded as value of 
  /// resulting `Promise`.
  ///
  /// - Parameter transform: function creating next `Promise` in the sequence.
  /// - Returns: `Promise` instance that represents result of sequence of async operations.
  
  public func ifErrorThen<EV>(transform: @escaping (E) -> Promise<T, EV>) -> Promise<T, EV> {
    return self.commonThen { result in
      switch result {
      case .success(let v):
        return Promise<T, EV>(value: v)
      case .error(let e):
        return transform(e)
      }
    }
  }
  
  
  /// Promise transformation using synchronous value transformation
  ///
  /// This creates new `Promise` whose resolved value will be the one current `Promise`
  /// resolved with after applying `transformation` function to it. In case current `Promise`
  /// rejects with error — resulting `Promise` behaves as current one.
  ///
  /// - Parameter transform: synchronous value transformation function
  /// - Returns: new `Promise` whose value is a result of `Promise` trnsformation
  
  public func map<V>(transform: @escaping (T) -> V) -> Promise<V, E> {
    return self.then { value in
      return Promise<V, E>(value: transform(value))
    }
  }
  
  
  /// Promise transformation using synchronous error transformation
  ///
  /// This creates new `Promise` whose reject error will be the one current `Promise`
  /// rejected with after applying `transformation` function to it. In case current `Promise`
  /// resolves with value — resulting `Promise` behaves as current one.
  ///
  /// - Parameter transform: synchronous error transformation function
  /// - Returns: new `Promise` whose error (if any) is a result of `Promise` error trnsformation
  
  public func mapError<EE: Error>(transform: @escaping (E) -> EE) -> Promise<T, EE> {
    return self.ifErrorThen { error in
      return Promise<T, EE>(error: transform(error))
    }
  }
}



