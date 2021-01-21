//
//  BridgePublisher.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import Combine
import RxSwift

public struct BridgePublisher<U: ObservableType>: Publisher {

    public typealias Output = U.Element
    public typealias Failure = BridgeFailure

    private let upstream: U

    init(upstream: U) {
        self.upstream = upstream
    }

    public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        subscriber.receive(subscription: BridgeSubscription(upstream: upstream, downstream: subscriber))
    }
}
