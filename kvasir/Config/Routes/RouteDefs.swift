//
//  RouteDefs.swift
//  kvasir
//
//  Created by Monsoir on 5/19/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import UIKit
import URLNavigator

protocol KvasirViewControllerRoutable {
    var template: String { get }
    func url(with args: [String: Any]) -> String
    var controllerFactory: ((_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> UIViewController?) { get }
}

enum KvasirURL: KvasirViewControllerRoutable, CaseIterable {
    // No need for args
    case newSentence
    case newParagraph
    case newAuthor
    case newTranslator
    case newBookManully
    case newBookScanly
    case allSentences
    case allParagraphs
    case allBooks
    case allAuthors
    case allTranslators
    case allTags
    case selectBooks
    case selectAuthors
    case selectTranslators
    case asServer
    
    // Need for args
    case detailSentence
    case detailParagraph
    case detailBook
    case detailTag
    case booksOfAnAuthor
    case booksOfATranslator
    case sentencesOfBook
    case paragraphsOfBook
    
    /// 路由模版
    var template: String {
        var schema: SchemaBuilder
        switch self {
        case .newSentence:
            // kvasir://digest/new/sentence
            schema = SchemaBuilder().component(RouteConstants.Nouns.digest).component(RouteConstants.Actions.new).component(RouteConstants.Nouns.sentence)
        case .newParagraph:
            schema = SchemaBuilder().component(RouteConstants.Nouns.digest).component(RouteConstants.Actions.new
                ).component(RouteConstants.Nouns.paragraph)
        case .newAuthor:
            // kvasir://resource/new/author
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.new).component(RouteConstants.Nouns.author)
        case .newTranslator:
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.new).component(RouteConstants.Nouns.translator)
        case .newBookManully:
            // kvasir://resource/new/book/manully
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.new).component(RealmBook.toMachine).component(RouteConstants.Preps.manully)
        case .newBookScanly:
            // kvasir://resource/new/book/scanly
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.new).component(RealmBook.toMachine).component(RouteConstants.Preps.scanly)
        case .allSentences:
            // kvasir://digest/all/sentence
            schema = SchemaBuilder().component(RouteConstants.Nouns.digest).component(RouteConstants.Actions.all).component(RouteConstants.Nouns.sentence)
        case .allParagraphs:
            schema = SchemaBuilder().component(RouteConstants.Nouns.digest).component(RouteConstants.Actions.all).component(RouteConstants.Nouns.paragraph)
        case .detailSentence:
            // kvasir://digest/sentence/an-id
            schema = SchemaBuilder().component(RouteConstants.Nouns.digest).component(RouteConstants.Nouns.sentence).component("<string:id>")
        case .detailParagraph:
            // kvasir://digest/paragraph/an-id
            schema = SchemaBuilder().component(RouteConstants.Nouns.digest).component(RouteConstants.Nouns.paragraph).component("<string:id>")
        case .detailBook:
            // kvasir://resource/book/an-id
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RealmBook.toMachine).component("<string:id>")
        case .detailTag:
            // kvasir://resource/tag/an-id
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RealmTag.toMachine).component("<string:id>")
        case .allBooks:
            // kvasir://resource/all/book
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.all).component(RouteConstants.Nouns.book)
        case .allAuthors:
            // kvasir://resource/all/author
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.all).component(RouteConstants.Nouns.author)
        case .booksOfAnAuthor:
            // kvasir://resource/author/author-id/books
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Nouns.author).component("<string:id>").component(RouteConstants.Nouns.books)
        case .allTranslators:
            // kvasir://resource/all/translator
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.all).component(RouteConstants.Nouns.translator)
        case .allTags:
            // kvasir://resource/all/tag
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.all).component(RouteConstants.Nouns.tag)
        case .booksOfATranslator:
            // kvasir://resource/translator/translator-id/books
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Nouns.translator).component("<string:id>").component(RouteConstants.Nouns.books)
        case .selectBooks:
            // kvasir://resource/select/book
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.select).component(RouteConstants.Nouns.book)
        case .selectAuthors:
            // kvasir://resource/select/author
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.select).component(RouteConstants.Nouns.author)
        case .selectTranslators:
            // kvasir://resource/select/translator
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Actions.select).component(RouteConstants.Nouns.translator)
        case .sentencesOfBook:
            // kvasir://resource/book/<book-id>/digest/sentence/all
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Nouns.book).component("<string:id>").component(RouteConstants.Nouns.digest).component(RouteConstants.Nouns.sentence).component(RouteConstants.Actions.all)
        case .paragraphsOfBook:
            // kvasir://resource/book/<book-id>/digest/paragraph/all
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Nouns.books).component("<string:id>").component(RouteConstants.Nouns.digest).component(RouteConstants.Nouns.paragraph).component(RouteConstants.Actions.all)
        case .asServer:
            schema = SchemaBuilder().component(RouteConstants.Nouns.server)
        }
        return schema.extract()
    }
    
    /// 构建具体路由
    ///
    /// - Parameter args: 路由需要的参数
    /// - Returns: 拼接参数后，可进行跳转的路由
    func url(with args: [String: Any]  = [:]) -> String {
        var schema: SchemaBuilder
        switch self {
        case .detailSentence:
            schema = SchemaBuilder().component(RouteConstants.Nouns.digest).component(RouteConstants.Nouns.sentence).component(args.getValueOrFatalError(key: "id"))
        case .detailParagraph:
            schema = SchemaBuilder().component(RouteConstants.Nouns.digest).component(RouteConstants.Nouns.paragraph).component(args.getValueOrFatalError(key: "id"))
        case .detailBook:
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RealmBook.toMachine).component(args.getValueOrFatalError(key: "id"))
        case .detailTag:
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RealmTag.toMachine).component(args.getValueOrFatalError(key: "id"))
        case .booksOfAnAuthor:
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Nouns.author).component(args.getValueOrFatalError(key: "id")).component(RouteConstants.Nouns.books)
        case .booksOfATranslator:
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Nouns.translator).component(args.getValueOrFatalError(key: "id")).component(RouteConstants.Nouns.books)
        case .sentencesOfBook:
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Nouns.book).component(args.getValueOrFatalError(key: "id")).component(RouteConstants.Nouns.digest).component(RouteConstants.Nouns.sentence).component(RouteConstants.Actions.all)
        case .paragraphsOfBook:
            schema = SchemaBuilder().component(RouteConstants.Nouns.resource).component(RouteConstants.Nouns.books).component(args.getValueOrFatalError(key: "id")).component(RouteConstants.Nouns.digest).component(RouteConstants.Nouns.paragraph).component(RouteConstants.Actions.all)
        default:
            return template
        }
        return schema.extract()
    }
    
    var controllerFactory: ((URLConvertible, [String : Any], Any?) -> UIViewController?) {
        switch self {
        case .newSentence, .newParagraph:
            return newDigestControllerFactory(url:values:context:)
        case .newAuthor, .newTranslator:
            return newCreatorControllerFactory(url:values:context:)
        case .newBookManully, .newBookScanly:
            return newBookControllerFactory(url:values:context:)
        case .allSentences, .allParagraphs:
            return allDigestControllerFactory(url:values:context:)
        case .detailSentence, .detailParagraph:
            return detailDigestControllerFactory(url:values:context:)
        case .allBooks, .allAuthors, .allTranslators, .allTags:
            return allResourceControllerFactory(url:values:context:)
        case .booksOfAnAuthor, .booksOfATranslator:
            return booksOfCreatorControllerFactory(url:values:context:)
        case .selectBooks, .selectAuthors, .selectTranslators:
            return selectResourceControllerFactory(url:values:context:)
        case .sentencesOfBook, .paragraphsOfBook:
            return digestOfBookControllerFactory(url:values:context:)
        case .detailTag, .detailBook:
            return resourceDetailFactory(url:values:context:)
        case .asServer:
            return serverControllerFactory(url:values:context:)
        }
    }
}

private extension Dictionary where Key == String, Value == Any {
    func getValueOrFatalError(key: String) -> String {
        guard let arg = self[key] else {
            fatalError("unknown key pass to route")
        }
        return "\(arg)"
    }
}
