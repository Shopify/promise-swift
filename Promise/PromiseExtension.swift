//
//  PromiseExtension.swift
//  Promise
//
//  Created by Sergey Gavrilyuk on 2017-07-12.
//  Copyright © 2017 Shopify. All rights reserved.
//

import Foundation

extension Promise {
    
    func completeOn(queue: DispatchQueue) -> Promise {
        return Promise { complete, _ in
            self.whenComplete { result in
                queue.async { complete(result) }
            }
        }
    }
    
    func delayed(for delay: DispatchTimeInterval, on queue: DispatchQueue = DispatchQueue.main) -> Promise {
        return Promise { complete, _ in
            self.whenComplete { result in
                queue.asyncAfter(deadline: .now() + delay) {
                    complete(result)
                }
            }
        }
    }
        
}


