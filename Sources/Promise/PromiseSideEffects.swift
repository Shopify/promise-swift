//
//  PromiseSideEffects.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation


extension Promise {
  
  
  /// Injects side effect on start event.
  ///
  /// Side effect is a function that will be invoked _before_ async computation 
  /// represented by this `Promise` is about to start. Start event will occur
  /// when resulting `Promise` is first subscribed to using `whenComplete`
  ///
  /// - Parameter action: function to execute when started
  /// - Returns: new `Promise` instanece
  
  public func onStart(do action: @escaping () -> Void) -> Promise {
    return Promise { resolver in
      action()
      self.whenComplete(callback: resolver.complete)
      resolver.onCancel = { self.cancel() }
    }
  }
  
  
  /// Injects side effect on complete event
  ///
  /// Side effect is a function that will be invoked _before_ async computation
  /// represented by this `Promise` is about to complete (either success or error).
  ///
  /// - Parameter action: function to execute when completed.
  /// - Parameter result: result `Promise` has been completed with.
  /// - Returns: new `Promise` instanece
  
  public func onComplete(do action: @escaping (_ result: Result<T, E>) -> Void) -> Promise {
    return Promise { resolver in
      self.whenComplete { result in
        action(result)
        resolver.complete(result)
      }
      resolver.onCancel = { self.cancel() }
    }
  }
  
  
  /// Injects side effect on success event (resolution)
  ///
  /// Side effect is a function that will be invoked _before_ async computation
  /// represented by this `Promise` is about to complete with success.
  /// - Parameter action: function to execute when resolved.
  /// - Parameter value: value `Promise` has been resolved with
  /// - Returns: new `Promise` instanece
  
  public func onSuccess(do action: @escaping (_ value: T) -> Void) -> Promise {
    return self.onComplete { result in
      switch result {
      case .success(let value): action(value)
      case .failure: break
      }
    }
  }

  /// Injects side effect on error event (rejection)
  ///
  /// Side effect is a function that will be invoked _before_ async computation
  /// represented by this `Promise` is about to complete with error.
  /// - Parameter action: function to execute when resolved.
  /// - Parameter error: error `Promise` has been rejected with
  /// - Returns: new `Promise` instanece

  public func onError(do action: @escaping (_ error: E) -> Void) -> Promise {
    return self.onComplete { result in
      switch result {
      case .failure(let error): action(error)
      case .success: break
      }
    }
  }
}

