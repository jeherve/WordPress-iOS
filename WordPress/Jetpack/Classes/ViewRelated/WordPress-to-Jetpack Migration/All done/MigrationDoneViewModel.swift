class MigrationDoneViewModel {

    let configuration: MigrationStepConfiguration

    init(viewModel: MigrationFlowViewModel, tracker: MigrationAnalyticsTracker = .init()) {

        let headerConfiguration = MigrationHeaderConfiguration(step: .done)

        let centerViewConfigurartion = MigrationCenterViewConfiguration(step: .done)

        let actionsConfiguration = MigrationActionsViewConfiguration(step: .done, primaryHandler: { [weak viewModel] in
            tracker.track(.thanksScreenFinishTapped)
            viewModel?.transitionToNextStep()
        })
        configuration = MigrationStepConfiguration(headerConfiguration: headerConfiguration,
                                                   centerViewConfiguration: centerViewConfigurartion,
                                                   actionsConfiguration: actionsConfiguration)
    }
}
