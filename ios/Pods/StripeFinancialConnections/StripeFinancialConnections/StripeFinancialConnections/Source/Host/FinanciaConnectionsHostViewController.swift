//
//  FinancialConnectionsHostViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import UIKit
import CoreMedia
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol FinancialConnectionsHostViewControllerDelegate: AnyObject {

    func financialConnectionsHostViewController(
        _ viewController: FinancialConnectionsHostViewController,
        didFinish result: FinancialConnectionsSheet.Result
    )
}

final class FinancialConnectionsHostViewController : UIViewController {

    // MARK: - Types

    enum State {
        case noManifest, manifestFetched, authSessionComplete
    }

    // MARK: - Properties

    weak var delegate: FinancialConnectionsHostViewControllerDelegate?

    fileprivate var authSessionManager: AuthenticationSessionManager?
    fileprivate var result: FinancialConnectionsSheet.Result = .canceled
    fileprivate var state: State = .noManifest
    fileprivate var hasNotifiedDelegate = false

    fileprivate let financialConnectionsSessionClientSecret: String
    fileprivate let apiClient: FinancialConnectionsAPIClient
    fileprivate let sessionFetcher: FinancialConnectionsSessionFetcher

    // MARK: - UI

    private lazy var closeItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: Image.close.makeImage(template: false),
                                   style: .plain,
                                   target: self,
                                   action: #selector(didTapClose))

        item.tintColor = UIColor.dynamic(light: CompatibleColor.systemGray2, dark: .white)
        return item
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = STPLocalizedString("Failed to connect", "Error message that displays when we're unable to connect to the server.")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = Styling.errorLabelFont
        return label
    }()

    private(set) lazy var tryAgainButton: StripeUICore.Button = {

        let button = StripeUICore.Button(configuration: .primary(),
                                         title: String.Localized.tryAgain)
        button.addTarget(self, action: #selector(didTapTryAgainButton), for: .touchUpInside)
        return button
    }()

    private let errorView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = Styling.errorViewSpacing
        return stackView
    }()

    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()

        if #available(iOS 13.0, *) {
            activityIndicatorView.style = .large
        }
        return activityIndicatorView
    }()

    // MARK: - Init

    init(financialConnectionsSessionClientSecret: String,
         apiClient: FinancialConnectionsAPIClient,
         sessionFetcher: FinancialConnectionsSessionFetcher) {
        self.financialConnectionsSessionClientSecret = financialConnectionsSessionClientSecret
        self.apiClient = apiClient
        self.sessionFetcher = sessionFetcher
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CompatibleColor.systemBackground
        installViews()
        installConstraints()
        getManifest()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        /**
         On iOS13+, it is possible to swipe down on presented view controller to dismiss.
         In this case, we need to notify the delegate.
         */
        if #available(iOS 13.0, *) {
            notifyDelegate()
        }
    }
}

// MARK: - Helpers

extension FinancialConnectionsHostViewController {

    fileprivate func getManifest() {
        errorView.isHidden = true
        activityIndicatorView.stp_startAnimatingAndShow()
        apiClient
            .generateSessionManifest(clientSecret: self.financialConnectionsSessionClientSecret)
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let manifest):
                    self.state = .manifestFetched
                    self.startAuthenticationSession(manifest: manifest)
                case .failure(let error):
                    self.activityIndicatorView.stp_stopAnimatingAndHide()
                    self.errorView.isHidden = false
                    self.result = .failed(error: error)
                }

        }
    }

    fileprivate func notifyDelegate() {
        if hasNotifiedDelegate { return }
        self.delegate?.financialConnectionsHostViewController(self, didFinish: self.result)
        hasNotifiedDelegate = true
    }

    fileprivate func startAuthenticationSession(manifest: FinancialConnectionsSessionManifest) {
        authSessionManager = AuthenticationSessionManager(manifest: manifest, window: view.window)
        authSessionManager?
            .start()
            .observe(using: { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                   case .success(.success):
                        self.state = .authSessionComplete
                        self.fetchSession()
                        return
                   case .success(.webCancelled):
                       self.result = .canceled
                   case .success(.nativeCancelled):
                        self.result = .canceled
                   case .failure(let error):
                        self.errorView.isHidden = false
                        self.result = .failed(error: error)
                   }
                self.activityIndicatorView.stp_stopAnimatingAndHide()
                self.notifyDelegate()
        })
    }

    fileprivate func fetchSession() {
        sessionFetcher
            .fetchSession()
            .observe { [weak self] (result) in
                guard let self = self else { return }
                self.activityIndicatorView.stp_stopAnimatingAndHide()
                switch result {
                case .success(let session):
                    self.result = .completed(session: session)
                case .failure(let error):
                    self.errorView.isHidden = false
                    self.result = .failed(error: error)
                    return
                }
                self.notifyDelegate()
            }
    }
}

// MARK: - UI Helpers

private extension FinancialConnectionsHostViewController {
    func installViews() {
        navigationItem.rightBarButtonItem = closeItem
        errorView.addArrangedSubview(errorLabel)
        errorView.addArrangedSubview(tryAgainButton)
        view.addSubview(errorView)
        view.addSubview(activityIndicatorView)
    }

    func installConstraints() {
        errorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        tryAgainButton.setContentHuggingPriority(.required, for: .vertical)
        tryAgainButton.setContentCompressionResistancePriority(.required, for: .vertical)
        errorLabel.setContentHuggingPriority(.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            // Center activity indicator
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),

            // Pin error view to top
            errorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            errorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
    }

    @objc
    func didTapTryAgainButton() {
        switch state {
        case .noManifest:
            getManifest()
        case .manifestFetched:
            // no-op
            return
        case .authSessionComplete:
            fetchSession()
        }
    }

    @objc
    func didTapClose() {
        notifyDelegate()
    }
}

// MARK: - Styling

fileprivate extension FinancialConnectionsHostViewController {
    enum Styling {
        static let errorViewSpacing: CGFloat = 16
        static var errorLabelFont: UIFont {
            UIFont.preferredFont(forTextStyle: .body, weight: .medium)
        }
    }
}
