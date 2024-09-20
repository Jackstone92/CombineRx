# CombineRx

![Run Tests](https://github.com/Jackstone92/CombineRx/workflows/Run%20Tests/badge.svg)
[![License](https://img.shields.io/badge/license-mit-brightgreen.svg)](https://en.wikipedia.org/wiki/MIT_License)
[![codecov](https://codecov.io/gh/Jackstone92/CombineRx/branch/main/graph/badge.svg?token=8XH4E4NLBD)](https://codecov.io/gh/Jackstone92/CombineRx)

The *CombineRx* library contains a series of functions that help with the interoperability between [RxSwift](https://github.com/ReactiveX/RxSwift) and Apple's [Combine](https://developer.apple.com/documentation/combine) frameworks.

## Interoperability between Combine and RxSwift

### Combine to RxSwift
In order to convert Combine `Publisher`s to RxSwift  `Observable`s, you can make use of the `asObservable()` function. This can be done as follows:
```swift
import Combine
import RxSwift
import CombineRx

let myBridgedObservable = Just(0).asObservable()
```

It is also possible to convert Combine `Publisher`s to RxSwift `Infallible`s using `.asInfallible()`.
This can be done as follows:
```swift
import Combine
import RxSwift
import CombineRx

let myBridgedInfallible = Just(0)
    .setFailureType(to: Never.self)
    .asInfallible() // Works when `Failure` type is `Never`.

let myBridgedInfallible = Just(0)
    .setFailureType(to: Error.self)
    .asInfallible(onErrorRecover: { error in ... }) // Handle the error

let myBridgedInfallible = Just(0)
    .setFailureType(to: Error.self)
    .asInfallible(onErrorFallbackTo: Just<Int>(42).eraseToAnyPublisher()) // Use a fallback `Publisher`

let myBridgedInfallible = Just(0)
    .setFailureType(to: Error.self)
    .asInfallible(onErrorJustReturn: 42) // Use a fallback value
```

### RxSwift to Combine
In order to convert RxSwift `Observable`s to Combine `Publisher`s, you can make use of the
`asPublisher(withBufferSize:andBridgeBufferingStrategy:)` function. This can be done as follows:
```swift
import Combine
import RxSwift
import CombineRx

let myBridgedPublisher1 = Observable.just(0).asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
let myBridgedPublisher2 = Observable.from([0, 1, 2, 3]).asPublisher(withBufferSize: 4, andBridgeBufferingStrategy: .error)
```

It is also possible to convert RxSwift `Infallible`s to Combine `Publisher`s 
using `asPublisher(withBufferSize:andBridgeBufferingStrategy:)`.
This can be done as follows:
```swift
import Combine
import RxSwift
import CombineRx

let myBridgedPublisher1 = Infallible.just(0).asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropOldest)
let myBridgedPublisher2 = Infallible.from([0, 1, 2, 3]).asPublisher(withBufferSize: 4, andBridgeBufferingStrategy: .dropOldest)
```


One difference between RxSwift and Combine is that Combine adheres to the mechanism of backpressure in order to ensure that `Publisher`s only produce as many elements that `Subscriber`s have requested. This prevents the case where elements might build up in a `Publisher`s buffer faster than they can be processed downstream by a subscriber as this could lead to out-of-memory errors and degradation in performance due to high system resource consumption. Combine applies this backpressure upstream through a contractual obligation by `Publisher`s to only emit an element when it is requested by `Subscriber`s through `Subscribers.Demand` requests.

RxSwift `Observable`s differ in this regard as they rely on a source with an unbounded rate of production and therefore when bridging to a Combine `Publisher`, we must maintain a buffer or drop elements accordingly in order to satisfy the requirements of downstream subscribers.

This is the reason for the required `withBufferSize` and `andBridgeBufferingStrategy` parameters for `asPublisher(withBufferSize:andBridgeBufferingStrategy:)`. `withBufferSize` is where the buffer size should manually be set (ideally based directly on the number of expected elements in the sequence). `andBridgeBufferingStrategy` is the strategy to employ when the maximum buffer capacity is reached. Keeping in line with native Combine strategies, this can either be `error`, where any buffer overflow is treated as an error, `dropNewest` where the elements already present in the buffer are maintained and any new elements are ignored, or finally `dropOldest` where new elements are added to the buffer and replace older elements that were already present.

Additional information on Combine's use of backpressure can be found [here](https://developer.apple.com/documentation/combine/processing-published-elements-with-subscribers).

## Installation

It is currently possible to install this library using Swift Package Manager. In order to do so, please add the current repository as a package dependency using Xcode or include the following in your `Package.swift` file:
```swift
import PackageDescription

let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/Jackstone92/CombineRx", .upToNextMajor(from: "0.1.0")),
    ],
    ...
    targets: [
        .target(name: "MyTarget", dependencies: ["CombineRx"]),
    ]
)
```

## Copywrite and license information
Copyright 2020 © Jack Stone

*CombineRx* is made available under the [MIT License](https://github.com/Jackstone92/CombineRx/blob/main/LICENSE)
