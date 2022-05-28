//
//  Publisher+AsInfallible.swift
//  Copyright © 2022 Jack Stone. All rights reserved.
//

import Combine
import RxSwift

extension Publisher where Failure == Never {

    /// A bridging function that transforms a Combine `Publisher` into an RxSwift `Infallible`.
    ///
    /// This is a direct transformation when the `Failure` type is already `Never`.
    ///
    /// - Returns: An RxSwift `Infallible` that is the bridged transformation of the given `Publisher`.
    ///
    public func asInfallible() -> Infallible<Output> {
        return .create { observer -> Disposable in

            let cancellable = sink(
                receiveCompletion: { _ in observer(.completed) },
                receiveValue: { observer(.next($0)) }
            )

            return Disposables.create {
                cancellable.cancel()
            }
        }
    }
}

extension Publisher {

    /// A bridging function that transforms a Combine `Publisher` into an RxSwift `Infallible`.
    ///
    /// If any error is encountered, the provided `element` is returned.
    ///
    /// - Parameter onErrorJustReturn: The element to return in the event of an error.
    ///
    /// - Returns: An RxSwift `Infallible` that is the bridged transformation of the given `Publisher`.
    ///
    public func asInfallible(onErrorJustReturn element: Output) -> Infallible<Output> {
        return asObservable()
            .asInfallible(onErrorJustReturn: element)
    }

    /// A bridging function that transforms a Combine `Publisher` into an RxSwift `Infallible`.
    ///
    /// If any error is encountered, the provided `onErrorRecover` closure is invoked.
    ///
    /// - Parameter onErrorRecover: A recovery closure that is invoked in the event of an error.
    ///
    /// - Returns: An RxSwift `Infallible` that is the bridged transformation of the given `Publisher`.
    ///
    public func asInfallible(onErrorRecover: @escaping (Error) -> AnyPublisher<Output, Never>) -> Infallible<Output> {
        return asObservable()
            .asInfallible(onErrorRecover: { onErrorRecover($0).asInfallible() })
    }

    /// A bridging function that transforms a Combine `Publisher` into an RxSwift `Infallible`.
    ///
    /// If any error is encountered, the provided `publisher` is used to fall back.
    ///
    /// - Parameter onErrorFallbackTo: A fallback publisher that is returned in the event of an error.
    ///
    /// - Returns: An RxSwift `Infallible` that is the bridged transformation of the given `Publisher`.
    ///
    public func asInfallible(onErrorFallbackTo publisher: AnyPublisher<Output, Never>) -> Infallible<Output> {
        return asObservable()
            .asInfallible(onErrorFallbackTo: publisher.asInfallible())
    }
}
