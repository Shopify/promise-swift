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


/// Manual promise resolver.
/// 
/// You don't create an instance of resolver mannually. `Promise` provides 
/// instance of resolver in async operation wrapper closure so caller can manually resolve or reject 
/// `Promise` when async operation is finished.
/// Also, `PromiseResolver` bears cancellation action, so you async operation can inject custom 
/// cancellation action into resolver using `onCancel` property

public class PromiseResolver<T, E: Error> {
  
  
  /// Cancellation action. Async operation can provide custom action to be performed
  /// when `Promise` is cancelled using this property.
  public var onCancel: PromiseCancelFunction?
  
  
  /// Promise `complete` handler.
  ///
  /// Combines both resolution AND rejection values in common `Result` type.
  /// `resolve(with:)` and `reject(with:)` use this property to forward result to observers.
  
  private(set) public var complete: PromiseCallback<T, E>
  
  fileprivate init(complete: @escaping PromiseCallback<T, E>) {
    self.complete = complete
  }
  
  
  /// Resolves `Promise`.
  ///
  /// Calling `resolve` will synchronously forward result into `Promise` observers, including 
  /// chained `Promise`s, unless current `Promise` has already been cancelled, in which case this call
  /// does nothing.
  ///
  /// - Parameter value: success value for promise to be resolved with.
  
  public func resolve(with value: T) {
    complete(.success(value))
  }
  
  
  /// Rejects `Promise`
  ///
  /// Calling `reject` will synchronously forward result into `Promise` observers,
  /// unless current `Promise` has already been cancelled, in which case this this call.
  /// Chained `Promise`s will not be created as errors are not propagated into `Promise` chain.
  ///
  /// - Parameter error: error value for promise to be rejected with
  
  public func reject(with error: E) {
    complete(.error(error))
  }
  
}


/// Promise 
///
/// Represnts value that may be available in future.

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
  
  
  /// Creates resolved `Promise` with success result of given value
  ///
  /// - Parameter value: value that is immediately available.
  
  public convenience init(value: T) {
    self.init(state: .complete(.success(value)))
  }
  
  
  /// Creates rejected `Promise` with error result of given value
  ///
  /// - Parameter error: error that is emmediately available.
  public convenience init(error: E) {
    self.init(state: .complete(.error(error)))
  }
  
  
  /// Creates `Promise` wrapping asynchronous action
  ///
  /// Returned `Promise` instance is in pending state. Upon first call to `whenComplete`
  /// `Promise` will execute start function, which supposed to start wrapping asynchronous operation
  /// Asynchronous operation can report when it's finished — either successfully or not — using `resolver`
  /// given as parameter to start function.
  /// `resolver` also retains cancellation action, which start function wrapping asynchronous operation
  /// can define using `onCancel` property of `resolver`
  /// ```
  /// let p = Promise<Int, NoError> { resolver in
  ///   let operation = startAsyncOperation() { result in
  ///     resolver.resolve(result)
  ///   }
  ///   resolver.onCancel = { operation.cancel() }
  /// }
  /// ```
  ///
  /// - Parameter start: start function wrapping asynchronous action
  
  public convenience init(_ start: @escaping PromiseStartFunction<T, E>) {
    self.init(state: .pending(start, []))
  }
  
  
  /// Adds observer to the `Promise`
  /// 
  /// Adds callback to observe result of the `Promise` (either resolution or rejection).
  /// Callback given may be called synchronously upon calling `whenComplete` (if the result is already available).
  /// May be called on any thread, depending on which thread asynchronous operation notified about availbale result.
  ///
  /// - Parameter callback: function to be called when result is available.
  /// - Returns: self instance of `Promise` that can be ignored. Used for call chaning purposes.
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
  
  
  /// Cancels executing `Promise`
  /// 
  /// If the `Promise` is alreadt canceled — does nothing.
  /// If the `Promise` is currently executing — calls cancellation action (providing via `onCancel` property of resolver)
  /// and ignores any subsequent attempts to resolve or reject `resolver` from asynchronous operation.
  /// `whenComplete` is guaranteed to never be called after `cancel` was called.
  /// Any `Promise`s chained with this one via `then` will never be created.
  
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

