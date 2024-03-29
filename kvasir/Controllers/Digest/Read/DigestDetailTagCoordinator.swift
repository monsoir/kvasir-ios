//
//  DigestDetailTagCoordinator.swift
//  kvasir
//
//  Created by Monsoir on 5/30/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import RealmSwift

class DigestDetailTagCoordinator: ListQueryCoordinatorable, UpdateCoordinatorable {
    typealias Model = RealmTag
    
    private let configuration: Configuration
    private(set) var results: Results<RealmTag>?
    private lazy var repository = RealmTagRepository.shared
    private var putInfo = PutInfo()
    
    private(set) var realmNotificationTokens = Set<NotificationToken>()
    
    var initialHandler: ((Results<RealmTag>?) -> Void)?
    var updateHandler: (([IndexPath], [IndexPath], [IndexPath]) -> Void)?
    var errorHandler: ((Error) -> Void)?
    
    func reclaim() {
        realmNotificationTokens.forEach{ $0.invalidate() }
    }
    
    func setupQuery(for section: Int) {
        repository.queryAllSortingByUpdatedAtDesc { [weak self] (success, results) in
            guard let self = self, success, let results = results else { return }
            
            self.results = results
            if let token = self.results?.observe({[weak self] (changes) in
                guard let self = self else { return }
                switch changes {
                case .initial:
                    self.initialHandler?(results)
                case .update(_, let deletions, let insertions, let modifications):
                    GlobalDefaultDispatchQueue.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name(rawValue: AppNotification.Name.relationBetweenDigestAndTagDidChange),
                            object: nil,
                            userInfo: nil
                        )
                    }
                    self.updateHandler?(
                        deletions.map { IndexPath(row: $0, section: section) },
                        insertions.map { IndexPath(row: $0, section: section) },
                        modifications.map { IndexPath(row: $0, section: section) }
                    )
                case .error(let e):
                    self.errorHandler?(e)
                }
            }) {
                self.realmNotificationTokens.insert(token)
            }
        }
    }
    
    func put(info: PutInfoScript) throws {
        putInfo = info as PutInfo
    }
    
    func update(completion: @escaping RealmUpdateCompletion) {
        guard let tagId = putInfo["tagId"] as? String, let digestIds = putInfo["entityIds"] as? [String] else {
            completion(false)
            return
        }
        
        repository.updateTagToDigestRelation(tagId: tagId, digestIds: digestIds, completion: { success in
            GlobalDefaultDispatchQueue.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: AppNotification.Name.relationBetweenDigestAndTagWillChange),
                    object: nil,
                    userInfo: [
                        "changeSuccess": success,
                        "tagId": tagId,
                        "digestIdSet": Set<String>(digestIds),
                    ]
                )
            }
            completion(success)
        })
    }
    
    required init(configuration: Configurable.Configuration) {
        self.configuration = configuration
    }
    
    deinit {
        #if DEBUG
        print("\(self) deinit")
        #endif
    }
    
}
