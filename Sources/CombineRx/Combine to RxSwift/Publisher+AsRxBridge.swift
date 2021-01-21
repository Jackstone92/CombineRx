//
//  Publisher+AsRxBridge.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import Combine
import RxSwift

extension Publisher {

    /// A bridging function that transforms a Combine `Publisher` into an RxSwift `Observable`.
    ///
    /// - Returns: An RxSwift `Observable` that is the bridged transformation of the given `Publisher`.
    public func asRxBridge() -> Observable<Output> {
        return .create { observer -> Disposable in
            let cancellable = sink { completion in
                switch completion {
                case .finished:             observer.onCompleted()
                case .failure(let error):   observer.onError(error)
                }

            } receiveValue: { value in
                observer.onNext(value)
            }

            return Disposables.create {
                cancellable.cancel()
            }
        }
    }
}
