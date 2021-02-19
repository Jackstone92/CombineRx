//
//  Publisher+ExponentialRetry.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import Foundation
import Combine

extension Publisher {

    /// Repeats the source observable sequence until either the `maxCount` number of retries is reached or until it successfully terminated.
    ///
    /// The delay is incremented by the specified `multiplier` after each iteration (multiplier = 0.5 means 50% increment).
    ///
    /// - Parameter maxCount: The maximum number of retries to attempt before terminating.
    /// - Parameter multiplier: The delay incrementation factor that is appliied after each iteration.
    /// - Parameter scheduler: The scheduler that will be used for delaying the subscription after error.
    ///
    /// - Returns: Observable sequence that will be automatically repeat if error occurred
    ///
    public func exponentialRetry<S: Scheduler>(maxCount: Int,
                                               multiplier: Double,
                                               scheduler: S) -> AnyPublisher<Output, Failure> {
        return retry(1, maxCount: maxCount, initial: 1, multiplier: multiplier, scheduler: scheduler)
    }
    
    /// Recursive retry that calculates the exponential delay based on the `currentAttempt`, `maxCount`,
    /// `initial` and `multiplier` parameters.
    ///
    /// - Parameter currentAttempt: The current retry attempt.
    /// - Parameter maxCount: The maximum number of retries to attempt before terminating.
    /// - Parameter initial: The initial retry count.
    /// - Parameter multiplier: The delay incrementation factor that is appliied after each iteration.
    /// - Parameter scheduler: The scheduler that will be used for delaying the subscription after error.
    ///
    /// - Returns: Observable sequence that will be automatically repeat if error occurred
    ///
    func retry<S: Scheduler>(_ currentAttempt: Int,
                             maxCount: Int,
                             initial: Double,
                             multiplier: Double,
                             scheduler: S) -> AnyPublisher<Output, Failure> {
        guard currentAttempt > 0 else { fatalError() }

        let conditions = ExponentialDelayCalculator.calculate(currentAttempt,
                                                              maxCount: maxCount,
                                                              initial: initial,
                                                              multiplier: multiplier)

        return self.catch { error -> AnyPublisher<Output, Failure> in

            guard let delay = conditions.delay.toDouble() else {
                // return error if exceeds maximum amount of retries
                return retry(currentAttempt + 1,
                             maxCount: maxCount,
                             initial: initial,
                             multiplier: multiplier,
                             scheduler: scheduler)
            }

            // otherwise retry after specified delay
            return Just<Void>(())
                .setFailureType(to: Failure.self)
                .delaySubscription(for: .seconds(delay), scheduler: scheduler)
                .flatMapLatest {
                    self.retry(currentAttempt + 1,
                               maxCount: maxCount,
                               initial: initial,
                               multiplier: multiplier,
                               scheduler: scheduler)
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
