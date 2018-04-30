import SVProgressHUD

class SignupEpilogueViewController: NUXViewController {

    // MARK: - Properties
    var credentials: WordPressCredentials?
    var socialService: SocialService?

    private var buttonViewController: NUXButtonViewController?
    private var updatedDisplayName: String?
    private var updatedPassword: String?
    private var updatedUsername: String?
    private var epilogueUserInfo: LoginEpilogueUserInfo?
    private var displayNameAutoGenerated: Bool = false
    private var changesMade = false

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WordPressAuthenticator.track(.signupEpilogueViewed, properties: tracksProperties())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
            buttonViewController?.delegate = self
            buttonViewController?.setButtonTitles(primary: NSLocalizedString("Continue", comment: "Button text on site creation epilogue page to proceed to My Sites."))
        }

        if let vc = segue.destination as? SignupEpilogueTableViewController {
            vc.credentials = credentials
            vc.socialService = socialService
            vc.dataSource = self
            vc.delegate = self
        }

        if let vc = segue.destination as? SignupUsernameViewController {
            vc.currentUsername = updatedUsername ?? epilogueUserInfo?.username
            vc.displayName = updatedDisplayName ?? epilogueUserInfo?.fullName
            vc.delegate = self
        }
    }

    // MARK: - analytics

    private func tracksProperties() -> [AnyHashable: Any] {
        let source = socialService != nil ? "google" : "email"
        return ["source": source]
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension SignupEpilogueViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        saveChanges()
    }
}

// MARK: - SignupEpilogueTableViewControllerDataSource

extension SignupEpilogueViewController: SignupEpilogueTableViewControllerDataSource {
    var customDisplayName: String? {
        return updatedDisplayName
    }

    var password: String? {
        return updatedPassword
    }

    var username: String? {
        return updatedUsername
    }
}

// MARK: - SignupEpilogueTableViewControllerDelegate

extension SignupEpilogueViewController: SignupEpilogueTableViewControllerDelegate {

    func displayNameUpdated(newDisplayName: String) {
        updatedDisplayName = newDisplayName
        displayNameAutoGenerated = false
    }

    func displayNameAutoGenerated(newDisplayName: String) {
        updatedDisplayName = newDisplayName
        displayNameAutoGenerated = true
    }

    func passwordUpdated(newPassword: String) {
        if !newPassword.isEmpty {
            updatedPassword = newPassword
        }
    }

    func usernameTapped(userInfo: LoginEpilogueUserInfo?) {
        epilogueUserInfo = userInfo
        performSegue(withIdentifier: .showUsernames, sender: self)
        WordPressAuthenticator.track(.signupEpilogueUsernameTapped, properties: self.tracksProperties())
    }
}

// MARK: - Private Extension

private extension SignupEpilogueViewController {
    func saveChanges() {
        if let newUsername = updatedUsername {
            SVProgressHUD.show(withStatus: NSLocalizedString("Changing username", comment: "Shown while the app waits for the username changing web service to return."))
            changeUsername(to: newUsername) {
                self.updatedUsername = nil
                self.saveChanges()
            }
        } else if let newDisplayName = updatedDisplayName {
            // If the display name is not auto generated, then the user changed it.
            // So we need to show the HUD to the user.
            if !displayNameAutoGenerated {
                SVProgressHUD.show(withStatus: NSLocalizedString("Changing display name", comment: "Shown while the app waits for the display name changing web service to return."))
            }
            changeDisplayName(to: newDisplayName) {
                self.updatedDisplayName = nil
                self.saveChanges()
            }
        } else if let newPassword = updatedPassword {
            SVProgressHUD.show(withStatus: NSLocalizedString("Changing password", comment: "Shown while the app waits for the password changing web service to return."))
            changePassword(to: newPassword) {
                self.updatedPassword = nil
                self.saveChanges()
            }
        } else {
            if !changesMade {
                defer {
                    WordPressAuthenticator.track(.signupEpilogueUnchanged, properties: tracksProperties())
                }
            }
            self.refreshAccountDetails() {
                SVProgressHUD.dismiss()
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        changesMade = true
    }

    func changeUsername(to newUsername: String, finished: @escaping (() -> Void)) {
        guard newUsername != "" else {
            finished()
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.defaultWordPressComAccount(),
            let api = account.wordPressComRestApi else {
                navigationController?.popViewController(animated: true)
                return
        }

        let settingsService = AccountSettingsService(userID: account.userID.intValue, api: api)
        settingsService.changeUsername(to: newUsername, success: {
            WordPressAuthenticator.track(.signupEpilogueUsernameUpdateSucceeded, properties: self.tracksProperties())
            finished()
        }) {
            WordPressAuthenticator.track(.signupEpilogueUsernameUpdateFailed, properties: self.tracksProperties())
            finished()
        }
    }

    func changeDisplayName(to newDisplayName: String, finished: @escaping (() -> Void)) {

        let context = ContextManager.sharedInstance().mainContext

        guard let defaultAccount = AccountService(managedObjectContext: context).defaultWordPressComAccount(),
        let restApi = defaultAccount.wordPressComRestApi else {
            finished()
            return
        }

        let accountSettingService = AccountSettingsService(userID: defaultAccount.userID.intValue, api: restApi)
        let accountSettingsChange = AccountSettingsChange.displayName(newDisplayName)

        accountSettingService.saveChange(accountSettingsChange) { success in
            if success {
                WordPressAuthenticator.track(.signupEpilogueDisplayNameUpdateSucceeded, properties: self.tracksProperties())
            } else {
                WordPressAuthenticator.track(.signupEpilogueDisplayNameUpdateFailed, properties: self.tracksProperties())
            }
            finished()
        }
    }

    func changePassword(to newPassword: String, finished: @escaping () -> Void) {

        let context = ContextManager.sharedInstance().mainContext

        guard let defaultAccount = AccountService(managedObjectContext: context).defaultWordPressComAccount(),
            let restApi = defaultAccount.wordPressComRestApi else {
                finished()
                return
        }

        let accountSettingService = AccountSettingsService(userID: defaultAccount.userID.intValue, api: restApi)

        accountSettingService.updatePassword(newPassword) { success in
            if success {
                WordPressAuthenticator.track(.signupEpiloguePasswordUpdateSucceeded, properties: self.tracksProperties())
            } else {
                WordPressAuthenticator.track(.signupEpiloguePasswordUpdateFailed, properties: self.tracksProperties())
            }
            finished()
        }
    }

    func refreshAccountDetails(finished: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            self.navigationController?.dismiss(animated: true, completion: nil)
            return
        }
        service.updateUserDetails(for: account, success: { () in
            finished()
        }, failure: { _ in
            finished()
        })
    }

}

extension SignupEpilogueViewController: SignupUsernameViewControllerDelegate {
    func usernameSelected(_ username: String) {
        if username.isEmpty || username == epilogueUserInfo?.username {
            updatedUsername = nil
        } else {
            updatedUsername = username
        }
    }
}
