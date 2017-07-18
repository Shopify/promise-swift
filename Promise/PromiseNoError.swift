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
    func whenSuccess(_ callback: @escaping (T) -> Void) -> Self {
        return self.whenComplete { result in
            switch result {
            case .success(let v): callback(v)
            case .error: fatalError()
            }
        }
    }
    
    func promoteErrors<En: Error>() -> Promise<T, En> {
        return self.mapError {_ in
            //will never get there
            fatalError()
        }
    }
    
}

extension Promise {
    func ignoreErrors() -> Promise<T, NoError> {
        return self.ifErrorThen { _ in
            return Promise<T, NoError>.never()
        }
    }
    
    static func never() -> Promise {
        return Promise {_, _ in }
    }
}
