//
//  ObservableType+AsPublisher.swift
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
    /// In order to align with RxSwift error types, the `Failure` type of the returned publisher is `Error` whereby the concrete upstream error type is preserved.
    /// If it is desired to transform the publisher error type further downstream, it will be required to do this manually using the `mapError` accordingly.
    ///
    /// - Parameter size: The size of the buffer.
    /// - Parameter whenFull: The buffering strategy to use. This determines how to handle the case when maximum buffer capacity is reached.
    ///
    /// - Returns: A Combine `Publisher` that is the bridged transformation of the given `ObservableType`.
    public func asPublisher(withBufferSize size: Int,
                            andBridgeBufferingStrategy whenFull: BridgeBufferingStrategy) -> Publishers.MapError<Publishers.Buffer<BridgePublisher<Self>>, Error> {
        return BridgePublisher(upstream: self)
            .buffer(size: size, prefetch: .byRequest, whenFull: whenFull.strategy)
            .mapError { error -> Error in
                switch error {
                case BridgeFailure.upstreamError(let upstreamError):    return upstreamError
                default:                                                return error
                }
            }
    }
}
