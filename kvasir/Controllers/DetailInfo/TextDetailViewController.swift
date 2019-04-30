//
//  TextDetailViewController.swift
//  kvasir-ios
//
//  Created by Monsoir on 2019/3/20.
//  Copyright © 2019 monsoir. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

private let SectionTitles = [
    "书名",
    "作者",
    "译者",
    "出版社",
    "摘录页码",
    "上次修改时间",
]

private let ContainerHeight = 50
private let CellIdentifierEditable = "editable"
private let CellIdentifierUneditable = "uneditable"

class TextDetailViewController<Digest: RealmWordDigest>: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var coordinator: TextDetailCoordinator<Digest>!
    private var entity: Digest? {
        get {
            return coordinator.entity
        }
    }
    
    private var modifying = false {
        didSet {
            btnEdit.setTitle(modifying ? "完成修改" : "修改", for: .normal)
            btnContentEdit.isHidden = !modifying
            reloadData()
        }
    }
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Color(hexString: ThemeConst.secondaryBackgroundColor)
        return view
    }()
    
    private lazy var headerContentView: UIView = {
        let view = UIView()
        view.backgroundColor = Color(hexString: ThemeConst.mainBackgroundColor)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private lazy var lbContent: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var btnContentEdit: UIButton = {
        let btn = simpleButtonWithButtonFromAwesomefont(name: .paintBrush)
        btn.addTarget(self, action: #selector(actionEditContent), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()
    
    private lazy var infoTableView: UITableView = { [unowned self] in
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = Color(hexString: ThemeConst.secondaryBackgroundColor)
        view.register(DetailInfoTableViewCell.self, forCellReuseIdentifier: DetailInfoTableViewCell.reuseIdentifier(extra: CellIdentifierUneditable))
        view.register(DetailInfoTableViewCell.self, forCellReuseIdentifier: DetailInfoTableViewCell.reuseIdentifier(extra: CellIdentifierEditable))
        view.tableFooterView = UIView()
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        return view
    }()
    
    private lazy var buttonsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Color(hexString: ThemeConst.mainBackgroundColor)
        return view
    }()
    
    private lazy var btnEdit: UIButton = makeAFunctionalButtonWith(title: "修改")
    private lazy var btnDel: UIButton = { [unowned self] in
        let btn = makeAFunctionalButtonWith(title: "删除")
        btn.setTitleColor(.red, for: .normal)
        btn.addTarget(self, action: #selector(actionDel), for: .touchUpInside)
        return btn
    }()
    
    private lazy var contentAttributes: StringAttributes = [
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 28)!
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupNavigationBar()
        setupSubviews()
        configureCoordinator()
        coordinator.queryOne { [weak self] (success, entity) in
            guard success else {
                Bartendar.handleSimpleAlert(title: "提示", message: "没有找到数据", on: self?.navigationController)
                return
            }
            self?.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let headerHeight = lbContent.attributedText?.height(containerWidth: infoTableView.bounds.width) ?? 0
        headerView.height = headerHeight + 100
        
        infoTableView.tableHeaderView = headerView
    }
    
    init(digestId: String) {
        self.coordinator = TextDetailCoordinator(digestId: digestId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        #if DEBUG
        print("\(self) deinit")
        #endif
        
        coordinator.reclaim()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func configureCell(_ identifier: String, indexPath: IndexPath, label: String, value: String, modifying: Bool?) -> DetailInfoTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! DetailInfoTableViewCell
            cell.label = label
            cell.value = value
            if let m = modifying {
                cell.modifying = m
            }
            cell.selectionStyle = .none
            return cell
        }
        
        guard let entity = entity else { return UITableViewCell() }
        switch indexPath.row {
        case 0:
            let cell = configureCell(DetailInfoTableViewCell.reuseIdentifier(extra: CellIdentifierEditable), indexPath: indexPath, label: SectionTitles[indexPath.row], value: entity.book?.name ?? "", modifying: modifying)
            cell.modifyHandler = { [weak self] cell in
                guard let strongSelf = self else { return }
                strongSelf.showBookList(cell)
            }
            return cell
        case 1:
            return configureCell(DetailInfoTableViewCell.reuseIdentifier(extra: CellIdentifierUneditable), indexPath: indexPath, label: SectionTitles[indexPath.row], value: entity.book?.createAuthorsReadable("\n") ?? "", modifying: nil)
        case 2:
            return configureCell(DetailInfoTableViewCell.reuseIdentifier(extra: CellIdentifierUneditable), indexPath: indexPath, label: SectionTitles[indexPath.row], value: entity.book?.createTranslatorReadabel("\n") ?? "", modifying: nil)
        case 3:
            return configureCell(DetailInfoTableViewCell.reuseIdentifier(extra: CellIdentifierUneditable), indexPath: indexPath, label: SectionTitles[indexPath.row], value: entity.book?.publisher ?? "", modifying: nil)
        case 4:
            let cell = configureCell(DetailInfoTableViewCell.reuseIdentifier(extra: CellIdentifierEditable), indexPath: indexPath, label: SectionTitles[indexPath.row], value: "\(entity.pageIndex)", modifying: modifying)
            cell.modifyHandler = { [weak self] cell in
                guard let strongSelf = self else { return }
                strongSelf.showPageIndexEdit(cell)
            }
            return cell
        case 5:
            return configureCell(DetailInfoTableViewCell.reuseIdentifier(extra: CellIdentifierUneditable), indexPath: indexPath, label: SectionTitles[indexPath.row], value: entity.updateAtReadable, modifying: nil)
        default:
            break
        }
        
        return UITableViewCell()
    }
    
    @objc func actionEdit() {
        modifying.toggle()
    }
    
    @objc func actionDel() {
        deleteDigest()
    }
    
    @objc private func actionEditContent() {
        showContentEdit()
    }
}

private extension TextDetailViewController {
    func setupNavigationBar() {
        title = "\(Digest.toHuman()) - 正文"
        setupImmersiveAppearance()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func setupSubviews() {
        view.backgroundColor = Color(hexString: ThemeConst.secondaryBackgroundColor)
        
        headerView.addSubview(headerContentView)
        headerContentView.addSubview(lbContent)
        headerContentView.addSubview(btnContentEdit)
        headerContentView.snp.makeConstraints { (make) in
            make.top.leading.equalToSuperview().offset(10)
            make.bottom.trailing.equalToSuperview().offset(-10)
            make.center.equalToSuperview()
        }
        lbContent.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.center.equalToSuperview()
        }
        btnContentEdit.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 22, height: 22))
            make.bottom.equalToSuperview().offset(-10)
        }
        
        view.addSubview(infoTableView)
        view.addSubview(buttonsContainer)
        
        buttonsContainer.addSubview(btnEdit)
        buttonsContainer.addSubview(btnDel)
        btnEdit.addTarget(self, action: #selector(actionEdit), for: .touchUpInside)
        
        buttonsContainer.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ContainerHeight)
            make.trailing.equalTo(buttonsContainer.snp.trailing)
        }
        
        btnEdit.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-20)
        }
        
        btnDel.snp.makeConstraints { (make) in
            make.right.equalTo(btnEdit.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }
        
        infoTableView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(buttonsContainer.snp.top)
        }
    }
    
    func configureCoordinator() {
        coordinator.reload = { [weak self] data in
            guard let strongSelf = self else { return }
            strongSelf.reloadData()
        }
        coordinator.errorHandler = { [weak self] msg in
            guard let strongSelf = self else { return }
            MainQueue.async {
                strongSelf.navigationController?.popToRootViewController(animated: true)
                Bartendar.handleSorryAlert(message: msg, on: nil)
            }
        }
        coordinator.entityDeleteHandler = { [weak self] in
            guard let strongSelf = self else { return }
            MainQueue.async {
                strongSelf.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}

private extension TextDetailViewController {
    func deleteDigest() {
        let alert = UIAlertController.init(title: "确定删除此条摘录吗？", message: nil, preferredStyle: .alert)
        alert.addAction(title: "确定", style: .destructive, isEnabled: true) { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.coordinator?.delete(completion: { (success) in
                DispatchQueue.main.async {
                    if !success {
                        Bartendar.handleSorryAlert(message: "删除失败", on: self?.navigationController)
                        return
                    }
                }
            })
        }
        alert.addAction(title: "取消", style: .cancel, isEnabled: true, handler: nil)
        navigationController?.present(alert, animated: true, completion: nil)
    }
    
    func showContentEdit() {
        guard let editingData = entity else { return }
        let vc = DigestEditViewController(text: editingData.content, singleLine: Digest.self === RealmSentence.self) { [weak self] (text) in
            do {
                let putInfo = ["content": text]
                try self?.coordinator.put(info: putInfo)
            } catch let e as ValidateError {
                Bartendar.handleTipAlert(message: e.message, on: self?.navigationController)
                return
            } catch {
                Bartendar.handleSorryAlert(on: self?.navigationController)
                return
            }
            
            self?.coordinator.update(completion: { (success) in
                guard success else {
                    Bartendar.handleSorryAlert(message: "更新失败", on: self?.navigationController)
                    return
                }
                
                MainQueue.async {
                    self?.navigationController?.popViewController()
                    self?.reloadData()
                }
            })
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showBookList(_ sender: DetailInfoTableViewCell) {
        let vc = BookListViewController { [weak self] (book) in
            guard let strongSelf = self else { return }
            strongSelf.coordinator?.updateBookRef(book: book, completion: { (success) in
                DispatchQueue.main.async {
                    guard success else {
                        Bartendar.handleSorryAlert(message: "修改失败", on: self?.navigationController)
                        return
                    }
                    
                    self?.navigationController?.popViewController()
                }
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showPageIndexEdit(_ sender: DetailInfoTableViewCell) {
    }
}

private extension TextDetailViewController {
    func reloadData() {
        MainQueue.async {
            self.lbContent.attributedText = NSAttributedString(string: self.entity?.content ?? "", attributes: self.contentAttributes)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.infoTableView.reloadData()
        }
    }
}
