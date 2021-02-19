//
//  Publisher+FlatMapLatestTests.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import XCTest
import Combine
@testable import CombineRx

final class Publisher_FlatMapLatestTests: XCTestCase {

    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
    }

    /// In this example, using `flatMap` may have unintended consequences. After assigning 👧🏼 to `player.value`, `👧🏼.score`
    /// will begin to emit elements, but the previous inner sequence (`👦🏻.score`) will also still emit elements.
    /// By changing `flatMap` to `flatMapLatest`, only the most recent inner sequence (`👧🏼.score`) will emit
    /// elements, i.e., setting `👦🏻.score.value` to `95` has no effect.
    ///
    /// Note that: `flatMapLatest` is actually a combination of the `map` and `switchLatest` operators.
    func testFlatMapLatestBehavesAsExpected() {

        var flatMapResults = [Int]()
        var flatMapLatestResults = [Int]()

        let 👦🏻 = Player(score: 80)
        let 👧🏼 = Player(score: 90)

        let flatMapPlayer = CurrentValueSubject<Player, Never>(👦🏻)
        let flatMapLatestPlayer = CurrentValueSubject<Player, Never>(👦🏻)

        flatMapPlayer
            .eraseToAnyPublisher()
            .flatMap { $0.score.eraseToAnyPublisher() }
            .sink(receiveValue: { flatMapResults.append($0) })
            .store(in: &subscriptions)

        flatMapLatestPlayer
            .eraseToAnyPublisher()
            .flatMapLatest { $0.score.eraseToAnyPublisher() }
            .sink(receiveValue: { flatMapLatestResults.append($0) })
            .store(in: &subscriptions)

        👦🏻.score.send(85)

        flatMapPlayer.send(👧🏼)
        flatMapLatestPlayer.send(👧🏼)

        👦🏻.score.send(95) // Will be included when using flatMap, but will not when using flatMapLatest

        👧🏼.score.send(100)

        let expectedFlatMapResults = [80, 85, 90, 95, 100]
        let expectedFlatMapLatestResults = [80, 85, 90, 100]

        XCTAssertEqual(flatMapResults, expectedFlatMapResults)
        XCTAssertEqual(flatMapLatestResults, expectedFlatMapLatestResults)
    }

    func testEmpty() {

        Empty<Int, TestError>()
            .flatMapLatest { Just($0 * 2).setFailureType(to: TestError.self) }
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

    func testFailureInTransform() {

        Just(1)
            .setFailureType(to: TestError.self)
            .flatMapLatest { _ in Fail<Int, TestError>(error: TestError.generic) }
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

    func testFailureDownstream() {

        Just(1)
            .setFailureType(to: TestError.self)
            .flatMapLatest { Just($0 * 2).setFailureType(to: TestError.self) }
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

    func testFailureUpstream() {

        Just(1)
            .setFailureType(to: TestError.self)
            .flatMap { _ in Fail<Int, TestError>(error: TestError.generic) }
            .flatMapLatest { Just($0 * 2).setFailureType(to: TestError.self) }
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
}

fileprivate struct Player {
    let score: CurrentValueSubject<Int, Never>

    init(score: Int) {
        self.score = CurrentValueSubject<Int, Never>(score)
    }
}
