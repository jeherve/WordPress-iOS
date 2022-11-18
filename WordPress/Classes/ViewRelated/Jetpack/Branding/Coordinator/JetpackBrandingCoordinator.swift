import UIKit

/// A class containing convenience methods for the the Jetpack branding experience
class JetpackBrandingCoordinator {

    static func presentOverlay(from viewController: UIViewController, redirectAction: (() -> Void)? = nil) {

        let action = redirectAction ?? {
            // I don't know where the entry point is so I'm assuming it's the JP bottom sheet for now
            let migrator = DataMigrator()
            migrator.exportData { result in
                switch result {
                case .success(_):
                    print("🟣 Data exported")
                    UserDefaults(suiteName: WPAppGroupName)?.set(true, forKey: "data-migration-ready")
                    
                    // Open app store/Jetpack
                case .failure(let error):
                    DDLogError("Failed to export data: \(error)")
                }
            }
        }

        let jetpackOverlayViewController = JetpackOverlayViewController(viewFactory: makeJetpackOverlayView, redirectAction: action)
        let bottomSheet = BottomSheetViewController(childViewController: jetpackOverlayViewController, customHeaderSpacing: 0)
        bottomSheet.show(from: viewController)
    }

    static func makeJetpackOverlayView(redirectAction: (() -> Void)? = nil) -> UIView {
        JetpackOverlayView(buttonAction: redirectAction)
    }

    static func shouldShowBannerForJetpackDependentFeatures() -> Bool {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase()
        switch phase {
        case .two:
            fallthrough
        case .three:
            return true
        default:
            return false
        }
    }
}
