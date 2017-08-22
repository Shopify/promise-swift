//
//  PromiseExtension.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

extension Promise {
  
  
  /// Dispatch `Promise` completion event on a queue.
  /// 
  /// Creates new `Promise` which is guaranteed to call on observers with completion event
  /// (either rejection or resolution) on a given GCD queue.
  /// **Note**: this does not modify current `Promise`, only returned instance is guaranteed to 
  /// to use queue for scheduling.
  ///
  /// - Parameter queue: queue to schedule observers callback on
  /// - Returns: new `Promise` instance.
  
  public func completeOn(queue: DispatchQueue) -> Promise {
    return Promise { resolver in
      self.whenComplete { result in
        queue.async { resolver.complete(result) }
      }
    }
  }
  
  
  /// Dispatch `Promise` async operation
  ///
  /// Creates new `Promise` whose start function dispatches execution of current `Promise`'s one on a
  /// given GCD queue.
  /// **Note**: this does not modify current `Promise`, only returned instance is guaranteed to
  /// to use queue for scheduling.
  ///
  /// - Parameter queue: GCD queue to schedule start operation on
  /// - Returns: new `Promise`instance.
  
  public func srartOn(queue: DispatchQueue) -> Promise {
    return Promise { resolver in
      queue.async {
        self.whenComplete(callback: resolver.complete)
      }
      resolver.onCancel = { self.cancel() }
    }
  }
  
  
  /// Injects a delay in async computation process.
  ///
  /// Creates new `Promise` which adds a given delay (using `disatchAfter` on a given queue)
  /// before notifying observers about completion event (both resolution and rejection).
  ///
  /// - Parameters:
  ///   - delay: delay to add before notifying observers
  ///   - queue: queue to schedule `dispatchAfter` on
  /// - Returns: new `Promise` instance.
  
  public func delayed(for delay: DispatchTimeInterval, on queue: DispatchQueue = DispatchQueue.main) -> Promise {
    return Promise { resolver in
      self.whenComplete { result in
        queue.asyncAfter(deadline: .now() + delay) {
          resolver.complete(result)
        }
      }
    }
  }
  
}


extension Promise {
  
  /// Creates retry promise based off given promise
  ///
  /// This will create a Promise that can recover from failure.
  /// Generator is used to create action promise that can fail. Since Promise retains
  /// it's failure status, need to create new filable action Promise on every attempt.
  /// Resulting Promise will wait repeat up until `count` retries after which will reject
  /// with the error underlying process was rejected with.
  /// - Parameters:
  ///   - count: number of attempts to try.
  ///   - promiseGenrator: function generating new Promise to try.
  /// - Returns: new Promise instance.
  public static func attempt(times count: Int, promiseGenrator: @escaping () -> Promise) -> Promise {

    func tryPromise(attemptsLeft: Int, promiseGenerator: @escaping () -> Promise, resolver: PromiseResolver<T, E>) {
      let runningPromise = promiseGenrator()
      resolver.onCancel = { runningPromise.cancel() }
      
      runningPromise.whenComplete { result in
        switch result {
        case .success(let value): resolver.resolve(with: value)
        case .error(let error):
          if attemptsLeft > 0 {
            tryPromise(attemptsLeft: attemptsLeft - 1, promiseGenerator: promiseGenrator, resolver: resolver)
          } else {
            resolver.reject(with: error)
          }
        }
      }
    }

    return Promise { resolver in
      tryPromise(attemptsLeft: count, promiseGenerator: promiseGenrator, resolver: resolver)
    }
  }
  
  
  
  /// Creates retry promise based off given promise
  ///
  /// This will create a Promise that can recover from failure.
  /// Generator is used to create action promise that can fail. Since Promise retains
  /// it's failure status, need to create new filable action Promise on every attempt.
  /// Resulting Promise will wait repeat up until `count` retries after which will reject
  /// with the error underlying process was rejected with.
  /// - Parameters:
  ///   - count: number of attempts to try.
  ///   - promiseGenrator: function generating new Promise to try.
  /// - Returns: new Promise instance.
  public static func attempt2(times count: UInt, promiseGenrator: @escaping () -> Promise) -> Promise {
    guard count > 0 else { return promiseGenrator() }
    
    return promiseGenrator().ifErrorThen { _ in
      return Promise.attempt2(times: count - 1, promiseGenrator: promiseGenrator)
    }
  }
}

