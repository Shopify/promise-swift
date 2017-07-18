//
//  Result.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

public enum Result<T, E: Error> {
    case success(T)
    case error(E)
}


extension Result {
    public func map<V>(_ transform: (T) -> V) -> Result<V, E> {
        switch self {
        case .success(let v): return .success(transform(v))
        case .error(let e): return .error(e)
        }
    }
}
