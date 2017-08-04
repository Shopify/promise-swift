//
//  PromiseNoError.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

extension Promise where E == NoError {
  
  @discardableResult
  public func whenSuccess(_ callback: @escaping (T) -> Void) -> Self {
    return self.whenComplete { result in
      switch result {
      case .success(let v): callback(v)
      case .error: fatalError()
      }
    }
  }
  
  public func promoteErrors<En: Error>() -> Promise<T, En> {
    return self.mapError {_ in
      //will never get there
      fatalError()
    }
  }
  
}

extension Promise {
  public func ignoreErrors() -> Promise<T, NoError> {
    return self.ifErrorThen { _ in
      return Promise<T, NoError>.never()
    }
  }
  
  public static func never() -> Promise {
    return Promise {_ in }
  }
}
