//
//  AnyPublisher+FailTests.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import XCTest
import Combine
@testable import CombineRx

final class AnyPublisher_FailTests: XCTestCase {

    func testFailure() {

        let existingExpectation = XCTestExpectation(description: "Existing implementation should complete with `.failure`")
        let expectation = XCTestExpectation(description: "New implementation should complete with `.failure`")

        let testError = TestError.generic

        var existingErrorReceived: TestError?
        var newErrorReceived: TestError?

        _ = Just(0)
            .setFailureType(to: TestError.self)
            .flatMap { _ -> AnyPublisher<Int, TestError> in Fail(error: testError).eraseToAnyPublisher() } // Existing implementation
            .sink { completion in
                guard case .failure(let error) = completion else { XCTFail(); return }

                guard error == testError else { XCTFail(); return }

                existingErrorReceived = error
                existingExpectation.fulfill()

            } receiveValue: { _ in XCTFail() }

        _ = Just(0)
            .setFailureType(to: TestError.self)
            .flatMap { _ -> AnyPublisher<Int, TestError> in .fail(with: testError) } // With convenience
            .sink { completion in
                guard case .failure(let error) = completion else { XCTFail(); return }

                guard error == testError else { XCTFail(); return }

                newErrorReceived = error
                expectation.fulfill()

            } receiveValue: { _ in XCTFail() }

        wait(for: [existingExpectation, expectation], timeout: 0.1)

        XCTAssertNotNil(existingErrorReceived)
        XCTAssertNotNil(newErrorReceived)
        XCTAssertEqual(existingErrorReceived, newErrorReceived)
    }
}
