//
//  InfallibleTypeBridgePublisher.swift
//  
//
//  Created by Jack Stone on 24/05/2022.
//

import Combine
import RxSwift

/// A `Publisher` that handles subscriptions from an upstream `InfallibleType`.
public struct InfallibleTypeBridgePublisher<U: InfallibleType>: Publisher {

    public typealias Output = U.Element
    public typealias Failure = Never

    private let upstream: U

    init(upstream: U) {
        self.upstream = upstream
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        subscriber.receive(
            subscription: BridgeSubscription(
                upstream: upstream,
                downstream: subscriber,
                witness: .infallibleType
            )
        )
    }
}
