//
//  Publisher+WithLatestFrom.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import Foundation
import Combine

extension Publisher {

    /// Merges two observable sequences into one observable sequence by combining each element from self with the latest element from the second source, if any.
    /// More info can be found [here](http://reactivex.io/documentation/operators/combinelatest.html).
    ///
    /// Note that elements emitted by self before the second source has emitted any values will be omitted.
    ///
    ///  - Parameter second: The second observable source.
    ///  - Parameter resultSelector: The function to invoke for each element from self combined with the latest element from the second source, if any.
    ///
    ///  - Returns: A publisher containing the result of combining each value of the self with the latest value from the second publisher, if any, using the
    ///             specified result selector function.
    ///
    public func withLatestFrom<Second: Publisher, Result>(_ second: Second,
                                                          resultSelector: @escaping (Output, Second.Output) -> Result) -> Publishers.WithLatestFrom<Self, Second, Result> {
        return .init(upstream: self, second: second, resultSelector: resultSelector)
    }

    /// Merges two observable sequences into one observable sequence by using latest element from the second sequence every time when `self` emits an element.
    ///
    /// - Parameter second: The second observable source.
    ///
    /// - Returns: An observable sequence containing the result of combining each element of self with the latest element from the second
    ///            source, if any, using the specified result selector function.
    ///
    public func withLatestFrom<Second: Publisher>(_ second: Second) -> Publishers.WithLatestFrom<Self, Second, Second.Output> {
        return .init(upstream: self, second: second) { $1 }
    }
}

// MARK: - Publisher
extension Publishers {

    public struct WithLatestFrom<U: Publisher,
                                 Second: Publisher,
                                 Output>: Publisher where U.Failure == Second.Failure {

        public typealias Failure = U.Failure
        public typealias ResultSelector = (U.Output, Second.Output) -> Output

        private let upstream: U
        private let second: Second
        private let resultSelector: ResultSelector
        private var latestValue: Second.Output?

        init(upstream: U,
             second: Second,
             resultSelector: @escaping ResultSelector) {
            self.upstream = upstream
            self.second = second
            self.resultSelector = resultSelector
        }

        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let subscription = Subscription(upstream: upstream,
                                            second: second,
                                            resultSelector: resultSelector,
                                            subscriber: subscriber)

            subscriber.receive(subscription: subscription)
        }
    }
}

// MARK: - Subscription
private extension Publishers.WithLatestFrom {

    final class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Output, S.Failure == Failure {

        private let subscriber: S
        private let resultSelector: ResultSelector
        private var latestValue: Second.Output?

        private let upstream: U
        private let second: Second

        private var firstSubscription: Cancellable?
        private var secondSubscription: Cancellable?

        init(upstream: U,
             second: Second,
             resultSelector: @escaping ResultSelector,
             subscriber: S) {
            self.upstream = upstream
            self.second = second
            self.subscriber = subscriber
            self.resultSelector = resultSelector

            subscribeToTrackLatestFromSecond()
        }

        func request(_ demand: Subscribers.Demand) {
            // Since `withLatestFrom` always takes the latest single value from the second observable, we don't really need to worry
            // about demand or backpressure here.
            firstSubscription = upstream
                .sink(
                    receiveCompletion: { [weak self] in self?.subscriber.receive(completion: $0) },
                    receiveValue: { [weak self] value in
                        guard let self = self else { return }
                        guard let latest = self.latestValue else { return }

                        _ = self.subscriber.receive(self.resultSelector(value, latest))
                    })
        }

        func cancel() {
            firstSubscription?.cancel()
            secondSubscription?.cancel()
        }

        /// Creates a subscription to the `Second` publisher that continuously tracks its latest value.
        private func subscribeToTrackLatestFromSecond() {
            let subscriber = makeTrackLatestSubscriber()

            self.second.subscribe(subscriber)
        }

        private func makeTrackLatestSubscriber() -> AnySubscriber<Second.Output, Second.Failure> {
            return .init(receiveSubscription: { [weak self] subscription in
                self?.secondSubscription = subscription
                subscription.request(.unlimited)
            },
            receiveValue: { [weak self] value in
                self?.latestValue = value
                return .unlimited
            },
            receiveCompletion: nil)
        }
    }
}
