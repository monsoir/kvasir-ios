//
//  RouteControllerFactory.swift
//  kvasir
//
//  Created by Monsoir on 5/19/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import URLNavigator

private typealias RouteParams = (createDigest: (() -> RealmWordDigest), holder: String)
private let RouteParamsDict: [String: RouteParams] = [
    DigestType.sentence.toMachine: ({ return RealmSentence() }, ""),
    DigestType.paragraph.toMachine: ({ return RealmParagraph() }, ""),
]

func newDigestControllerFactory(url: URLConvertible, values: [String: Any], context: Any?) -> UIViewController? {
    guard let identifier = get(url: url, componentAt: 2) else { return nil }
    guard let param = RouteParamsDict[identifier] else { return nil }
    
    switch identifier {
    case RealmSentence.toMachine():
        return CreateDigestContainerViewController(digest: param.createDigest() as! RealmSentence)
    case RealmParagraph.toMachine():
        return CreateDigestContainerViewController(digest: param.createDigest() as! RealmParagraph)
    default:
        return nil
    }
}

func allDigestControllerFactory(url: URLConvertible, values: [String: Any], context: Any?) -> UIViewController? {
    guard let identifier = get(url: url, componentAt: 2) else { return nil }
    
    switch identifier {
    case RealmSentence.toMachine():
        return DigestListViewController<RealmSentence>(with: [:])
    case RealmParagraph.toMachine():
        return DigestListViewController<RealmParagraph>(with: [:])
    default:
        return nil
    }
}

func detailDigestControllerFactory(url: URLConvertible, values: [String: Any], context: Any?) -> UIViewController? {
    guard let identifier = get(url: url, componentAt: 1) else { return nil }
    guard let id = values["id"] as? String else { return nil }
    
    switch identifier {
    case RealmSentence.toMachine():
        return DigestDetailViewController<RealmSentence>(digestId: id)
    case RealmParagraph.toMachine():
        return DigestDetailViewController<RealmParagraph>(digestId: id)
    default:
        return nil
    }
}

func allResourceControllerFactory(url: URLConvertible, values: [String: Any], context: Any?) -> UIViewController? {
    guard let identifier = get(url: url, componentAt: 2) else { return nil }
    
    switch identifier {
    case RouteConstants.Nouns.book:
        return BookListViewController(with: ["editable": true, "title": "收集的书籍"])
    case RouteConstants.Nouns.author:
        return AuthorListViewController(with: ["editable": true, "title": "已知\(RealmAuthor.toHuman())", "creatorType": "author"])
    case RouteConstants.Nouns.translator:
        return TranslatorListViewController(with: ["editable": true, "title": "已知\(RealmTranslator.toHuman())", "creatorType": "translator"])
    default:
        return nil
    }
}

func booksOfCreatorControllerFactory(url: URLConvertible, values: [String: Any], context: Any?) -> UIViewController? {
    guard let id = values["id"] else { return nil }
    let creatorType = get(url: url, componentAt: 1) ?? "author"
    
    switch creatorType {
    case "author":
        return BookListViewController(with: ["editable": true, "title": "TA 的书籍", "creatorType": "author", "creatorId": id])
    case "translator":
        return BookListViewController(with: ["editable": true, "title": "TA 的书籍", "creatorType": "translator", "creatorId": id])
    default:
        return nil
    }
}

func selectResourceControllerFactory(url: URLConvertible, values: [String: Any], context: Any?) -> UIViewController? {
    guard let identifier = get(url: url, componentAt: 2) else { return nil }
    
    switch identifier {
    case RouteConstants.Nouns.book:
        return BookListViewController(with: ["editable": false, "title": "选择一本书籍"])
    case RouteConstants.Nouns.author:
        return AuthorListViewController(with: ["editable": false, "title": "选择一个\(RealmAuthor.toHuman())"])
    case RouteConstants.Nouns.translator:
        return TranslatorListViewController(with: ["editable": false, "title": "选择一个\(RealmTranslator.toHuman())"])
    default:
        return nil
    }
}

func digestOfBookControllerFactory(url: URLConvertible, values: [String: Any], context: Any?) -> UIViewController? {
    guard let id = values["id"], let digestType = get(url: url, componentAt: 4) else { return nil }
    switch digestType {
    case RealmSentence.toMachine():
        return DigestListViewController<RealmSentence>(with: ["bookId": id])
    case RealmParagraph.toMachine():
        return DigestListViewController<RealmParagraph>(with: ["bookId": id])
    default:
        return nil
    }
}

// MARK: Helpers

private func get(url: URLConvertible, componentAt index: Int) -> String? {
    guard let url = url.urlValue else { return nil }
    let components = url.pathComponents
    return components.item(at: index)
}