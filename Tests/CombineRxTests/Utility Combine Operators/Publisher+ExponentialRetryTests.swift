//
//  Publisher+ExponentialRetryTests.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import XCTest
import Combine
import CombineSchedulers
@testable import CombineRx

final class Publisher_ExponentialRetryTests: XCTestCase {

    private var subscriptions = Set<AnyCancellable>()
    private var scheduler: TestScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>!

    private enum TestError: Error {
        case generic
    }

    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
        scheduler = DispatchQueue.testScheduler
    }

    func testExponentialRetryRetriesExponentiallyUntilMaxCountIsReachedBeforeReturningError() throws {

        let subject = PassthroughSubject<Int, TestError>()
        var output = [Int]()

        let maxCount = 5
        let multiplier = 0.5

        subject
            .receive(on: scheduler)
            .exponentialRetry(maxCount: maxCount, multiplier: multiplier, scheduler: scheduler)
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

            } receiveValue: { value in
                output.append(value)
            }
            .store(in: &subscriptions)

        subject.send(completion: .failure(.generic))

        XCTAssertTrue(output.isEmpty)

        let millisecondsPassedPartWay = try XCTUnwrap(ExponentialDelayCalculator.calculate(maxCount - 2,
                                                                                           maxCount: maxCount,
                                                                                           initial: 1,
                                                                                           multiplier: multiplier).delay.toDouble())

        scheduler.advance(by: .milliseconds(Int(millisecondsPassedPartWay)))
        XCTAssertTrue(output.isEmpty)

        let millisecondsPassedUntilFinishRetrying = try XCTUnwrap(ExponentialDelayCalculator.calculate(maxCount,
                                                                                                       maxCount: maxCount,
                                                                                                       initial: 1,
                                                                                                       multiplier: multiplier).delay.toDouble())

        scheduler.advance(by: .milliseconds(Int(millisecondsPassedUntilFinishRetrying - millisecondsPassedPartWay)))

        XCTAssertTrue(output.isEmpty)
    }

    func testExponentialRetryFailureDownstream() throws {

        let maxCount = 5
        let multiplier = 0.5

        Just(1)
            .setFailureType(to: TestError.self)
            .exponentialRetry(maxCount: maxCount, multiplier: multiplier, scheduler: scheduler)
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

        let millisecondsPassedUntilFinishRetrying = try XCTUnwrap(ExponentialDelayCalculator.calculate(maxCount,
                                                                                                       maxCount: maxCount,
                                                                                                       initial: 1,
                                                                                                       multiplier: multiplier).delay.toDouble())

        scheduler.advance(by: .milliseconds(Int(millisecondsPassedUntilFinishRetrying)))
    }

    func testExponentialRetryEmpty() throws {

        let maxCount = 5
        let multiplier = 0.5

        Empty<Int, TestError>()
            .exponentialRetry(maxCount: maxCount, multiplier: multiplier, scheduler: scheduler)
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

            } receiveValue: { value in
                XCTFail()
            }
            .store(in: &subscriptions)

        let millisecondsPassedUntilFinishRetrying = try XCTUnwrap(ExponentialDelayCalculator.calculate(maxCount,
                                                                                                       maxCount: maxCount,
                                                                                                       initial: 1,
                                                                                                       multiplier: multiplier).delay.toDouble())

        scheduler.advance(by: .milliseconds(Int(millisecondsPassedUntilFinishRetrying)))
    }
}
