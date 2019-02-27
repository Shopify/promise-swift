//
//  PromiseExtension.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

public protocol DispatchQueueType {
  func async(execute work: DispatchWorkItem)
  func asyncAfter(deadline: DispatchTime, execute work: DispatchWorkItem)
}

extension DispatchQueue: DispatchQueueType {}

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
  
  public func completeOn(queue: DispatchQueueType) -> Promise {
    return Promise { resolver in
      self.whenComplete { result in
        queue.async(execute: DispatchWorkItem { resolver.complete(result) } )
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
  /// - Returns: new `Promise` instance.
  
  public func startOn(queue: DispatchQueueType) -> Promise {
    return Promise { resolver in
      let workItem = DispatchWorkItem {
        self.whenComplete(callback: resolver.complete)
      }
      queue.async(execute: workItem)
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
  
  public func delayed(for delay: DispatchTimeInterval, on queue: DispatchQueueType = DispatchQueue.main) -> Promise {
    return Promise { resolver in
      self.whenComplete { result in
        queue.asyncAfter(deadline: .now() + delay, execute: DispatchWorkItem {
          resolver.complete(result)
        })
      }
    }
  }
  
}


