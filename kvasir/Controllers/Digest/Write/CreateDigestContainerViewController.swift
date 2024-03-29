//
//  CreateDigestContentViewController.swift
//  kvasir
//
//  Created by Monsoir on 4/27/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import UIKit
import SnapKit
import FontAwesome_swift
import RealmSwift

private let DefaultTab = 0

class CreateDigestContainerViewController: UnifiedViewController, Configurable {
    
    private let configuration: Configuration
    private var digest: RealmWordDigest {
        get {
            return coordinator.entity
        }
    }
    private lazy var coordinator = CreateDigestCoordinator(configuration: self.configuration)
    private var createCompletion: ((_: UIViewController) -> Void)? {
        return configuration["completion"] as? (_: UIViewController) -> Void ?? { vc in
            vc.dismiss(animated: true, completion: nil)
        }
    }
    
    private lazy var constraintDict = [String: Constraint]()
    private lazy var basicInfoVC = CreateDigestInfoViewController(digest: self.digest, creating: true)
    private lazy var contentVC = DigestEditViewController(digest: self.digest)
    private lazy var vcs = [self.basicInfoVC, self.contentVC]
    private var currentVC: UIViewController? {
        get {
            return self.children.first
        }
    }

    private lazy var segement: UISegmentedControl = { [unowned self] in
        let view = UISegmentedControl(items: ["基本信息", "\(self.digest.category.toHuman)内容"])
        view.addTarget(self, action: #selector(actionChangeSegement(sender:)), for: .valueChanged)
        view.selectedSegmentIndex = DefaultTab
        return view
    }()
    
    required init(configuration: Configuration) {
        self.configuration = configuration
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
        setupNavigationBar()
        setupSubviews()
    }
    
    @objc func actionChangeSegement(sender: UISegmentedControl) {
        switchTabTo(sender.selectedSegmentIndex)
    }
    
    @objc func actionSubmit() {
        let formValues = basicInfoVC.getFormValues()
        let contentValues = contentVC.getValues()
        
        do {
            try coordinator.post(info: formValues.merging(contentValues, uniquingKeysWith: { (_, new) -> Any in
                return new
            }))
        } catch let e as ValidateError {
            Bartendar.handleTipAlert(message: e.message, on: self.navigationController)
            return
        } catch {
            Bartendar.handleSorryAlert(on: self.navigationController)
            return
        }
        
        coordinator.create { [weak self] (success, message) in
            guard let self = self else { return }
            MainQueue.async {
                guard success else {
                    Bartendar.handleTipAlert(message: "创建失败", on: self.navigationController)
                    return
                }
                self.createCompletion?(self)
            }
        }
    }
}

private extension CreateDigestContainerViewController {
    func setupNavigationBar() {
        setupImmersiveAppearance()
        navigationItem.titleView = segement
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: { [weak self] in
            let btn = simpleButtonWithButtonFromAwesomefont(name: .check, fontSize: 22)
            btn.addTarget(self, action: #selector(actionSubmit), for: .touchUpInside)
            return btn
        }())
    }
    
    func setupSubviews() {
        let childVC = vcs[DefaultTab]
        addChildViewController(childVC, toContainerView: view)
        var constraint: Constraint!
        childVC.view.snp.makeConstraints({ (make) in
            constraint = make.edges.equalToSuperview().constraint
        })
        constraintDict[childVC.toMachine()] = constraint
    }
    
    func switchTabTo(_ index: Int) {
        if let beforeVC = currentVC {
            beforeVC.removeViewAndControllerFromParentViewController()
            constraintDict[beforeVC.toMachine()]?.deactivate()
        }
        
        let toVC = vcs[index]
        addChildViewController(toVC, toContainerView: view)
        if let constraint = constraintDict[toVC.toMachine()] {
            constraint.activate()
        } else {
            var constraint: Constraint!
            toVC.view.snp.makeConstraints { (make) in
                constraint = make.edges.equalToSuperview().constraint
            }
            constraintDict[toVC.toMachine()] = constraint
        }
    }
}

private extension UIViewController {
    func toMachine() -> String {
        return "\(self.self)"
    }
}
