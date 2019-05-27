//
//  RealmAuthor.swift
//  kvasir
//
//  Created by Monsoir on 4/25/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import RealmSwift

class RealmCreator: RealmBasicObject {
    @objc dynamic var name = ""
    @objc dynamic var localeName = ""
    
    override static func indexedProperties() -> [String] {
        return ["name", "localName"]
    }
    
    class func toHuman() -> String {
        return "创意者"
    }
    
    class func toMachine() -> String {
        return "creator"
    }
    
    class func createAnUnmanagedOneFromPayload<T: RealmCreator>(_ payload: [String: Any]) -> T {
        let creator = T()
        creator.name = payload["name"] as? String ?? ""
        creator.localeName = payload["localeName"] as? String ?? ""
        return creator
    }
    
    override func preCreate() {
        super.preCreate()
        name.trim()
        localeName.trim()
    }
    
    override func preUpdate() {
        super.preUpdate()
        name.trim()
        localeName.trim()
    }
}
