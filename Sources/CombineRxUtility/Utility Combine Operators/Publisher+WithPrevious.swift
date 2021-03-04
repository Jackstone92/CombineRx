//
//  Publisher+WithPrevious.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import Foundation
import Combine

extension Publisher {

    /// Provides access to previous and current values in an observable sequence.
    ///
    /// - Parameter startsWith: The initial seed value.
    ///
    /// - Returns: The observable sequence containing the previous and current values as a tuple.
    public func withPrevious(startsWith first: Output) -> AnyPublisher<(Output, Output), Failure> {
        scan((first, first)) { ($0.1, $1) }.eraseToAnyPublisher()
    }
}
