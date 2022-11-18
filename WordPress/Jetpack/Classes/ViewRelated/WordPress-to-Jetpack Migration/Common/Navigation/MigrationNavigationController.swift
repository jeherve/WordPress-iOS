import Combine
import UIKit

class MigrationNavigationController: UINavigationController {
    /// Navigation coordinator
    private let coordinator: MigrationFlowCoordinator
    /// The view controller factory used to push view controllers on the stack
    private let factory: MigrationViewControllerFactory
    /// Receives state changes to set the navigation stack accordingly
    private var cancellable: AnyCancellable?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if WPDeviceIdentification.isiPhone() {
            return .portrait
        } else {
            return .allButUpsideDown
        }
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }

    init(coordinator: MigrationFlowCoordinator, factory: MigrationViewControllerFactory) {
        self.coordinator = coordinator
        self.factory = factory
        // Possible approach we can take:
        // If the initial view controller is nil that means there's no account data and the automatic data import failed. When
        // the error screen is created, the coordinator should be set to an 'error' step and the error UI presented. In the error screen,
        // the 'Try again' button can attempt to import the data again.
        //
        // One issue that would need to be solved with this approach is we need to check if we have to run some of the startup sequence
        // again after importing the data. Currently, the automatic import is placed before the startup sequence.
        if let initialViewController = factory.initialViewController() {
            super.init(rootViewController: initialViewController)
        } else {
            super.init(nibName: nil, bundle: nil)
        }
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        let navigationBar = self.navigationBar
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        navigationBar.standardAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        navigationBar.compactAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = scrollEdgeAppearance
        }
        navigationBar.isTranslucent = true
        listenForStateChanges()
    }

    private func listenForStateChanges() {
        cancellable = coordinator.$currentStep
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                self?.updateStack(for: step)
            }
    }

    private func updateStack(for step: MigrationStep) {
        // sets the stack for the next navigation step, if there's one
        guard let viewController = factory.viewController(for: step) else {
            return
        }
        // if we want to support backwards navigation, we need to set
        // also the previous steps in the stack
        setViewControllers([viewController], animated: true)
    }
}
