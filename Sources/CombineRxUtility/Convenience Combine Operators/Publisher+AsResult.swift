//
//  Publisher+AsResult.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import Foundation
import Combine

extension Publisher {

    /// Converts a publisher's output and failure type to a result that can be switched on.
    /// The resulting publisher's error type becomes `Never` as any error will be caught and propagated to the `Result`.
    ///
    /// - Returns: A publisher whose original output and failure type become a result that can be sinked on, and whose failure type becomes `Never`.
    public func asResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        return map(Result.success)
            .catch { Just(.failure($0)) }
            .eraseToAnyPublisher()
    }
}
