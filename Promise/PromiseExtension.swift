//
//  PromiseExtension.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

extension Promise {
  
  public func completeOn(queue: DispatchQueue) -> Promise {
    return Promise { resolver in
      self.whenComplete { result in
        queue.async { resolver.complete(result) }
      }
    }
  }
  
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


