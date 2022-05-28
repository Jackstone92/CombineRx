//
//  BridgeSubscription.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import Combine
import RxSwift

final class BridgeSubscription<U: ObservableType, D: Subscriber>: Subscription where U.Element == D.Input,
                                                                                     D.Failure == BridgeFailure {

    enum Status {
        case active(disposeBag: DisposeBag)
        case pending
        case completed
    }

    private let upstream: U
    private let downstream: D
    private var status: Status = .pending

    init(upstream: U, downstream: D) {
        self.upstream = upstream
        self.downstream = downstream
    }

    // While RxSwift does not have intrinsic back pressure support, legal behaviour can be guaranteed because the subscriber
    // is in fact a `Buffer` sink that is enforced by the API (with an internal operator initialiser).
    // All that must be done is to ensure that a subscription commences whenever a demand threshold of `1` is reached.
    func request(_ demand: Subscribers.Demand) {
        guard case .pending = status, demand > .none else {
            return
        }

        let disposeBag = DisposeBag()

        upstream
            .subscribe(
                onNext: { [unowned self] value in _ = self.downstream.receive(value) },
                onError: { [unowned self] error in self.downstream.receive(completion: .failure(.upstreamError(error))) },
                onCompleted: { [unowned self] in self.downstream.receive(completion: .finished) }
            )
            .disposed(by: disposeBag)

        status = .active(disposeBag: disposeBag)
    }

    func cancel() {
        status = .completed
    }
}
