//
//  ObservableType+AsCombineBridge.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import Combine
import RxSwift

extension ObservableType {

    /// A bridging function that transforms an RxSwift `ObservableType` into a Combine `Publisher`.
    ///
    /// There is a fundamental difference between Combine and RxSwift around the concept of backpressure and how it is handled.
    /// Combine adheres to strict instructions specifed by a `Subscriber` but RxSwiift `Observable`s do not have the same restrictions.
    /// This function stores a buffer of values from the upstream `Observable` until they are requested.
    ///
    /// In order to mitigate out-of-memory errors, it is recommended to provide a conservative value for `size` that matches
    /// the expected output of the upstream `Observable` and consumption of the downstream `Subscriber`.
    ///
    /// - Parameter size: The size of the buffer.
    /// - Parameter whenFull: The buffering strategy to use. This determines how to handle the case when maximum buffer capacity is reached.
    ///
    /// - Returns: A Combine `Publisher` that is the bridged transformation of the given `ObservableType`.
    public func asCombineBridge(withBufferSize size: Int,
                                andBridgeBufferingStrategy whenFull: BridgeBufferingStrategy) -> Publishers.Buffer<BridgePublisher<Self>> {
        return BridgePublisher(upstream: self)
            .buffer(size: size, prefetch: .byRequest, whenFull: whenFull.strategy)
    }
}

extension Publisher where Failure == BridgeFailure {

    /// Raises a fatal error when an upstream `BridgePublisher`'s buffer overflows.
    /// In the event this does not occur, the failure type is mapped to the `Error` type of the upstream `Observable`.
    ///
    /// This function can be used at any point following the `asCombineBridge` function if you want to ensure a buffer overflow never occurs.
    ///
    /// - Returns: A publisher that maps any upstream error or fatal errors in the event of a `bufferOverflow`.
    public func assertBridgeBufferDoesNotOverflow() -> Publishers.MapError<Self, Error> {
        return mapError { error -> Error in
            switch error {
            case .bufferOverflow:                   preconditionFailure("Bridge buffer overflowed.")
            case .upstreamError(let upstreamError): return upstreamError
            }
        }
    }
}
