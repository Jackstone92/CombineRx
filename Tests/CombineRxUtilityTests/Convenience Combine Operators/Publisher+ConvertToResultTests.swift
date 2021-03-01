//
//  Publisher+ConvertToResultTests.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import XCTest
import Combine
@testable import TestCommon
@testable import CombineRxUtility

final class Publisher_ConvertToResultTests: XCTestCase {

    private var subscriptions: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
    }

    func testSuccessResultCase() {

        let expectation = XCTestExpectation(description: "Should receive value when sinking")

        let subject = PassthroughSubject<Int, TestError>()
        let value = 99

        var output = [Result<Int, TestError>]()

        subject
            .convertToResult()
            .sink(receiveValue: { output.append($0); expectation.fulfill() })
            .store(in: &subscriptions)

        subject.send(value)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertFalse(output.isEmpty)
        XCTAssertEqual(output.count, 1)

        switch output[0] {
        case .failure(let error): XCTFail(error.localizedDescription)
        case .success(let receivedValue): XCTAssertEqual(receivedValue, value)
        }
    }

    func testFailureResultCase() {

        let expectation = XCTestExpectation(description: "Should receive value when sinking")

        let subject = PassthroughSubject<Int, TestError>()
        let testError: TestError = .generic

        var output = [Result<Int, TestError>]()

        subject
            .convertToResult()
            .sink(receiveValue: { output.append($0); expectation.fulfill() })
            .store(in: &subscriptions)

        subject.send(completion: .failure(testError))

        wait(for: [expectation], timeout: 0.1)

        XCTAssertFalse(output.isEmpty)
        XCTAssertEqual(output.count, 1)

        switch output[0] {
        case .failure(let error):
            guard case .generic = error else { XCTFail(); return }
        case .success:
            XCTFail()
        }
    }
}
