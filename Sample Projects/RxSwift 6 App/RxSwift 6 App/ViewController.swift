//
//  ViewController.swift
//  RxSwift 6 App
//
//  Created by Jack Stone on 24/05/2022.
//

import UIKit
import Combine
import RxSwift
import RxCocoa
import CombineRx

final class ViewController: UIViewController {
    private let viewModel: ViewModel
    private let disposeBag = DisposeBag()
    private var subscriptions = Set<AnyCancellable>()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var factLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .red
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.isHidden = true
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

        setupFactLabel()
        setupErrorLabel()
        setupButton()
        setupActivityIndicator()
    }

    private func setupFactLabel() {
        view.addSubview(factLabel)

        NSLayoutConstraint.activate([
            factLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            factLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            factLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            factLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupErrorLabel() {
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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
        Infallible.just(viewModel.title)
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .sink { [unowned self] title in self.title = title }
            .store(in: &subscriptions)

        Infallible.just(viewModel.buttonLabel)
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .sink { [unowned self] title in self.button.setTitle(title, for: .normal) }
            .store(in: &subscriptions)

        Infallible.just(viewModel.errorMessage)
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .sink { [unowned self] errorMessage in self.errorLabel.text = errorMessage }
            .store(in: &subscriptions)

        viewModel.factInfallible
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .sink { [unowned self] label in self.factLabel.text = label }
            .store(in: &subscriptions)

        viewModel.isLoadingInfallible
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .sink { [unowned self] isLoading in
                switch isLoading {
                case true:  self.activityIndicator.startAnimating()
                case false: self.activityIndicator.stopAnimating()
                }
            }
            .store(in: &subscriptions)

        viewModel.isLoadingInfallible
            .withLatestFrom(viewModel.isErrorInfallible, resultSelector: { $0 || $1 })
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .sink { [unowned self] isLoadingOrError in self.factLabel.isHidden = isLoadingOrError }
            .store(in: &subscriptions)

        viewModel.isErrorInfallible
            .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropNewest)
            .sink { [unowned self] isError in self.errorLabel.isHidden = !isError }
            .store(in: &subscriptions)
    }

    private func setupSubscriptions() {
        button.rx.tap
            .asDriver()
            .drive(viewModel.buttonTapSubject)
            .disposed(by: disposeBag)
    }
}
