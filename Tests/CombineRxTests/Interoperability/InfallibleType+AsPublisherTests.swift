//
//  InfallibleType+AsPublisherTests.swift
//  
//
//  Created by Jack Stone on 24/05/2022.
//

import XCTest
import Combine
import RxSwift
import CombineSchedulers
import CombineRx

final class InfallibleType_AsPublisherTests: XCTestCase {


    private var subscriptions: Set<AnyCancellable>!
    private var scheduler: TestSchedulerOf<DispatchQueue>!

    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
        scheduler = DispatchQueue.test
    }

    func test_infallibleIsBridged() {

        let subject = PublishSubject<Int>()
        var output = [Int]()

        subject.asInfallible(onErrorJustReturn: -1)
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .receive(on: scheduler)
            .sink { output.append($0) }
            .store(in: &subscriptions)

        XCTAssertTrue(output.isEmpty)

        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)

        scheduler.advance()

        XCTAssertEqual(output, [1, 2, 3])
    }

    func test_onCompleteEventsArePropagatedDownstream() {

        var didCompleteWithFinished = false
        let subject = PublishSubject<Int>()

        subject.asInfallible(onErrorJustReturn: -1)
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: {
                    guard case .finished = $0 else {
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

    func test_onErrorEventsReturnFallbackValue() {

        let subject = PublishSubject<Int>()
        var output = [Int]()

        subject.asInfallible(onErrorJustReturn: -1)
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .receive(on: scheduler)
            .sink { output.append($0) }
            .store(in: &subscriptions)

        XCTAssertTrue(output.isEmpty)

        subject.onNext(55)
        subject.onNext(48)
        subject.onNext(19)
        subject.onError(TestError.generic)

        scheduler.advance()

        XCTAssertEqual(output, [55, 48, 19, -1])

        subject.onNext(21)

        scheduler.advance()

        XCTAssertEqual(output, [55, 48, 19, -1])
    }

    func test_onErrorEventsReturnFallbackInfallible() {

        let subject = PublishSubject<Int>()
        var receivedErrors = [Error]()
        var output = [Int]()

        subject.asInfallible(
            onErrorRecover: { error in
                receivedErrors.append(error)
                return .just(999).asInfallible(onErrorJustReturn: -1)
            }
        )
        .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
        .receive(on: scheduler)
        .sink { output.append($0) }
        .store(in: &subscriptions)

        XCTAssertTrue(output.isEmpty)
        XCTAssertTrue(receivedErrors.isEmpty)

        subject.onNext(55)
        subject.onNext(48)
        subject.onNext(19)
        subject.onError(TestError.generic)

        scheduler.advance()

        XCTAssertEqual(output, [55, 48, 19, 999])
    }

    func testDropNewestBridgeBufferStrategy() {

        let bufferSize = 100
        var output = [Int]()

        Infallible.from(Array(0..<bufferSize + 1))
            .asPublisher(withBufferSize: bufferSize, andBridgeBufferingStrategy: .dropNewest)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { output.append($0) }
            )
            .store(in: &subscriptions)

        let expected = Array(0..<bufferSize)

        scheduler.advance()

        XCTAssertEqual(output, expected)
    }

    func testDropOldestBridgeBufferStrategy() {

        let bufferSize = 100
        var output = [Int]()

        Infallible.from(Array(0..<bufferSize + 1))
            .asInfallible(onErrorJustReturn: -1)
            .asPublisher(withBufferSize: bufferSize, andBridgeBufferingStrategy: .dropOldest)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { output.append($0) }
            )
            .store(in: &subscriptions)

        let expected = Array(1..<bufferSize + 1)

        scheduler.advance()

        XCTAssertEqual(output, expected)
    }
}
