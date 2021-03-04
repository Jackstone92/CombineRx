//
//  AnyPublisher+JustTests.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import XCTest
import Combine
@testable import TestCommon
@testable import CombineRxUtility

final class AnyPublisher_JustTests: XCTestCase {

    func testOutput() {

        let existingExpectation = XCTestExpectation(description: "Existing implementation should complete with `.finished`")
        let expectation = XCTestExpectation(description: "New implementation should complete with `.finished`")

        let testString = "Test"

        var existingStringReceived: String?
        var newStringReceived: String?

        _ = Just(0)
            .setFailureType(to: TestError.self)
            .flatMap { _ -> AnyPublisher<String, TestError> in
                Just(testString).setFailureType(to: TestError.self).eraseToAnyPublisher() // Existing implementation
            }
            .sink { completion in
                guard case .finished = completion else { XCTFail(); return }
                existingExpectation.fulfill()
            } receiveValue: { existingStringReceived = $0 }

        _ = Just(0)
            .setFailureType(to: TestError.self)
            .flatMap { _ -> AnyPublisher<String, TestError> in .just(testString) } // With convenience
            .sink { completion in
                guard case .finished = completion else { XCTFail(); return }
                expectation.fulfill()
            } receiveValue: { newStringReceived = $0 }

        wait(for: [existingExpectation, expectation], timeout: 0.1)

        XCTAssertNotNil(existingStringReceived)
        XCTAssertNotNil(newStringReceived)
        XCTAssertEqual(existingStringReceived, newStringReceived)
    }
}
