//
//  Publisher+WithPreviousTests.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import XCTest
import Combine
import CombineSchedulers
@testable import CombineRx

final class Publisher_WithPreviousTests: XCTestCase {

    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
    }

    func testWithPreviousUpdatesPreviousValueAsExpected() {

        let value = 1
        let startValue = 0

        Just(value)
            .withPrevious(startsWith: startValue)
            .sink(receiveValue: { wasValue, isValue in
                XCTAssertEqual(wasValue, startValue)
                XCTAssertEqual(isValue, value)
            })
            .store(in: &subscriptions)
    }

    func testWithPreviousUpdatesPreviousValueSequence() {

        let subject = CurrentValueSubject<Int, Error>(0)

        var wasValues = [Int]()
        var isValues = [Int]()
        var hasFinished = false

        subject
            .withPrevious(startsWith: 0)
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

                hasFinished = true

            } receiveValue: { wasValue, isValue in
                wasValues.append(wasValue)
                isValues.append(isValue)
            }
            .store(in: &subscriptions)

        (1..<5).forEach { subject.send($0) }

        subject.send(completion: .finished)

        let expectedWasValues = [0] + (0..<4).map { $0 }
        let expectedIsValues = [0] + (1..<5).map { $0 }

        XCTAssertEqual(wasValues, expectedWasValues)
        XCTAssertEqual(isValues, expectedIsValues)
        XCTAssertTrue(hasFinished)
    }

    func testWithPreviousFailureInTransform() {

        let subject = PassthroughSubject<Int, Error>()
        var wasValues = [Int]()
        var isValues = [Int]()
        var testError: Error?

        subject
            .withPrevious(startsWith: 0)
            .sink { completion in
                guard case .failure(let error) = completion else {
                    XCTFail()
                    return
                }

                guard case TestError.generic = error else {
                    XCTFail()
                    return
                }

                testError = error

            } receiveValue: { wasValue, isValue in
                wasValues.append(wasValue)
                isValues.append(isValue)
            }
            .store(in: &subscriptions)

        subject.send(completion: .failure(TestError.generic))

        XCTAssertTrue(wasValues.isEmpty)
        XCTAssertTrue(isValues.isEmpty)
        XCTAssertNotNil(testError)
    }

    func testWithPreviousFailureDownstream() {

        Just(1)
            .setFailureType(to: TestError.self)
            .withPrevious(startsWith: 0)
            .flatMap { _ in Fail<Int, TestError>(error: TestError.generic) }
            .sink { completion in
                guard case .failure(let error) = completion else {
                    XCTFail()
                    return
                }

                guard case TestError.generic = error else {
                    XCTFail()
                    return
                }
            } receiveValue: { value in
                XCTFail()
            }
            .store(in: &subscriptions)
    }

    func testWithPreviousFailureUpstream() {

        Just(1)
            .setFailureType(to: TestError.self)
            .flatMap { _ in Fail<Int, TestError>(error: TestError.generic) }
            .withPrevious(startsWith: 0)
            .sink { completion in
                guard case .failure(let error) = completion else {
                    XCTFail()
                    return
                }

                guard case TestError.generic = error else {
                    XCTFail()
                    return
                }
            } receiveValue: { value in
                XCTFail()
            }
            .store(in: &subscriptions)
    }

    func testWithPreviousEmpty() {

        Empty<Int, TestError>()
            .withPrevious(startsWith: 0)
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

            } receiveValue: { value in
                XCTFail()
            }
            .store(in: &subscriptions)
    }
}
