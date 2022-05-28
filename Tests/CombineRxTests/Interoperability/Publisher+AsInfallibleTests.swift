//
//  Publisher+AsInfallibleTests.swift
//  Copyright © 2022 Jack Stone. All rights reserved.
//

import XCTest
import Combine
import RxSwift
import RxTest
import CombineRx

final class Publisher_AsInfallibleTests: XCTestCase {

    private var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
    }

    // MARK: - asInfallible() tests
    func testPassthroughSubjectSendEventsAreBridged() {

        let disposeBag = DisposeBag()

        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, Never>()

        scheduler.scheduleAt(100) {
            subject
                .asInfallible()
                .subscribe(
                    onNext: { output.onNext($0) },
                    onCompleted: { output.onCompleted() }
                )
                .disposed(by: disposeBag)
        }

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(1) }
        scheduler.scheduleAt(400) { subject.send(2) }
        scheduler.scheduleAt(500) { subject.send(3) }

        let expectedEvents = [
            Recorded.next(200, 0),
            Recorded.next(300, 1),
            Recorded.next(400, 2),
            Recorded.next(500, 3)
        ]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    func testPublisherSendEventsAreBridged() {

        let disposeBag = DisposeBag()

        let publisher = Just<Int>(1)
        let output = scheduler.createObserver(Int.self)

        scheduler.scheduleAt(100) {
            publisher
                .asInfallible()
                .subscribe(
                    onNext: { output.onNext($0) },
                    onCompleted: { output.onCompleted() }
                )
                .disposed(by: disposeBag)
        }

        let expectedEvents = [Recorded.next(100, 1), Recorded.completed(100)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    func testSequencePublisherEventsAreBridged() {

        let disposeBag = DisposeBag()

        let publisher = Just<[Int]>([1, 2, 3, 4, 5])
        let output = scheduler.createObserver([Int].self)

        scheduler.scheduleAt(100) {
            publisher
                .asInfallible()
                .subscribe(
                    onNext: { output.onNext($0) },
                    onCompleted: { output.onCompleted() }
                )
                .disposed(by: disposeBag)
        }

        let expectedEvents = [Recorded.next(100, [1, 2, 3, 4, 5]), Recorded.completed(100)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    func testCompleteEventsArePropagatedDownstream() {

        let disposeBag = DisposeBag()

        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, Never>()

        scheduler.scheduleAt(100) {
            subject
                .asInfallible()
                .subscribe(
                    onNext: { output.onNext($0) },
                    onCompleted: { output.onCompleted() }
                )
                .disposed(by: disposeBag)
        }

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(completion: .finished) }

        let expectedEvents = [Recorded.next(200, 0), Recorded.completed(300)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    // MARK: - asInfallible(onErrorJustReturn:) tests
    func testCanReturnElementOnError() {

        let disposeBag = DisposeBag()

        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, TestError>()

        scheduler.scheduleAt(100) {
            subject
                .asInfallible(onErrorJustReturn: Int.max)
                .subscribe(
                    onNext: { output.onNext($0) },
                    onCompleted: { output.onCompleted() }
                )
                .disposed(by: disposeBag)
        }

        let error = TestError.generic

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(completion: .failure(error)) }

        let expectedEvents = [Recorded.next(200, 0), Recorded.next(300, Int.max), Recorded.completed(300)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    // MARK: - asInfallible(onErrorRecover:) tests
    func testCanRecoverFromErrorUsingClosureOnError() {

        let disposeBag = DisposeBag()

        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, TestError>()
        let recoverySubject = PassthroughSubject<Int, Never>()

        let recovery: (Error) -> AnyPublisher<Int, Never> = { error in
            guard case TestError.generic = error else { XCTFail(); return Empty().eraseToAnyPublisher() }
            return recoverySubject.eraseToAnyPublisher()
        }

        scheduler.scheduleAt(100) {
            subject
                .asInfallible(onErrorRecover: recovery)
                .subscribe(
                    onNext: { output.onNext($0) },
                    onCompleted: { output.onCompleted() }
                )
                .disposed(by: disposeBag)
        }

        let error = TestError.generic

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(completion: .failure(error)) }
        scheduler.scheduleAt(400) { recoverySubject.send(1) }
        scheduler.scheduleAt(500) { recoverySubject.send(2) }
        scheduler.scheduleAt(600) { recoverySubject.send(completion: .finished) }

        let expectedEvents = [
            Recorded.next(200, 0),
            Recorded.next(400, 1),
            Recorded.next(500, 2),
            Recorded.completed(600)
        ]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    // MARK: - asInfallible(onErrorFallbackTo:) tests
    func testCanFallbackToPublisherOnError() {

        let disposeBag = DisposeBag()

        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, TestError>()
        let recoverySubject = PassthroughSubject<Int, Never>()

        scheduler.scheduleAt(100) {
            subject
                .asInfallible(onErrorFallbackTo: recoverySubject.eraseToAnyPublisher())
                .subscribe(
                    onNext: { output.onNext($0) },
                    onCompleted: { output.onCompleted() }
                )
                .disposed(by: disposeBag)
        }

        let error = TestError.generic

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(completion: .failure(error)) }
        scheduler.scheduleAt(400) { recoverySubject.send(1) }
        scheduler.scheduleAt(500) { recoverySubject.send(2) }
        scheduler.scheduleAt(600) { recoverySubject.send(completion: .finished) }

        let expectedEvents = [
            Recorded.next(200, 0),
            Recorded.next(400, 1),
            Recorded.next(500, 2),
            Recorded.completed(600)
        ]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }
}
