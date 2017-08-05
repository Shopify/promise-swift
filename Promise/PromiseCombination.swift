//
//  PromiseCombination.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

extension Promise {
  
  public static func all<S: Sequence>(_ promises: S, on queue: DispatchQueue = DispatchQueue.main) -> Promise<[T], E> where S.Iterator.Element == Promise<T, E> {
    return Promise<[T], E> { resolver in
      let group = DispatchGroup()
      let serialQueue = DispatchQueue(label: "serial")
      
      let cancelOthers = { (skip: Int) in
        for (index, promise) in promises.enumerated() {
          guard index != skip else { continue }
          promise.cancel()
        }
      }
      
      var results: [T?] = Array(promises.map { _ in nil })
      for (index, promise) in promises.enumerated() {
        group.enter()
        promise.whenComplete { result in
          switch result {
          case .success(let value):
            serialQueue.sync {
              results[index] = value
            }
            group.leave()
          case .error(let e):
            cancelOthers(index)
            resolver.reject(with: e)
          }
        }
      }
      
      group.notify(queue: queue) {
        resolver.resolve(with: results.flatMap { $0 } )
      }
      
      resolver.onCancel = {
        for promise in promises {
          promise.cancel()
        }
      }
    }
  }
  
  
  fileprivate struct Box {
    private var value: Any
    init(_ value: Any) {
      self.value = value
    }
    func typed<T>() -> T {
      return value as! T
    }
  }
  
  public static func all<T1, T2, E: Error>(_ p1: Promise<T1, E>, _ p2: Promise<T2, E>, on queue: DispatchQueue = DispatchQueue.main) -> Promise<(T1, T2), E> {
    
    let erased = [
      p1.map(transform: Box.init),
      p2.map(transform: Box.init)
    ]
    
    return Promise<Box, E>.all(erased, on: queue).map { ($0[0].typed(), $0[1].typed()) }
  }
  
  public static func all<T1, T2, T3, E: Error>(_ p1: Promise<T1, E>, _ p2: Promise<T2, E>, _ p3: Promise<T3, E>, on queue: DispatchQueue = DispatchQueue.main) -> Promise<(T1, T2, T3), E> {
    
    let erased = [
      p1.map(transform: Box.init),
      p2.map(transform: Box.init),
      p3.map(transform: Box.init)
    ]
    
    return Promise<Box, E>.all(erased, on: queue).map { ($0[0].typed(), $0[1].typed(), $0[2].typed()) }
  }
  
  public static func all<T1, T2, T3, T4, E: Error>(_ p1: Promise<T1, E>, _ p2: Promise<T2, E>, _ p3: Promise<T3, E>,_ p4: Promise<T4, E>, on queue: DispatchQueue = DispatchQueue.main) -> Promise<(T1, T2, T3, T4), E> {
    
    let erased = [
      p1.map(transform: Box.init),
      p2.map(transform: Box.init),
      p3.map(transform: Box.init),
      p4.map(transform: Box.init)
    ]
    
    return Promise<Box, E>.all(erased, on: queue).map { ($0[0].typed(), $0[1].typed(), $0[2].typed(), $0[3].typed()) }
  }
  
}
