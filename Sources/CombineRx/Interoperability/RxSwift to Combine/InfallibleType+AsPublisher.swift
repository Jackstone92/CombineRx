//
//  InfallibleType+AsPublisher.swift
//  Copyright © 2022 Jack Stone. All rights reserved.
//

import Combine
import RxSwift

extension InfallibleType {
    /// A bridging function that transforms an RxSwift `InfallibleType` into a Combine `Publisher`.
    ///
    /// There is a fundamental difference between Combine and RxSwift around the concept of back pressure and how it is handled.
    /// Combine adheres to strict instructions specified by a `Subscriber` but RxSwift `Observable`s do not have the same restrictions.
    /// This function stores a buffer of values from the upstream `Infallible` until they are requested.
    ///
    /// In order to mitigate out-of-memory errors, it is recommended to provide a conservative value for `size` that matches
    /// the expected output of the upstream `Infallible` and consumption of the downstream `Subscriber`.
    ///
    /// - Parameter size: The size of the buffer.
    /// - Parameter whenFull: The buffering strategy to use. This determines how to handle the case when maximum buffer capacity is reached.
    ///
    /// - Returns: A Combine `Publisher` that is the bridged transformation of the given `InfallibleType`.
    ///
    public func asPublisher(
        withBufferSize size: Int,
        andBridgeBufferingStrategy whenFull: InfallibleBridgeBufferingStrategy
    ) -> Publishers.Buffer<InfallibleTypeBridgePublisher<Self>> {
        return InfallibleTypeBridgePublisher(upstream: self)
            .buffer(size: size, prefetch: .byRequest, whenFull: whenFull.strategy)
    }
}
