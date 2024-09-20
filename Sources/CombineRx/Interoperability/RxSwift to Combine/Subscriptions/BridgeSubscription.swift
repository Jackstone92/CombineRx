//
//  BridgeSubscription.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import Combine
import RxSwift

final class BridgeSubscription<Upstream, Downstream: Subscriber>: Subscription {
    enum Status {
        case active(disposeBag: DisposeBag)
        case pending
        case completed
    }

    struct Witness<U, D: Subscriber> {
        let subscribe: (_ upstream: U, _ downstream: D) -> Disposable
    }

    private let upstream: Upstream
    private let downstream: Downstream
    private let witness: Witness<Upstream, Downstream>
    private var status: Status = .pending

    init(upstream: Upstream, downstream: Downstream, witness: Witness<Upstream, Downstream>) {
        self.upstream = upstream
        self.downstream = downstream
        self.witness = witness
    }

    func request(_ demand: Subscribers.Demand) {
        guard case .pending = status, demand > .none else {
            return
        }

        let disposeBag = DisposeBag()

        witness.subscribe(upstream, downstream)
            .disposed(by: disposeBag)

        status = .active(disposeBag: disposeBag)
    }

    func cancel() {
        status = .completed
    }
}
