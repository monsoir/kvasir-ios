//
//  RealmBook.swift
//  kvasir
//
//  Created by Monsoir on 4/25/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import RealmSwift

class RealmBook: RealmBasicObject {
    @objc dynamic var isbn13 = ""
    @objc dynamic var isbn10 = ""
    @objc dynamic var name = ""
    @objc dynamic var localeName = ""
    @objc dynamic var summary = ""
    @objc dynamic var publisher = ""
    @objc dynamic var imageLarge = ""
    @objc dynamic var imageMedium = ""
    
    let sentences = List<RealmSentence>()
    let paragraphs = List<RealmParagraph>()
    
    let authors = LinkingObjects(fromType: RealmAuthor.self, property: "books")
    let translators = LinkingObjects(fromType: RealmTranslator.self, property: "books")
    let tags = LinkingObjects(fromType: RealmTag.self, property: "books")
    
    override static func indexedProperties() -> [String] {
        return ["isbn13", "isbn10", "name", "localeName"]
    }
}
