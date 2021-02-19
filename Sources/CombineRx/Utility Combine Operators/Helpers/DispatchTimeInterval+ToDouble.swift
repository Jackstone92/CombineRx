//
//  DispatchTimeInterval+ToDouble.swift
//  Copyright © 2021 Notonthehighstreet Enterprises Limited. All rights reserved.
//

import Foundation

extension DispatchTimeInterval {

    /// Converts a given `DispatchTimeInterval` to its `Double` representation.
    /// In the case of `never`, `nil` is returned.
    func toDouble() -> Double? {
        switch self {
        case .seconds(let value):       return Double(value)
        case .milliseconds(let value):  return Double(value) * 0.001
        case .microseconds(let value):  return Double(value) * 0.000001
        case .nanoseconds(let value):   return Double(value) * 0.000000001
        case .never:                    return nil
        @unknown default:               fatalError()
        }
    }
}
