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


