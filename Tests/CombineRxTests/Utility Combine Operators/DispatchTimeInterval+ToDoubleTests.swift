//
//  DispatchTimeInterval+ToDoubleTests.swift
//  Copyright © 2021 Notonthehighstreet Enterprises Limited. All rights reserved.
//

import XCTest
@testable import CombineRx

final class DispatchTimeInterval_ToDoubleTests: XCTestCase {

    func testSeconds() {
        let seconds = 5_129
        let dispatchTimeInterval: DispatchTimeInterval = .seconds(seconds)

        XCTAssertNotNil(dispatchTimeInterval.toDouble())
        XCTAssertEqual(dispatchTimeInterval.toDouble(), Double(seconds))
    }

    func testMilliseconds() {
        let milliseconds = 5_129_999
        let dispatchTimeInterval: DispatchTimeInterval = .milliseconds(milliseconds)

        XCTAssertNotNil(dispatchTimeInterval.toDouble())
        XCTAssertEqual(dispatchTimeInterval.toDouble(), Double(milliseconds) * 0.001)
    }

    func testMicroseconds() {
        let microsecoonds = 5_129_999_194
        let dispatchTimeInterval: DispatchTimeInterval = .microseconds(microsecoonds)

        XCTAssertNotNil(dispatchTimeInterval.toDouble())
        XCTAssertEqual(dispatchTimeInterval.toDouble(), Double(microsecoonds) * 0.000001)
    }

    func testNanoseconds() {
        let nanoseconds = 5_129_999_194_9159
        let dispatchTimeInterval: DispatchTimeInterval = .nanoseconds(nanoseconds)

        XCTAssertNotNil(dispatchTimeInterval.toDouble())
        XCTAssertEqual(dispatchTimeInterval.toDouble(), Double(nanoseconds) * 0.000000001)
    }

    func testNever() {
        XCTAssertNil(DispatchTimeInterval.never.toDouble())
    }
}
