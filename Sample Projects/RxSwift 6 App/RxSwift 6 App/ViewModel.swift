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
        case loaded(Expression)
        case error
    }

    var expressionAndAnswerObservable: Infallible<String> {
        stateSubject
            .skip { $0 == .pending }
            .map { state in
                guard let expression = state.expression else { return "" }
                return [expression.expression, "=", String(expression.answer)].joined(separator: " ")
            }
            .asInfallible(onErrorJustReturn: "")
    }

    var isErrorObservable: Infallible<Bool> {
        stateSubject
            .skip { $0 == .pending }
            .map { $0 == .error }
            .asInfallible(onErrorJustReturn: false)
    }

    var isLoadingObservable: Infallible<Bool> {
        stateSubject
            .skip { $0 == .pending }
            .map { $0 == .loading }
            .asInfallible(onErrorJustReturn: false)
    }

    var title: String { "Maths Expressions" }
    var buttonLabel: String { "Random Expression" }
    var errorMessage: String { "Something went wrong... Please try again" }

    let buttonTapSubject = PublishSubject<Void>()

    private let stateSubject = BehaviorSubject<State>(value: .pending)

    private let client: MathsExpressionClient
    private let mainScheduler: SchedulerType
    private let disposeBag = DisposeBag()

    init(
        client: MathsExpressionClient,
        mainScheduler: SchedulerType
    ) {
        self.client = client
        self.mainScheduler = mainScheduler

        subscribeToButtonTapObservable()
    }

    private func subscribeToButtonTapObservable() {
        buttonTapSubject
            .debounce(.milliseconds(300), scheduler: mainScheduler)
            .subscribe(onNext: { [unowned self] in self.fetchRandomExpression() })
            .disposed(by: disposeBag)
    }

    private func fetchRandomExpression() {
        guard let value = try? stateSubject.value(), value != .loading else { return }

        stateSubject.onNext(.loading)

        client.randomExpression()
            .asObservable()
            .observe(on: mainScheduler)
            .subscribe(
                onNext: { [unowned self] expression in self.stateSubject.onNext(.loaded(expression)) },
                onError: { [unowned self] _ in self.stateSubject.onNext(.error) }
            )
            .disposed(by: disposeBag)
    }
}

private extension ViewModel.State {

    var expression: Expression? {
        switch self {
        case .loaded(let expression):
            return expression

        case .pending, .loading, .error:
            return nil
        }
    }
}
