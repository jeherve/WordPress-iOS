import UIKit

@objc
class ReaderCoordinator: NSObject {
    let readerNavigationController: UINavigationController

    var failureBlock: (() -> Void)? = nil

    @objc
    init(readerNavigationController: UINavigationController) {
        self.readerNavigationController = readerNavigationController
        super.init()
    }

    func showReaderTab() {
        RootViewCoordinator.sharedPresenter.showReaderTab()
    }

    func showDiscover() {
        RootViewCoordinator.sharedPresenter.switchToDiscover()
    }

    func showSearch() {
        RootViewCoordinator.sharedPresenter.navigateToReaderSearch()
    }

    func showA8C() {
        RootViewCoordinator.sharedPresenter.switchToTopic(where: { topic in
            return (topic as? ReaderTeamTopic)?.slug == ReaderTeamTopic.a8cSlug
        })
    }

    func showP2() {
        RootViewCoordinator.sharedPresenter.switchToTopic(where: { topic in
            return (topic as? ReaderTeamTopic)?.slug == ReaderTeamTopic.p2Slug
        })
    }

    func showMyLikes() {
        RootViewCoordinator.sharedPresenter.switchToMyLikes()
    }

    func showManageFollowing() {
        RootViewCoordinator.sharedPresenter.switchToFollowedSites()
    }

    func showList(named listName: String, forUser user: String) {
        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)

        guard let topic = service.topicForList(named: listName, forUser: user) else {
            failureBlock?()
            return
        }

        RootViewCoordinator.sharedPresenter.switchToTopic(where: { $0 == topic })
    }

    func showTag(named tagName: String) {
        let remote = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress()))
        let slug = remote.slug(forTopicName: tagName) ?? tagName.lowercased()

        getTagTopic(tagSlug: slug) { result in
            guard let topic = try? result.get() else { return }
            RootViewCoordinator.sharedPresenter.navigateToReaderTag(topic)
        }
    }

    private func getTagTopic(tagSlug: String, completion: @escaping (Result<ReaderTagTopic, Error>) -> Void) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.tagTopicForTag(withSlug: tagSlug,
            success: { objectID in

                guard let objectID = objectID,
                    let topic = try? ContextManager.sharedInstance().mainContext.existingObject(with: objectID) as? ReaderTagTopic else {
                    DDLogError("Reader: Error retriving tag topic - invalid tag slug")
                    return
                }
                completion(.success(topic))
            },
            failure: { error in
                let defaultError = NSError(domain: "readerTagTopicError", code: -1, userInfo: nil)
                DDLogError("Reader: Error retriving tag topic - " + (error?.localizedDescription ?? "unknown failure reason"))
                completion(.failure(error ?? defaultError))
            })
    }

    func showStream(with siteID: Int, isFeed: Bool) {
        getSiteTopic(siteID: NSNumber(value: siteID), isFeed: isFeed) { result in
            guard let topic = try? result.get() else {
                return
            }

            RootViewCoordinator.sharedPresenter.navigateToReaderSite(topic)
        }
    }

    private func getSiteTopic(siteID: NSNumber, isFeed: Bool, completion: @escaping (Result<ReaderSiteTopic, Error>) -> Void) {
        let service = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.siteTopicForSite(withID: siteID,
        isFeed: isFeed,
        success: { objectID, isFollowing in

            guard let objectID = objectID,
                let topic = try? ContextManager.sharedInstance().mainContext.existingObject(with: objectID) as? ReaderSiteTopic else {
                DDLogError("Reader: Error retriving site topic - invalid Site Id")
                return
            }
            completion(.success(topic))
        },
        failure: { error in
            let defaultError = NSError(domain: "readerSiteTopicError", code: -1, userInfo: nil)
            DDLogError("Reader: Error retriving site topic - " + (error?.localizedDescription ?? "unknown failure reason"))
            completion(.failure(error ?? defaultError))
        })
    }

    func showPost(with postID: Int, for feedID: Int, isFeed: Bool) {
        showPost(in: ReaderDetailViewController
                    .controllerWithPostID(postID as NSNumber,
                                          siteID: feedID as NSNumber,
                                          isFeed: isFeed))
    }

    func showPost(with url: URL) {
        showPost(in: ReaderDetailViewController.controllerWithPostURL(url))
    }

    private func showPost(in detailViewController: ReaderDetailViewController) {

        let postLoadFailureBlock = { [weak self, failureBlock] in
            self?.readerNavigationController.popToRootViewController(animated: false)
            failureBlock?()
        }

        detailViewController.postLoadFailureBlock = postLoadFailureBlock
        RootViewCoordinator.sharedPresenter.navigateToReader(detailViewController)
    }

}

extension ReaderTopicService {
    /// Returns an existing topic for the specified list, or creates one if one
    /// doesn't already exist.
    ///
    func topicForList(named listName: String, forUser user: String) -> ReaderListTopic? {
        let remote = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress()))
        let sanitizedListName = remote.slug(forTopicName: listName) ?? listName.lowercased()
        let sanitizedUser = user.lowercased()
        let path = remote.path(forEndpoint: "read/list/\(sanitizedUser)/\(sanitizedListName)/posts", withVersion: ._1_2)

        if let existingTopic = findContainingPath(path) as? ReaderListTopic {
            return existingTopic
        }

        let topic = ReaderListTopic(context: managedObjectContext)
        topic.title = listName
        topic.slug = sanitizedListName
        topic.owner = user
        topic.path = path

        return topic
    }
}
