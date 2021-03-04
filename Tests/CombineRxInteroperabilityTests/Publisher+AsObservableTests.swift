//
//  Publisher+AsObservableTests.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import XCTest
import RxTest
import Combine
import RxSwift
@testable import TestCommon
@testable import CombineRxInteroperability

final class Publisher_AsObservableTests: XCTestCase {

    /// A test scheduler that uses virtual time. This means that we don't need to waste
    /// test time waiting for any `XTCExpectation`s. For example, using this test scheduler, it is
    /// easy to test operators like delay/debounce etc without having to actually wait `n` seconds or milliseconds.
    private var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
    }

    /// Tests that we can convert observables being emitted from a Combine `PassthroughSubject`
    /// into an RxSwift `Observable` and that emitted elements are propogated correctly.
    func testPassthroughSubjectSendEventsAreBridged() {

        let disposeBag = DisposeBag()

        // Register an observer with the test scheduler
        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, Never>()

        // Set up a subscription to the Combine subject and use bridging method to convert to an RxSwift `Observable`
        scheduler.scheduleAt(100) {
            subject
                .asObservable()
                .subscribe(output)
                .disposed(by: disposeBag)
        }

        // Specify some test events that will be emitted from our Combine subject at various test time intervals
        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(1) }
        scheduler.scheduleAt(400) { subject.send(2) }
        scheduler.scheduleAt(500) { subject.send(3) }

        // Specify our expected events that will have been recorded by our test scheduler at a given test time and
        // with the expected received element
        let expectedEvents = [Recorded.next(200, 0),
                              Recorded.next(300, 1),
                              Recorded.next(400, 2),
                              Recorded.next(500, 3)]

        // Run the test scheduler and assert that the recorded events are the same as what we were expecting
        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    /// Tests that publishers like `Just<Int>` with single elements are propogated into the RxSwift world.
    func testPublisherSendEventsAreBridged() {

        let disposeBag = DisposeBag()

        let publisher = Just<Int>(1)
        let output = scheduler.createObserver(Int.self)

        scheduler.scheduleAt(100) {
            publisher
                .asObservable()
                .subscribe(output)
                .disposed(by: disposeBag)
        }

        let expectedEvents = [Recorded.next(100, 1), Recorded.completed(100)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    /// Tests that publishers like `Just<[Int]>` with a sequence of elements are propogated into the RxSwift world.
    func testSequencePublisherEventsAreBridged() {

        let disposeBag = DisposeBag()

        let publisher = Just<[Int]>([1, 2, 3, 4, 5])
        let output = scheduler.createObserver([Int].self)

        scheduler.scheduleAt(100) {
            publisher
                .asObservable()
                .subscribe(output)
                .disposed(by: disposeBag)
        }

        let expectedEvents = [Recorded.next(100, [1, 2, 3, 4, 5]), Recorded.completed(100)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    /// Tests that when a Combine publisher emits a completion, this is propogated into the RxSwift world.
    func testCompleteEventsArePropogatedDownstream() {

        let disposeBag = DisposeBag()
        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, Never>()

        scheduler.scheduleAt(100) {
            subject
                .asObservable()
                .subscribe(output)
                .disposed(by: disposeBag)
        }

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(completion: .finished) }

        let expectedEvents = [Recorded.next(200, 0),
                              Recorded.completed(300)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    /// Tests that when a Combine publisher emits an error, this is propogated into the RxSwift world.
    func testErrorsArePropogatedDownstream() {

        let disposeBag = DisposeBag()
        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, TestError>()

        scheduler.scheduleAt(100) {
            subject
                .asObservable()
                .subscribe(output)
                .disposed(by: disposeBag)
        }

        let error = TestError.generic

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(completion: .failure(error)) }

        let expectedEvents = [Recorded.next(200, 0),
                              Recorded.error(300, error)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }
}
