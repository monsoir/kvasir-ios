//
//  ColletionTypeEmptyBackgroundView.swift
//  kvasir
//
//  Created by Monsoir on 4/23/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

enum CollectionTypeEmptyBackgroundViewPosition {
    case upper
    case middle
    case lower
}

class CollectionTypeEmptyBackgroundView: UIView {
    private var title = ""
    private var position = CollectionTypeEmptyBackgroundViewPosition.middle
    private lazy var lbTitle: ExpandedLabel = {
        let label = ExpandedLabel(halfHorizontal: 10, halfVertical: 10)
        label.numberOfLines = 2
        label.font = PingFangSCLightFont?.withSize(22)
        label.textAlignment = .center
        label.backgroundColor = Color(hexString: ThemeConst.secondaryBackgroundColor)
        label.cornerRadius = 10
        return label
    }()
    private var customFactor: CGFloat?
    
    init(title: String = "A Placeholder", position: CollectionTypeEmptyBackgroundViewPosition = .middle, customFactor: CGFloat? = nil) {
        super.init(frame: .zero)
        self.title = title
        self.position = position
        self.customFactor = customFactor
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        lbTitle.text = title
        addSubview(lbTitle)
    }
    
    override func updateConstraints() {
        lbTitle.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            switch position {
            case .upper:
                make.centerY.equalToSuperview().multipliedBy(customFactor ?? 0.3)
            case .middle:
                make.centerY.equalToSuperview().multipliedBy(customFactor ?? 1)
            case .lower:
                make.centerY.equalToSuperview().multipliedBy(customFactor ?? 1.5)
            }
        }
        super.updateConstraints()
    }
}
