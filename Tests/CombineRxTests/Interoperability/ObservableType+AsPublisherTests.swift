//
//  ObservableType+AsPublisherTests.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import XCTest
import Combine
import RxSwift
import CombineSchedulers
@testable import CombineRx

final class ObservableType_AsPublisherTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()
    private var scheduler: TestScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        scheduler = DispatchQueue.testScheduler
    }

    func testPublishSubjectOnNextEventsAreBridged() {

        let subject = PublishSubject<Int>()
        var output = [Int]()

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in output.append(value) })
            .store(in: &cancellables)

        XCTAssertTrue(output.isEmpty)

        subject.onNext(0)

        scheduler.advance()

        XCTAssertEqual(output, [0])
    }

    func testOnCompleteEventsArePropogatedDownstream() {

        let expectation = XCTestExpectation(description: "Should complete with `.finished`")
        let subject = PublishSubject<Int>()

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .sink(receiveCompletion: { completion in
                guard case .finished = completion else {
                    XCTFail("Did not complete with `.finished`")
                    return
                }

                expectation.fulfill()
            },
                  receiveValue: { _ in })
            .store(in: &cancellables)

        subject.onCompleted()

        scheduler.advance()

        wait(for: [expectation], timeout: 0.1)
    }

    func testOnErrorEventsArePropogatedDownstream() {

        let expectation = XCTestExpectation(description: "Should complete with `.failure`")
        let subject = PublishSubject<Int>()
        let testError = BridgeFailure.upstreamError(TestError.generic)

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { completion in
                    guard case .failure = completion else {
                        XCTFail("Did not complete with `.failure`")
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail("Should not receive any values") }
            )
            .store(in: &cancellables)

        subject.onError(testError)

        scheduler.advance()

        wait(for: [expectation], timeout: 0.1)
    }

    func testErrorTypeCanBeChainedDownstreamIfAlsoErrorType() {

        let expectation = XCTestExpectation(description: "Should complete with `.failure`")
        let subject = PublishSubject<Int>()

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .flatMap { value -> AnyPublisher<Int, Error> in
                Just(value * 2)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else {
                        XCTFail("Did not complete with `.failure`")
                        return
                    }

                    guard case TestError.generic = error else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail("Should not receive any values") }
            )
            .store(in: &cancellables)

        subject.onError(TestError.generic)

        scheduler.advance()

        wait(for: [expectation], timeout: 0.1)
    }

    func testErrorTypeCanBeMappedFurtherDownstream() {

        let expectation = XCTestExpectation(description: "Should complete with `.failure`")
        let subject = PublishSubject<Int>()

        struct DatedError: Error {
            let error: Error
            let date: Date

            init(_ error: Error) {
                self.error = error
                date = Date()
            }
        }

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .mapError { DatedError($0) } // Map error required to map from generic `Error` type to desired `DatedError` type
            .flatMap { value -> AnyPublisher<Int, DatedError> in // Dummy flatMap to indicate a possible transform that might be required
                Just(value * 2)
                    .setFailureType(to: DatedError.self)
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let datedError) = completion else {
                        XCTFail("Did not complete with `.failure`")
                        return
                    }

                    guard case TestError.generic = datedError.error else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail("Should not receive any values") }
            )
            .store(in: &cancellables)

        subject.onError(TestError.generic)

        scheduler.advance()

        wait(for: [expectation], timeout: 0.1)
    }

    func testCanFillBufferWithEvents() {

        let bufferSize = 100
        let subject = PublishSubject<Int>()
        var output = [Int]()

        subject
            .asPublisher(withBufferSize: bufferSize, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in output.append(value) })
            .store(in: &cancellables)

        XCTAssertTrue(output.isEmpty)

        (0..<100).forEach { int in subject.onNext(int) }

        scheduler.advance()

        XCTAssertEqual(output.count, bufferSize)
    }

    func testErrorBridgeBufferStrategy() {

        let expectation = XCTestExpectation(description: "Should complete with `.failure`")
        let bufferSize = 100

        Observable.from(Array(0..<bufferSize + 1))
            .asPublisher(withBufferSize: bufferSize, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { completion in
                    guard case .failure = completion else {
                        XCTFail("Did not complete with `.failure`")
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        scheduler.advance()

        wait(for: [expectation], timeout: 0.1)
    }

    func testDropNewestBridgeBufferStrategy() {

        let bufferSize = 100
        var output = [Int]()

        Observable.from(Array(0..<bufferSize + 1))
            .asPublisher(withBufferSize: bufferSize, andBridgeBufferingStrategy: .dropNewest)
            .receive(on: scheduler)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in output.append(value) })
            .store(in: &cancellables)

        let expected = Array(0..<bufferSize)

        scheduler.advance()

        XCTAssertEqual(output, expected)
    }

    func testDropOldestBridgeBufferStrategy() {

        let bufferSize = 100
        var output = [Int]()

        Observable.from(Array(0..<bufferSize + 1))
            .asPublisher(withBufferSize: bufferSize, andBridgeBufferingStrategy: .dropOldest)
            .receive(on: scheduler)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in output.append(value) })
            .store(in: &cancellables)

        let expected = Array(1..<bufferSize + 1)

        scheduler.advance()

        XCTAssertEqual(output, expected)
    }

    func testAssertBridgeBufferDoesNotOverflowIfPossiblePropogatesErrors() {

        let expectation = XCTestExpectation(description: "Should complete with `.failure`")
        let subject = PublishSubject<Int>()

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .assertBridgeBufferDoesNotOverflowIfPossible { XCTFail(); return TestError.other  }
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { completion in
                    guard case .failure = completion else {
                        XCTFail("Did not complete with `.failure`")
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &cancellables)

        subject.onError(TestError.generic)

        scheduler.advance()

        wait(for: [expectation], timeout: 0.1)
    }

    func testAssertBridgeBufferDoesNotOverflowIfPossiblePropogatesUpstreamBridgeFailureErrors() {

        let expectation = XCTestExpectation(description: "Should complete with `.failure`")
        let subject = PublishSubject<Int>()

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .assertBridgeBufferDoesNotOverflowIfPossible { XCTFail(); return TestError.other }
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { completion in
                    guard case .failure = completion else {
                        XCTFail("Did not complete with `.failure`")
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &cancellables)

        subject.onError(BridgeFailure.upstreamError(TestError.generic))

        scheduler.advance()

        wait(for: [expectation], timeout: 0.1)
    }

    func testAssertBridgeBufferDoesNotOverflowIfPossibleIsTriggeredOnBridgeBufferOverflow() {

        let expectation = XCTestExpectation(description: "Should complete with `.failure`")
        let bridgeBufferOverflowExpectation = XCTestExpectation(description: "Should trigger bridge buffer overflow")

        let subject = PublishSubject<Int>()

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .assertBridgeBufferDoesNotOverflowIfPossible { bridgeBufferOverflowExpectation.fulfill(); return BridgeFailure.bufferOverflow }
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else {
                        XCTFail("Did not complete with `.failure`")
                        return
                    }

                    guard case BridgeFailure.bufferOverflow = error else {
                        XCTFail()
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { _ in XCTFail() })
            .store(in: &cancellables)

        subject.onError(BridgeFailure.bufferOverflow)

        scheduler.advance()

        wait(for: [expectation, bridgeBufferOverflowExpectation], timeout: 0.1)
    }
}
