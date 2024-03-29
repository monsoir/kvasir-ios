//
//  RealmCommonInfo.swift
//  kvasir
//
//  Created by Monsoir on 4/21/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import RealmSwift

class RealmBasicObject: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var serverId  = ""
    @objc dynamic var createdAt = Date()
    @objc dynamic var updatedAt = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
