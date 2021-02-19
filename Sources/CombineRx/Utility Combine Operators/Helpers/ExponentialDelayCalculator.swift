//
//  ExponentialDelayCalculator.swift
//  Copyright © 2021 Notonthehighstreet Enterprises Limited. All rights reserved.
//

import Foundation

/// A helper method to calculate exponential delay.
struct ExponentialDelayCalculator {

    /// Calculates the exponential delay.
    ///
    /// - Parameter currentAttempt: The current retry attempt.
    /// - Parameter maxCount: The maximum number of retries to attempt before terminating.
    /// - Parameter initial: The initial retry count.
    /// - Parameter multiplier: The delay incrementation factor that is appliied after each iteration.
    ///
    /// - Returns: Tuple with `maxCount` and calculated delay in milliseconds for the current attempt.
    ///
    static func calculate(_ currentAttempt: Int,
                          maxCount: Int,
                          initial: Double,
                          multiplier: Double) -> (maxCount: Int, delay: DispatchTimeInterval) {
        let delay = currentAttempt == 1
            ? initial
            : initial * pow(1 + multiplier, Double(currentAttempt - 1))

        return (maxCount: maxCount, delay: .milliseconds(Int(delay * 1000)))
    }
}
