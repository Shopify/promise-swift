//
//  PromiseCore.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-05-30.
//  Copyright © 2017 Jaded Labs Inc. All rights reserved.
//

import Foundation



public enum NoError: Error {}

public typealias PromiseCallback<T, E: Error> = (Result<T, E>) -> Void
public typealias PromiseStartFunction<T, E: Error> = (PromiseResolver<T, E>) -> Void
public typealias PromiseCancelFunction = () -> Void

fileprivate enum PromiseState<T, E: Error> {
  case pending(PromiseStartFunction<T, E>, [PromiseCallback<T, E>])
  case executing(PromiseCancelFunction, [PromiseCallback<T, E>])
  case complete(Result<T, E>)
  case cancelled
  
  mutating func addCallback(_ callback: @escaping PromiseCallback<T, E>) {
    switch self {
    case .pending(let start, var callbacks):
      callbacks.append(callback)
      self = .pending(start, callbacks)
    case .executing(let cancel, var callbacks):
      callbacks.append(callback)
      self = .executing(cancel, callbacks)
    default:()
    }
  }
}

public class PromiseResolver<T, E: Error> {
  public var onCancel: PromiseCancelFunction?
  private(set) public var complete: PromiseCallback<T, E>
  
  fileprivate init(complete: @escaping PromiseCallback<T, E>) {
    self.complete = complete
  }
  
  public func resolve(with value: T) {
    complete(.success(value))
  }
  
  public func reject(with error: E) {
    complete(.error(error))
  }
  
}

final public class Promise<T, E: Error> {
  
  private let state: Atomic<PromiseState<T, E>>
  
  private init(state: PromiseState<T, E>) {
    self.state = Atomic<PromiseState<T, E>>(state) { oldValue, newValue in
      switch (oldValue, newValue) {
      case (.executing(_, let callbacks), .complete(let result)):
        for callback in callbacks {
          callback(result)
        }
      default:()
      }
    }
  }
  
  public convenience init(value: T) {
    self.init(state: .complete(.success(value)))
  }
  
  public convenience init(error: E) {
    self.init(state: .complete(.error(error)))
  }
  
  public convenience init(_ start: @escaping PromiseStartFunction<T, E>) {
    self.init(state: .pending(start, []))
  }
  
  @discardableResult
  public func whenComplete(callback: @escaping PromiseCallback<T, E>) -> Self {
    state.modify {
      switch $0 {
      case .pending, .executing:
        $0.addCallback(callback)
      case .complete(let result):
        callback(result)
      default:()
      }
      
      if case .pending = $0 {
        start()
      }
    }
    return self
  }
  
  func start() {
    self.state.modify { state in
      guard case .pending(let start, let callbacks) = state else { return }
      
      func complete(result: Result<T, E>) {
        self.state.modify { $0 = .complete(result) }
      }

      let resolver = PromiseResolver(complete: complete)
      let cancel: PromiseCancelFunction  = {
        resolver.onCancel?()
      }
      state = .executing(cancel, callbacks)
      
      start(resolver)
    }
  }
  
  private func notifyObservers(_ callbacks: [PromiseCallback<T, E>],  with result: Result<T, E>) {
    for callback in callbacks {
      callback(result)
    }
  }
  
  public func cancel() {
    state.modify {
        switch $0 {
        case .cancelled: break
        case .executing(let cancelFunc, _):
            $0 = .cancelled
            cancelFunc()
        case .pending, .complete:
            $0 = .cancelled
        }
    }
  }
}

