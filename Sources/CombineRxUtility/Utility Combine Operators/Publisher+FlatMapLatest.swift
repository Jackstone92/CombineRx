//
//  Publisher+FlatMapLatest.swift
//  Copyright © 2021 Jack Stone. All rights reserved.
//

import Combine

extension Publisher {

    /// Projects each element of an observable sequence into a new sequence of observable sequences and then
    /// transforms an observable sequence of observable sequences into an observable sequence producing values only from the most recent observable sequence.
    ///
    /// It is a combination of `map` + `switchLatest` operator
    ///
    /// This is useful when, for example, when you have a sequence that itself emits observable
    /// sequences, and you want to be able to react to new emissions from either sequence. The difference
    /// between `flatMap` and `flatMapLatest` is that `flatMapLatest` will only emit elements from the most recent
    /// inner sequence. [More info](http://reactivex.io/documentation/operators/flatmap.html)
    ///
    /// - Parameter transform: A transform function to apply to each element.
    ///
    /// - Returns: An observable sequence whose elements are the result of invoking the transform function on each element of source producing an
    ///            observable of observable sequences and that at any point in time produces the elements of the most recent inner observable sequence that has been received.
    ///
    public func flatMapLatest<T: Publisher>(_ transform: @escaping (Self.Output) -> T) -> Publishers.SwitchToLatest<T, Publishers.Map<Self, T>> where T.Failure == Self.Failure {
        map(transform).switchToLatest()
    }
}
