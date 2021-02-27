//
//  AnyPublisher+Fail.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import Foundation
import Combine

extension AnyPublisher {

    /// A convenience function on `AnyPublisher` to create a `Fail` without having to include the boilerplate code to set failure type and erase to `AnyPublisher`.
    ///
    /// - Parameter error: The desired error for the `Fail`.
    ///
    /// - Returns: The created `Fail` that has already been erased to `AnyPublisher`.
    ///
    public static func fail(with error: Failure) -> Self {
        Fail(error: error).eraseToAnyPublisher()
    }
}
