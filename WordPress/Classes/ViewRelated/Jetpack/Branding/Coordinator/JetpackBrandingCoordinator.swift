import UIKit

/// A class containing convenience methods for the the Jetpack branding experience
class JetpackBrandingCoordinator {

    static func presentOverlay(from viewController: UIViewController, redirectAction: (() -> Void)? = nil) {

        let action = redirectAction ?? {
            handleJetpackAppDeepLink()
        }

        let jetpackOverlayViewController = JetpackOverlayViewController(viewFactory: makeJetpackOverlayView, redirectAction: action)
        let bottomSheet = BottomSheetViewController(childViewController: jetpackOverlayViewController, customHeaderSpacing: 0)
        bottomSheet.show(from: viewController)
    }

    static func makeJetpackOverlayView(redirectAction: (() -> Void)? = nil) -> UIView {
        JetpackOverlayView(buttonAction: redirectAction)
    }

    private static var jetpackAppUrl: URL? {
        URL(string: Constants.openJetpackAppUrlString)
    }

    private static var jetpackAppStoreUrl: URL? {
        URL(string: Constants.appStoreUrlString)
    }

    static func handleJetpackAppDeepLink() {
        guard let url = JetpackBrandingCoordinator.jetpackAppUrl else {
            return
        }
        UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { success in
            guard !success, let appUrl = JetpackBrandingCoordinator.jetpackAppStoreUrl else {
                return
            }
            UIApplication.shared.open(appUrl)
        }
    }

    private enum Constants {
        static let appStoreUrlString = "https://apps.apple.com/app/jetpack-wp-security-speed/id1565481562"
        static let openJetpackAppUrlString = "https://apps.wordpress.com/get"
    }
}
