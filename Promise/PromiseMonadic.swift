//
//  PromiseExtensions.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

extension Promise {
  
  private func commonThen<T1, E1: Error>(transform: @escaping (Result<T, E>) -> Promise<T1, E1>) -> Promise<T1, E1> {
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
  
  public func ifErrorThen<EV: Error>(transform: @escaping (E) -> Promise<T, EV>) -> Promise<T, EV> {
    return self.commonThen { result in
      switch result {
      case .success(let v):
        return Promise<T, EV>(value: v)
      case .error(let e):
        return transform(e)
      }
    }
  }
  
  public func map<V>(transform: @escaping (T) -> V) -> Promise<V, E> {
    return self.then { value in
      return Promise<V, E>(value: transform(value))
    }
  }
  
  public func mapError<EE: Error>(transform: @escaping (E) -> EE) -> Promise<T, EE> {
    return self.ifErrorThen { error in
      return Promise<T, EE>(error: transform(error))
    }
  }
}



