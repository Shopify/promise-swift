# Promise
This is a swift framework implementing [promise](link to wiki here) pattern.

## What is Promise?
Promise represents a value that may be available in future. Technically, it's a wrapper for an async function with result returned via callback. Besides being an async computation wrapper, Promise can also be implemented as a [continuation monad](link to continuation monad here) opening up a new way of solving many problems related to async computations.

## Features
`Promise-swift` is heavily influenced by Node.js `Promise` implementation in terms of API and by [ReactiveSwift](link here)'s `Signal` implementation in internal design. Notably:
1. `Promise-swift` is cold: async computation the promise represents will only be executed when promise is first observed using `whenComplete` method.
2. `Promise-swift` is buffered: once value computed subsequent calls to `whenComplete` will not trigger async computation again.
3. `Promise-swift` is parameterized with both value _and_ error.
4. `Promise-swift` is thread-safe: async computations and observing can be triggered from different threads.
:


# Credits
`Promise-swift` created by Sergey Gavrilyuk [@octogavrix](http://twitter.com/octogavrix).


## License
`Promise-swift` is distributed under MIT license. See LICENSE for more info.

## Contributing
Fork, branch & pull request.
    
