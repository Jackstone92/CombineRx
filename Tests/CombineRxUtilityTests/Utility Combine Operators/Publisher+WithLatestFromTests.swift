//
//  Publisher+WithLatestFromTests.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import XCTest
import Combine
@testable import TestCommon
@testable import CombineRxUtility

final class Publisher_WithLatestFromTests: XCTestCase {

    private var subscriptions: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
    }

    func testWithLatestFromEmitsSecondValueIfSpecifiedWithoutResultSelector() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        subject1
            .withLatestFrom(subject2)
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

                expectation.fulfill()
            } receiveValue: { value in
                XCTAssertEqual(value, 1)
            }
            .store(in: &subscriptions)

        subject1.send(0)
        subject2.send(1)
        subject1.send(0)
        subject1.send(completion: .finished)

        wait(for: [expectation], timeout: 0.1)
    }

    func testWithLatestFromResultSelector() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        subject1
            .withLatestFrom(subject2, resultSelector: { ($0, $1) })
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

                expectation.fulfill()
            } receiveValue: { first, second in
                XCTAssertEqual(first, 0)
                XCTAssertEqual(second, 1)
            }
            .store(in: &subscriptions)

        subject2.send(1)
        subject1.send(0)
        subject1.send(completion: .finished)

        wait(for: [expectation], timeout: 0.1)
    }

    func testWithLatestFromResultSelectorCanReturnOnlyFirstValue() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        subject1
            .withLatestFrom(subject2, resultSelector: { first, second in return first })
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

                expectation.fulfill()
            } receiveValue: { first in
                XCTAssertEqual(first, 0)
            }
            .store(in: &subscriptions)

        subject2.send(1)
        subject1.send(0)
        subject1.send(completion: .finished)

        wait(for: [expectation], timeout: 0.1)
    }

    func testWithLatestFromResultSelectorCanReturnOnlySecondValue() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        subject1
            .withLatestFrom(subject2, resultSelector: { first, second in return second })
            .sink { completion in
                guard case .finished = completion else {
                    XCTFail()
                    return
                }

                expectation.fulfill()
            } receiveValue: { second in
                XCTAssertEqual(second, 1)
            }
            .store(in: &subscriptions)

        subject2.send(1)
        subject1.send(0)
        subject1.send(completion: .finished)

        wait(for: [expectation], timeout: 0.1)
    }

    func testWithLatestFromPassThroughSubject() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        var output = [(Int, Int)]()

        subject1
            .withLatestFrom(subject2, resultSelector: { ($0, $1) })
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { output.append($0) }
            )
            .store(in: &subscriptions)

        subject2.send(1)
        subject1.send(0)
        subject1.send(2)
        subject2.send(4)
        subject1.send(3)
        subject1.send(completion: .finished)

        wait(for: [expectation], timeout: 0.1)

        let expected = [0, 1, 2, 1, 3, 4]

        XCTAssertFalse(output.isEmpty)
        XCTAssertEqual(output.flatMap { [$0.0] + [$0.1] }, expected)
    }

    func testWithLatestFromCurrentValueSubject() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = CurrentValueSubject<Int, Never>(0)
        let subject2 = CurrentValueSubject<Int, Never>(1)

        var output = [(Int, Int)]()

        subject1
            .withLatestFrom(subject2, resultSelector: { ($0, $1) })
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { output.append($0) }
            )
            .store(in: &subscriptions)

        subject1.send(5)
        subject1.send(completion: .finished)

        wait(for: [expectation], timeout: 0.1)

        let expected = [0, 1, 5, 1]

        XCTAssertFalse(output.isEmpty)
        XCTAssertEqual(output.flatMap { [$0.0] + [$0.1] }, expected)
    }

    func testWithLatestFromWithJusts() {

        let expectation = XCTestExpectation(description: "Should complete")

        let just1 = Just(0).eraseToAnyPublisher()
        let just2 = Just(1).eraseToAnyPublisher()

        var output = [(Int, Int)]()

        just1
            .withLatestFrom(just2, resultSelector: { ($0, $1) })
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { output.append($0) }
            )
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 0.1)

        let expected = [0, 1]

        XCTAssertEqual(output.flatMap { [$0.0] + [$0.1] }, expected)
    }

    func testWithLatestFromWithSequences() {

        let expectation = XCTestExpectation(description: "Should complete")

        let sequence1 = [0, 1, 2, 3].publisher
        let sequence2 = [4, 5, 6, 7, 8, 9, 10].publisher

        var output = [(Int, Int)]()

        sequence1
            .withLatestFrom(sequence2, resultSelector: { ($0, $1) })
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { output.append($0) }
            )
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 0.1)

        let expected = [0, 10, 1, 10, 2, 10, 3, 10]

        XCTAssertEqual(output.flatMap { [$0.0] + [$0.1] }, expected)
    }

    func testErrorsFromFirstPublisherIsPropogatedDownstream() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, TestError>()
        let subject2 = PassthroughSubject<Int, TestError>()

        var testError: Error?

        subject1
            .withLatestFrom(subject2, resultSelector: { ($0, $1) })
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else {
                        XCTFail()
                        return
                    }

                    testError = error

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        subject1.send(completion: .failure(.generic))

        wait(for: [expectation], timeout: 0.1)

        XCTAssertNotNil(testError)
    }

    func testErrorsFromSecondPublisherAreNotPropogatedDownstream() {

        let expectation = XCTestExpectation(description: "Should complete")
        expectation.isInverted = true

        let subject1 = PassthroughSubject<Int, TestError>()
        let subject2 = PassthroughSubject<Int, TestError>()

        var testError: Error?

        subject1
            .withLatestFrom(subject2)
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else {
                        XCTFail()
                        return
                    }

                    testError = error

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        subject2.send(completion: .failure(.generic))
        subject1.send(0)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertNil(testError)
    }

    func testUpstreamErrorsArePropogatedDownstream() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, Error>()
        let subject2 = PassthroughSubject<Int, Error>()
        let subject3 = PassthroughSubject<Int, Error>()

        var testError: Error?

        subject1
            .flatMap { _ in subject2.withLatestFrom(subject3) }
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else {
                        XCTFail()
                        return
                    }

                    testError = error

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        subject1.send(completion: .failure(TestError.generic))

        wait(for: [expectation], timeout: 0.1)

        XCTAssertNotNil(testError)
    }

    func testUpstreamCompletionEventsArePropogatedDownstream() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()
        let subject3 = PassthroughSubject<Int, Never>()

        var isFinished = false

        subject1
            .flatMap { _ in subject2.withLatestFrom(subject3) }
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    isFinished = true
                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        subject1.send(completion: .finished)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertTrue(isFinished)
    }

    func testCompletionEventsFromFirstPublisherArePropogatedDownstream() {

        let expectation = XCTestExpectation(description: "Should complete")

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        var isFinished = false

        subject1
            .withLatestFrom(subject2, resultSelector: { ($0, $1) })
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    isFinished = true
                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        subject1.send(completion: .finished)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertTrue(isFinished)
    }

    func testCompletionEventsFromSecondPublisherAreNotPropogatedDownstream() {

        let expectation = XCTestExpectation(description: "Should complete")
        expectation.isInverted = true

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        var isFinished = false

        subject1
            .withLatestFrom(subject2, resultSelector: { ($0, $1) })
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    isFinished = true
                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        subject2.send(completion: .finished)
        subject1.send(0)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertFalse(isFinished)
    }

    func testWithLatestFromWithUpstreamEmpty() {

        let expectation = XCTestExpectation(description: "Should complete")

        let just = Just(0).eraseToAnyPublisher()

        var output = [Int]()

        Empty<Int, Never>()
            .withLatestFrom(just)
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { output.append($0) }
            )
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertEqual(output, [])
    }

    func testWithLatestFromWithSecondEmpty() {

        let expectation = XCTestExpectation(description: "Should complete")

        let just = Just(0).eraseToAnyPublisher()

        var output = [Int]()

        just
            .withLatestFrom(Empty<Int, Never>())
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { output.append($0) }
            )
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertEqual(output, [])
    }

    func testWithLatestFromCanBeCancelled() {

        let expectation = XCTestExpectation(description: "Should complete")
        expectation.isInverted = true

        let subject1 = PassthroughSubject<Int, Never>()
        let subject2 = PassthroughSubject<Int, Never>()

        var isFinished = false

        let cancellable = subject1
            .withLatestFrom(subject2, resultSelector: { ($0, $1) })
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail()
                        return
                    }

                    isFinished = true
                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )

        subject1.send(0)

        cancellable.cancel()

        subject2.send(1)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertFalse(isFinished)
    }
}
