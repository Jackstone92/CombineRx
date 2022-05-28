//
//  BridgeSubscription+Witness.swift
//  
//
//  Created by Jack Stone on 24/05/2022.
//

import Foundation
import RxSwift

// MARK: - ObservableType
extension BridgeSubscription.Witness where U: ObservableType, U.Element == D.Input, D.Failure == BridgeFailure {

    static var observableType: Self {
        Self(
            subscribe: { upstream, downstream in
                upstream
                    .subscribe(
                        onNext: { value in _ = downstream.receive(value) },
                        onError: { error in downstream.receive(completion: .failure(.upstreamError(error))) },
                        onCompleted: { downstream.receive(completion: .finished) }
                    )
            }
        )
    }
}

// MARK: - InfallibleType
extension BridgeSubscription.Witness where U: InfallibleType, U.Element == D.Input, D.Failure == Never {

    static var infallibleType: Self {
        Self(
            subscribe: { upstream, downstream in
                upstream
                    .subscribe(
                        onNext: { value in _ = downstream.receive(value) },
                        onCompleted: { downstream.receive(completion: .finished) }
                    )
            }
        )
    }
}
