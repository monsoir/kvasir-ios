//
//  TagDetailViewController.swift
//  kvasir
//
//  Created by Monsoir on 5/27/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import PKHUD

private let SectionInfos: [(title: String, url: String)] = [
    (title: "句摘", url: KvasirURL.allSentences.url()),
    (title: "段摘", url: KvasirURL.allParagraphs.url()),
//    (title: "书籍", url: KvasirURL.allBooks.url()),
]

private let SectionMaxRows = 3

class TagDetailViewController: UnifiedViewController {
    
    private var coordinator: TagDetailCoordinator!
    private var needsUpdateHeader = true
    
    private lazy var tableView: UITableView = { [unowned self] in
        let view = UITableView(frame: CGRect.zero, style: .grouped)
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 200
        view.register(TopListTableViewHeaderActionable.self, forHeaderFooterViewReuseIdentifier: TopListTableViewHeaderActionable.reuseIdentifier())
        view.register(PlainTextViewFooter.self, forHeaderFooterViewReuseIdentifier: PlainTextViewFooter.reuseIdentifier())
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.separatorStyle = .none
        return view
    }()
    private lazy var tableHeader: TagDetailHeader = { [unowned self] in
        let view = TagDetailHeader()
        view.delegate = self
        return view
    }()
    
    init(with configuration: [String : Any]) {
        self.coordinator = TagDetailCoordinator(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        debugPrint("\(self) deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSubviews()
        configureCoordinator()
        coordinator.query { [weak self] (success, _) in
            guard let self = self, success else { return }
            self.reloadView()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if needsUpdateHeader {
            reloadHeader()
        }
    }
    
    private func setupSubviews() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func configureCoordinator() {
        coordinator.reloadHandler = { [weak self] _ in
            guard let self = self else { return }
            MainQueue.async {
                self.reloadView()
            }
        }
        coordinator.errorHandler = { [weak self] msg in
            guard let self = self else { return }
            MainQueue.async {
                self.navigationController?.popViewController()
                Bartendar.handleSorryAlert(message: msg, on: nil)
            }
        }
        coordinator.deleteHandler = { [weak self] in
            guard let self = self else { return }
            MainQueue.async {
                self.navigationController?.popViewController(animated: true)
                HUD.flash(.label("该标签已被删除"), onView: nil, delay: 1.0, completion: nil)
            }
        }
    }
    
    private func reloadHeader() {
        tableHeader.color = Color(hexString: coordinator.tagResult?.color ?? "")
        tableHeader.title = coordinator.tagResult?.name ?? ""
        tableHeader.frame = CGRect(x: 0, y: 0, width: tableView.width, height: TagDetailHeader.height)
        tableView.tableHeaderView = tableHeader
        needsUpdateHeader = false
    }
    
    private func reloadView() {
        reloadHeader()
        tableView.reloadData()
        title = "\(RealmTag.toHuman)-\(coordinator.tagResult?.name ?? "")"
    }
    
    private func setNeedsUpdateHeader() {
        needsUpdateHeader = true
    }
    
    private func updateHeaderIfNeeded() {
        if needsUpdateHeader {
            reloadHeader()
        }
    }
}

// MARK: - UITableViewDataSource
extension TagDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionInfos.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        switch section {
        case 0:
            count = coordinator.sentences?.count ?? 0
        case 1:
            count = coordinator.paragraphs?.count ?? 0
        default:
            count = 0
        }
        return count > SectionMaxRows ? SectionMaxRows : count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0, 1:
            return TextListTableViewCell.height
        case 2:
            return BookListTableViewCell.height
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func cellForDigestAtIndexPath(_ indexPath: IndexPath, digest: RealmWordDigest?) -> UITableViewCell {
            guard let digest = digest else { return UITableViewCell() }
            
            var cell: TextListTableViewCell?
            if let hasImage = digest.book?.hasImage, hasImage {
                cell = tableView.dequeueReusableCell(withIdentifier: TextListTableViewCell.reuseIdentifier(extra: TextListTableViewCell.cellWithThumbnailIdentifierAddon)) as? TextListTableViewCell
                if cell == nil {
                    cell = TextListTableViewCell(
                        style: .default,
                        reuseIdentifier: TextListTableViewCell.reuseIdentifier(extra: TextListTableViewCell.cellWithThumbnailIdentifierAddon),
                        needThumbnail: true
                    )
                }
                cell?.thumbnail = digest.book?.thumbnailImage ?? ""
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: TextListTableViewCell.reuseIdentifier(extra: TextListTableViewCell.cellWithoutThumbnailIdentifierAddon)) as? TextListTableViewCell
                if cell == nil {
                    cell = TextListTableViewCell(
                        style: .default,
                        reuseIdentifier: TextListTableViewCell.cellWithoutThumbnailIdentifierAddon
                    )
                }
            }
            cell?.title = digest.title
            cell?.bookName = digest.book?.name
            cell?.recordUpdatedDate = digest.updateAtReadable
            cell?.tagColors = digest.tags.map { $0.color }
            return cell!
        }

        switch indexPath.section {
        case 0:
            guard let digest = coordinator.sentences?[indexPath.row] else { return UITableViewCell() }
            return cellForDigestAtIndexPath(indexPath, digest: digest)
        case 1:
            guard let digest = coordinator.paragraphs?[indexPath.row] else { return UITableViewCell() }
            return cellForDigestAtIndexPath(indexPath, digest: digest)
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate
extension TagDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TopListTableViewHeaderActionable.height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: TopListTableViewHeaderActionable.reuseIdentifier()) as? TopListTableViewHeaderActionable else { return nil }
        
        func headerAccessoryTitleForSection(_ section: Int) -> (tip: String, title: String) {
            switch section {
            case 0:
                return ("查看全部 \(coordinator.sentences?.count ?? 0)", RealmWordDigest.Category.sentence.toHuman)
            case 1:
                return ("查看全部 \(coordinator.paragraphs?.count ?? 0)", RealmWordDigest.Category.paragraph.toHuman)
            default:
                return ("", "")
            }
        }
        
        let tagId = coordinator.tagResult?.id;
        let tagName = coordinator.tagResult?.name
        let displayTitles = headerAccessoryTitleForSection(section)
        header.title = SectionInfos[section].title
        header.actionTitle = displayTitles.tip
        header.contentView.backgroundColor = Color(hexString: ThemeConst.mainBackgroundColor)
        header.seeAllHandler = {
            // MARK: 查看全部跳转
            MainQueue.async {
                KvasirNavigator.push(SectionInfos[section].url, context: ["canAdd": false, "tagId": tagId ?? "", "title": "\(tagName ?? "") 的\(displayTitles.title)"])
            }
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return coordinator.hasSentences ? 0 : PlainTextViewFooter.height
        case 1:
            return coordinator.hasParagraphs ? 0 : PlainTextViewFooter.height
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return coordinator.hasSentences ? nil : {
                let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlainTextViewFooter.reuseIdentifier()) as? PlainTextViewFooter
                footer?.title = "没有找到该\(RealmTag.toHuman)下的\(RealmWordDigest.Category.sentence.toHuman)"
                return footer
            }()
        case 1:
            return coordinator.hasParagraphs ? nil : {
                let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlainTextViewFooter.reuseIdentifier()) as? PlainTextViewFooter
                footer?.title = "没有找到该\(RealmTag.toHuman)下的\(RealmWordDigest.Category.paragraph.toHuman)"
                return footer
            }()
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            guard let digest = coordinator.sentences?[indexPath.row] else { break }
            let id = digest.id
            KvasirNavigator.push(KvasirURL.detailSentence.url(with: ["id": id]))
        case 1:
            guard let digest = coordinator.paragraphs?[indexPath.row] else { break }
            let id = digest.id
            KvasirNavigator.push(KvasirURL.detailParagraph.url(with: ["id": id]))
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private extension TagDetailViewController {
    func showEditTagName() {
        let validateErrorHandler: FieldEditValidatorHandler = { messages in
            Bartendar.handleTipAlert(message: messages.first ?? "", on: nil)
            return
        }
        let completion: FieldEditCompletion = { [weak self] (newValue, vc) in
            guard let self = self else { return }
            let putInfo = [
                "name": newValue as? String ?? "",
            ]
            do {
                try self.coordinator.put(info: putInfo)
            } catch let e as ValidateError {
                Bartendar.handleTipAlert(message: e.message, on: nil)
                return
            } catch {
                Bartendar.handleSorryAlert(on: nil)
                return
            }
            
            self.coordinator.update(completion: { (success) in
                guard success else {
                    Bartendar.handleSorryAlert(message: "更新失败", on: nil)
                    return
                }
                MainQueue.async {
                    vc?.dismiss(animated: true, completion: nil)
                }
            })
        }
        let info: [String: Any?] = [
            FieldEditInfoPreDefineKeys.title: "标签名称",
            FieldEditInfoPreDefineKeys.oldValue: self.coordinator.tagResult?.name,
            FieldEditInfoPreDefineKeys.completion: completion,
            FieldEditInfoPreDefineKeys.validateErrorHandler: validateErrorHandler,
            FieldEditInfoPreDefineKeys.startEditingAsShown: true,
        ]
        MainQueue.async {
            let vc = FieldEditFactory.createAFieldEditController(of: .shortText, editInfo: info)
            let nc = UINavigationController(rootViewController: vc)
            self.present(nc, animated: true, completion: nil)
        }
    }
}

extension TagDetailViewController: TagDetailHeaderDelegate {
    func tagDetailHeaderDidTouch(_: TagDetailHeader) {
        showEditTagName()
    }
}
