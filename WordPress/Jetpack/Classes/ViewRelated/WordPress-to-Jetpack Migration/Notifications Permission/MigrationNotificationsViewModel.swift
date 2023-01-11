import Foundation

class MigrationNotificationsViewModel {

    let configuration: MigrationStepConfiguration

    init(viewModel: MigrationFlowViewModel, tracker: MigrationAnalyticsTracker = .init()) {
        let headerConfiguration = MigrationHeaderConfiguration(step: .notifications)
        let centerViewConfigurartion = MigrationCenterViewConfiguration(step: .notifications)

        let primaryHandler = { [weak viewModel] in
            tracker.track(.notificationsScreenContinueTapped)
            InteractiveNotificationsManager.shared.requestAuthorization { [weak viewModel] authorized in
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    guard settings.authorizationStatus != .notDetermined else {
                        tracker.track(.notificationsScreenPermissionNotDetermined)
                        return
                    }

                    viewModel?.transitionToNextStep()
                    let event: MigrationEvent = authorized ? .notificationsScreenPermissionGranted : .notificationsScreenPermissionDenied
                    tracker.track(event)

                    if authorized {
                        JetpackNotificationMigrationService.shared.rescheduleLocalNotifications()
                    }
                }
            }
        }
        let secondaryHandler = { [weak viewModel] in
            tracker.track(.notificationsScreenDecideLaterButtonTapped)
            viewModel?.transitionToNextStep()
        }
        let actionsConfiguration = MigrationActionsViewConfiguration(step: .notifications,
                                                                     primaryHandler: primaryHandler,
                                                                     secondaryHandler: secondaryHandler)

        configuration = MigrationStepConfiguration(headerConfiguration: headerConfiguration,
                                                   centerViewConfiguration: centerViewConfigurartion,
                                                   actionsConfiguration: actionsConfiguration)
    }
}
