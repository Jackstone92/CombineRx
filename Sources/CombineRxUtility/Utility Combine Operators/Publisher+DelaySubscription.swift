//
//  Publisher+DelaySubscription.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import Foundation
import Combine

extension Publisher {

    /// Time shifts the observable sequence by delaying the subscription with the specified relative time duration, using the specified scheduler to run timers.
    ///
    /// [More info](http://reactivex.io/documentation/operators/delay.html)
    ///
    /// - Parameter interval: The amount of delay time.
    /// - Parameter tolerance: The allowed tolerance in the firing of the delayed subscription.
    /// - Parameter scheduler: The scheduler to run the subscription delay timer on
    /// - Parameter options: Any additional scheduler options.
    ///
    /// - Returns: The time-shifted sequence.
    ///
    public func delaySubscription<S: Scheduler>(for interval: S.SchedulerTimeType.Stride,
                                                tolerance: S.SchedulerTimeType.Stride? = nil,
                                                scheduler: S,
                                                options: S.SchedulerOptions? = nil) -> Publishers.DelaySubscription<Self, S> {
        return Publishers.DelaySubscription(upstream: self,
                                            interval: interval,
                                            tolerance: tolerance ?? scheduler.minimumTolerance,
                                            scheduler: scheduler,
                                            options: options)
    }
}

// MARK: - Publisher
// The various operators defined as extensions on `Publisher` implement their functionality as classes or structs
// that extend this `Publishers` enumeration. For example, the `contains(_:)` operator returns a `Publishers.Contains` instance.
// Following this pattern, the `delaySubscription(for:tolerance:scheduler:options:)` operator should return a
// `Publishers.DelaySubscription` instance.
extension Publishers {

    /// A publisher that delays subscription of upstream.
    ///
    /// Follows the RxSwift design as seen [here](https://github.com/ReactiveX/RxSwift/blob/main/RxSwift/Observables/DelaySubscription.swift)
    public struct DelaySubscription<U: Publisher, S: Scheduler>: Publisher {

        public typealias Output = U.Output      // Upstream output
        public typealias Failure = U.Failure    // Upstream failure

        /// The publisher that this publisher receives signals from.
        public let upstream: U

        /// The amount of delay time.
        public let interval: S.SchedulerTimeType.Stride

        /// The allowed tolerance in the firing of the delayed subscription.
        public let tolerance: S.SchedulerTimeType.Stride

        /// The scheduler to run the subscription delay timer on.
        public let scheduler: S

        /// Any additional scheduler options.
        public let options: S.SchedulerOptions?

        init(upstream: U,
             interval: S.SchedulerTimeType.Stride,
             tolerance: S.SchedulerTimeType.Stride,
             scheduler: S,
             options: S.SchedulerOptions?) {
            self.upstream = upstream
            self.interval = interval
            self.tolerance = tolerance
            self.scheduler = scheduler
            self.options = options
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            self.upstream.subscribe(DelayedSubscription(publisher: self, downstream: subscriber))
        }
    }
}

// MARK: - Subscription
private extension Publishers.DelaySubscription {

    /// The actual delayed subsription where the scheduler advancing takes place.
    final class DelayedSubscription<D: Subscriber>: Subscriber where D.Input == Output, D.Failure == U.Failure {

        typealias Input = U.Output      // Upstream output
        typealias Failure = U.Failure   // Upstream failure

        private let interval: S.SchedulerTimeType.Stride
        private let tolerance: S.SchedulerTimeType.Stride
        private let scheduler: S
        private let options: S.SchedulerOptions?

        private let downstream: D

        init(publisher: Publishers.DelaySubscription<U, S>,
             downstream: D) {
            self.interval = publisher.interval
            self.tolerance = publisher.tolerance
            self.scheduler = publisher.scheduler
            self.options = publisher.options
            self.downstream = downstream
        }

        func receive(subscription: Subscription) {
            scheduler.schedule(after: scheduler.now.advanced(by: interval),
                               tolerance: tolerance,
                               options: options) { [weak self] in
                self?.downstream.receive(subscription: subscription)
            }
        }

        func receive(_ input: U.Output) -> Subscribers.Demand {
            return downstream.receive(input)
        }

        func receive(completion: Subscribers.Completion<U.Failure>) {
            downstream.receive(completion: completion)
        }
    }
}
