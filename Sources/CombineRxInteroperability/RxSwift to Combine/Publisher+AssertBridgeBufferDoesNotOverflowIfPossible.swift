//
//  Publisher+AssertBridgeBufferDoesNotOverflowIfPossible.swift
//  Copyright © 2021 Notonthehighstreet Enterprises Limited. All rights reserved.
//

import Foundation
import Combine

extension Publisher {

    /// Convenience method whose default implementation causes a `preconditionFailure` when an upstream `BridgePublisher`'s buffer overflows.
    /// In the event this does not occur, the failure type is mapped to the `Error` type of the upstream `Observable`.
    ///
    /// This function can be used at any point following the `asPublisher` function if you want to ensure a buffer overflow never occurs.
    ///
    /// - Returns: A publisher that maps any upstream error or fatal errors in the event of a `bufferOverflow`.
    ///
    public func assertBridgeBufferDoesNotOverflowIfPossible(onBufferOverflow: @escaping () -> Error = { preconditionFailure("Bridge buffer overflowed.") }) -> Publishers.MapError<Self, Error> {
        return mapError { error -> Error in
            guard let bridgeFailure = error as? BridgeFailure else { return error }

            switch bridgeFailure {
            case .bufferOverflow:                   return onBufferOverflow()
            case .upstreamError(let upstreamError): return upstreamError
            }
        }
    }
}
