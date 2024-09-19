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

    private var subscriptions = Set<AnyCancellable>()
    private var scheduler: TestSchedulerOf<DispatchQueue>!

    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
        scheduler = DispatchQueue.test
    }

    func testPublishSubjectOnNextEventsAreBridged() {

        let subject = PublishSubject<Int>()
        var output = [Int]()

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in output.append(value) }
            )
            .store(in: &subscriptions)

        XCTAssertTrue(output.isEmpty)

        subject.onNext(0)

        scheduler.advance()

        XCTAssertEqual(output, [0])
    }

    func testOnCompleteEventsArePropagatedDownstream() {

        var didCompleteWithFinished = false
        let subject = PublishSubject<Int>()

        subject
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail("Did not complete with `.finished`")
                        return
                    }

                    didCompleteWithFinished = true
                },
                receiveValue: { _ in }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(didCompleteWithFinished)

        subject.onCompleted()

        scheduler.advance()

        XCTAssertTrue(didCompleteWithFinished)
    }

    func testOnErrorEventsArePropagatedDownstream() {

        var didCompleteWithFailure = false
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

                    didCompleteWithFailure = true
                },
                receiveValue: { _ in XCTFail("Should not receive any values") }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(didCompleteWithFailure)

        subject.onError(testError)

        scheduler.advance()

        XCTAssertTrue(didCompleteWithFailure)
    }

    func testErrorTypeCanBeChainedDownstreamIfAlsoErrorType() {

        var didCompleteWithFailure = false
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

                    didCompleteWithFailure = true
                },
                receiveValue: { _ in XCTFail("Should not receive any values") }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(didCompleteWithFailure)

        subject.onError(TestError.generic)

        scheduler.advance()

        XCTAssertTrue(didCompleteWithFailure)
    }

    func testErrorTypeCanBeMappedFurtherDownstream() {

        var didCompleteWithFailure = false
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

                    didCompleteWithFailure = true
                },
                receiveValue: { _ in XCTFail("Should not receive any values") }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(didCompleteWithFailure)

        subject.onError(TestError.generic)

        scheduler.advance()

        XCTAssertTrue(didCompleteWithFailure)
    }

    func testCanFillBufferWithEvents() {

        let bufferSize = 100
        let subject = PublishSubject<Int>()
        var output = [Int]()

        subject
            .asPublisher(withBufferSize: bufferSize, andBridgeBufferingStrategy: .error)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in output.append(value) }
            )
            .store(in: &subscriptions)

        XCTAssertTrue(output.isEmpty)

        (0..<100).forEach { int in subject.onNext(int) }

        scheduler.advance()

        XCTAssertEqual(output.count, bufferSize)
    }

    func testErrorBridgeBufferStrategy() {

        var didCompleteWithFailure = false
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

                    didCompleteWithFailure = true
                },
                receiveValue: { _ in }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(didCompleteWithFailure)

        scheduler.advance()

        XCTAssertTrue(didCompleteWithFailure)
    }

    func testDropNewestBridgeBufferStrategy() {

        let bufferSize = 100
        var output = [Int]()

        Observable.from(Array(0..<bufferSize + 1))
            .asPublisher(withBufferSize: bufferSize, andBridgeBufferingStrategy: .dropNewest)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in output.append(value) }
            )
            .store(in: &subscriptions)

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
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in output.append(value) }
            )
            .store(in: &subscriptions)

        let expected = Array(1..<bufferSize + 1)

        scheduler.advance()

        XCTAssertEqual(output, expected)
    }

    func testAssertBridgeBufferDoesNotOverflowIfPossiblePropagatesErrors() {

        var didCompleteWithFailure = false
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

                    didCompleteWithFailure = true
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(didCompleteWithFailure)

        subject.onError(TestError.generic)

        scheduler.advance()

        XCTAssertTrue(didCompleteWithFailure)
    }

    func testAssertBridgeBufferDoesNotOverflowIfPossiblePropagatesUpstreamBridgeFailureErrors() {

        var didCompleteWithFailure = false
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

                    didCompleteWithFailure = true
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(didCompleteWithFailure)

        subject.onError(BridgeFailure.upstreamError(TestError.generic))

        scheduler.advance()

        XCTAssertTrue(didCompleteWithFailure)
    }

    func testAssertBridgeBufferDoesNotOverflowIfPossibleIsTriggeredOnBridgeBufferOverflow() {

        var didCompleteWithFailure = false
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

                    didCompleteWithFailure = true
                },
                receiveValue: { _ in XCTFail() }
            )
            .store(in: &subscriptions)

        XCTAssertFalse(didCompleteWithFailure)

        subject.onError(BridgeFailure.bufferOverflow)

        scheduler.advance()

        XCTAssertTrue(didCompleteWithFailure)
    }
}
