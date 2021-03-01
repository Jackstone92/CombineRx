//
//  AnyPublisher+Just.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import Foundation
import Combine

extension AnyPublisher {

    /// A convenience method on `AnyPublisher` to create a `Just` without having to include the boilerplate code to set failure type and erase to `AnyPublisher`.
    ///
    /// - Parameter output: The desired output value for the `Just`.
    ///
    /// - Returns: The created `Just` that has already been erased to `AnyPublisher` and whose failure type has already been implicitly set.
    ///
    public static func just(_ output: Output) -> Self {
        Just(output)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }
}
