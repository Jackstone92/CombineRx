//
//  ViewModel.swift
//  RxSwift 6 App
//
//  Created by Jack Stone on 24/05/2022.
//

import Foundation
import RxSwift
import CombineRx

final class ViewModel {
    enum State: Equatable {
        case pending
        case loading
        case loaded(fact: String)
        case error
    }

    private(set) lazy var factInfallible: Infallible<String> = {
        stateSubject
            .skip { $0 == .pending }
            .compactMap(\.fact)
            .asInfallible(onErrorJustReturn: "")
    }()

    private(set) lazy var isErrorInfallible: Infallible<Bool> = {
        stateSubject
            .skip { $0 == .pending }
            .map { $0 == .error }
            .asInfallible(onErrorJustReturn: false)
    }()

    private(set) lazy var isLoadingInfallible: Infallible<Bool> = {
        stateSubject
            .skip { $0 == .pending }
            .map { $0 == .loading }
            .asInfallible(onErrorJustReturn: false)
    }()

    var title: String { "Random Number Facts" }
    var buttonLabel: String { "Random Number Fact" }
    var errorMessage: String { "Something went wrong... Please try again" }

    let buttonTapSubject = PublishSubject<Void>()

    private let stateSubject = BehaviorSubject<State>(value: .pending)

    private let client: NumberFactClient
    private let randomNumberGenerator: () -> Int
    private let mainScheduler: SchedulerType
    private let disposeBag = DisposeBag()

    init(
        client: NumberFactClient,
        randomNumberGenerator: @escaping () -> Int,
        mainScheduler: SchedulerType
    ) {
        self.client = client
        self.randomNumberGenerator = randomNumberGenerator
        self.mainScheduler = mainScheduler

        subscribeToButtonTapObservable()
    }

    private func subscribeToButtonTapObservable() {
        buttonTapSubject
            .debounce(.milliseconds(300), scheduler: mainScheduler)
            .subscribe(onNext: { [unowned self] in self.fetchRandomFact() })
            .disposed(by: disposeBag)
    }

    private func fetchRandomFact() {
        guard let value = try? stateSubject.value(), value != .loading else { return }

        stateSubject.onNext(.loading)

        client.fact(randomNumberGenerator())
            .asObservable()
            .observe(on: mainScheduler)
            .subscribe(
                onNext: { [unowned self] fact in self.stateSubject.onNext(.loaded(fact: fact)) },
                onError: { [unowned self] _ in self.stateSubject.onNext(.error) }
            )
            .disposed(by: disposeBag)
    }
}

private extension ViewModel.State {
    var fact: String? {
        guard case let .loaded(fact) = self else { return nil }
        return fact
    }
}
