//
//  Publisher+DelaySubscriptionTests.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import XCTest
import Combine
import CombineSchedulers
@testable import CombineRx

final class Publisher_DelaySubscriptionTests: XCTestCase {

    private var subscriptions = Set<AnyCancellable>()
    private var scheduler: TestScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>!

    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
        scheduler = DispatchQueue.testScheduler
    }

    func testDelaySubscription() {

        var output = [Int]()
        var totalTimePassed = 0

        Just<Int>(1)
            .delaySubscription(for: .seconds(100_000_000), scheduler: scheduler)
            .sink { value in
                output.append(value)
            }
            .store(in: &subscriptions)

        XCTAssertTrue(output.isEmpty)

        scheduler.advance(by: .seconds(50_000_000))
        totalTimePassed += 50_000_000
        XCTAssertTrue(output.isEmpty)

        scheduler.advance(by: .seconds(49_999_999))
        totalTimePassed += 49_999_999
        XCTAssertTrue(output.isEmpty)

        scheduler.advance(by: 1)
        totalTimePassed += 1

        XCTAssertEqual(totalTimePassed, 100_000_000)
        XCTAssertFalse(output.isEmpty)
        XCTAssertEqual(output, [1])
    }

    func testTimespanError() {

        let subject = PassthroughSubject<Int, TestError>()

        var output = [Int]()
        var testError: Error?

        subject
            .receive(on: scheduler)
            .delaySubscription(for: .seconds(10_000), scheduler: scheduler)
            .sink { completion in
                guard case .failure(let error) = completion else {
                    XCTFail()
                    return
                }

                testError = error

            } receiveValue: { value in
                output.append(value)
            }
            .store(in: &subscriptions)

        subject.send(42)
        subject.send(43)
        subject.send(completion: .failure(.generic))

        scheduler.advance(by: .seconds(10_000))
        XCTAssertTrue(output.isEmpty) // As the error was emitted while subscription was being delayed, no elements were emitted.
        XCTAssertNotNil(testError)
    }

    func testTimespanCompleted() {

        let subject = PassthroughSubject<Int, TestError>()

        var output = [Int]()
        var hasFinished = false

        subject
            .receive(on: scheduler)
            .delaySubscription(for: .seconds(10_000), scheduler: scheduler)
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

                hasFinished = true

            } receiveValue: { value in
                output.append(value)
            }
            .store(in: &subscriptions)

        subject.send(42)
        subject.send(43)
        subject.send(completion: .finished)

        scheduler.advance(by: .seconds(10_000))
        XCTAssertTrue(output.isEmpty) // As the sequence was completed while subscription was being delayed, no elements were emitted.
        XCTAssertTrue(hasFinished)
    }
}
