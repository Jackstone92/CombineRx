//
//  Publisher+AsRxBridge.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import XCTest
import RxTest
import Combine
import RxSwift
@testable import CombineRxBridge

final class AsRxBridgeTests: XCTestCase {

    private var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
    }

    func testPassthroughSubjectSendEventsAreBridged() {

        let disposeBag = DisposeBag()
        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, Never>()

        scheduler.scheduleAt(100) {
            subject
                .asRxBridge()
                .subscribe(output)
                .disposed(by: disposeBag)
        }

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(1) }
        scheduler.scheduleAt(400) { subject.send(2) }
        scheduler.scheduleAt(500) { subject.send(3) }

        let expectedEvents = [Recorded.next(200, 0),
                              Recorded.next(300, 1),
                              Recorded.next(400, 2),
                              Recorded.next(500, 3)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }

    func testCompleteEventsArePropogatedDownstream() {

        let disposeBag = DisposeBag()
        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, Never>()

        scheduler.scheduleAt(100) {
            subject
                .asRxBridge()
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

    func testErrorsArePropogatedDownstream() {

        let disposeBag = DisposeBag()
        let output = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, BridgeFailure>()

        scheduler.scheduleAt(100) {
            subject
                .asRxBridge()
                .subscribe(output)
                .disposed(by: disposeBag)
        }

        let error = BridgeFailure.upstreamError(TestError.generic)

        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(completion: .failure(error)) }

        let expectedEvents = [Recorded.next(200, 0),
                              Recorded.error(300, error)]

        scheduler.start()

        XCTAssertEqual(output.events, expectedEvents)
    }
}

private enum TestError: Error {
    case generic
}
