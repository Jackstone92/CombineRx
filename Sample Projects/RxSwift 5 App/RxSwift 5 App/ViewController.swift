//
//  ViewController.swift
//  RxSwift 5 App
//
//  Created by Jack Stone on 24/05/2022.
//

import UIKit
import Combine
import RxSwift
import RxCocoa
import CombineRx

class ViewController: UIViewController {

    private let viewModel: ViewModel
    private let disposeBag = DisposeBag()
    private var subscriptions = Set<AnyCancellable>()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var expressionAndAnswerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBindings()
        setupSubscriptions()
    }

    private func setupViews() {
        view.backgroundColor = .white

        setupExpressionAndAnswerLabel()
        setupButton()
        setupActivityIndicator()
    }

    private func setupExpressionAndAnswerLabel() {
        view.addSubview(expressionAndAnswerLabel)

        NSLayoutConstraint.activate([
            expressionAndAnswerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            expressionAndAnswerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupButton() {
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupBindings() {
        Observable.just(viewModel.title)
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .catchToEmpty()
            .sink { [unowned self] title in self.title = title }
            .store(in: &subscriptions)

        Observable.just(viewModel.buttonLabel)
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .catchToEmpty()
            .sink { [unowned self] title in self.button.setTitle(title, for: .normal) }
            .store(in: &subscriptions)

        viewModel.expressionAndAnswerObservable
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .catchToEmpty()
            .sink { [unowned self] label in self.expressionAndAnswerLabel.text = label }
            .store(in: &subscriptions)

        viewModel.isLoadingObservable
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .catchToEmpty()
            .sink { [unowned self] isLoading in
                switch isLoading {
                case true:  self.activityIndicator.startAnimating()
                case false: self.activityIndicator.stopAnimating()
                }
            }
            .store(in: &subscriptions)

        viewModel.isLoadingObservable
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .error)
            .catchToEmpty()
            .sink { [unowned self] isLoading in self.expressionAndAnswerLabel.isHidden = isLoading }
            .store(in: &subscriptions)
    }

    private func setupSubscriptions() {
        button.rx.tap
            .asDriver()
            .drive(viewModel.buttonTapSubject)
            .disposed(by: disposeBag)
    }
}

private extension Publisher {

    func catchToEmpty() -> AnyPublisher<Output, Never> {
        self
            .catch { _ in Empty().eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
}
