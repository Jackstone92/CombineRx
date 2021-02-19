//
//  ExponentialDelayCalculatorTests.swift
//  Copyright © 2021 Notonthehighstreet Enterprises Limited. All rights reserved.
//

import XCTest
@testable import CombineRx

final class ExponentialDelayCalculatorTests: XCTestCase {


    func testCalculateExponentialDelay() {

        let maxCount = 5
        let initial: Double = 1
        let multiplier = 0.5

        var output = [DispatchTimeInterval]()

        for i in 1...5 {
            let exponentialDelay = ExponentialDelayCalculator.calculate(i,
                                                                        maxCount: maxCount,
                                                                        initial: initial,
                                                                        multiplier: multiplier).delay
            output.append(exponentialDelay)
        }

        let expected: [DispatchTimeInterval] = [.milliseconds(1000),
                                                .milliseconds(1500),
                                                .milliseconds(2250),
                                                .milliseconds(3375),
                                                .milliseconds(5062)]

        XCTAssertEqual(output, expected)
    }
}
