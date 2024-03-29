//
//  BookListTableViewCell.swift
//  kvasir
//
//  Created by Monsoir on 4/25/19.
//  Copyright © 2019 monsoir. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import Kingfisher

private let LeadingMargin = 10
private let TrailingMargin = 10
private let TopMargin = 10
private let BottomMargin = 10

class BookListTableViewCell: ShadowedTableViewCell {
    static let BookThumbnailSize = CGSize(width: 66, height: 98)
    static let BookThumbnailZoomFactor = 1.5 as CGFloat
    static let height = UITableView.automaticDimension
    static let cellWithThumbnailIdentifierAddon = "with-thumnbnail"
    static let cellWithoutThumbnailIdentifierAddon = "without-thumnbnail"
    
    private var needThumbnail: Bool
    
    var payload: [String: Any]? {
        didSet {
            let thumbnail = payload?["thumbnail"] as? String ?? ""
            let title = payload?["title"] as? String ?? ""
            let author = payload?["author"] as? String ?? ""
            let publisher = payload?["publisher"] as? String ?? ""
            let sentencesCount = payload?["sentencesCount"] as? Int ?? 0
            let paragraphsCount = payload?["paragraphsCount"] as? Int ?? 0
            
            let detail = [author.isEmpty ? "[作者]" : author, publisher.isEmpty ? "[出版社]" : publisher].joined(separator: " / ")
            let digest = ["\(sentencesCount)个句摘", "\(paragraphsCount)个段摘"].joined(separator: "/")
            
            ivThumbnail.kf.setImage(with: URL(string: thumbnail), placeholder: nil, options: kingfisherOptions)
            lbTitle.attributedText = NSAttributedString(string: title, attributes: titleAttributes)
            lbDetail.attributedText = NSAttributedString(string: detail, attributes: detailAttributes)
            lbDigest.attributedText = NSAttributedString(string: digest, attributes: detailAttributes)
        }
    }
    
    private lazy var ivThumbnail: UIImageView = {
        let imageView = UIImageView()
        // image view 不要使用此方法添加圆角
        // 会遮蔽图片显示
        // 被这行代码搞了2个小时了
//        imageView.roundCorners([.allCorners], radius: 10 as CGFloat)
        imageView.contentMode = .center
        return imageView
    }()
    private lazy var lbTitle: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }()
    private lazy var lbDetail: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }()
    private lazy var lbDigest: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var titleAttributes: StringAttributes = [
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22, weight: .medium),
    ]
    private lazy var detailAttributes: StringAttributes = [
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
        NSAttributedString.Key.foregroundColor: UIColor.lightGray,
    ]
    private lazy var kingfisherOptions: KingfisherOptionsInfo = [
        // 对于普通的 Redirect, Kingfisher 可能内置了处理
        // 不过这里就显式声明一下吧
        .redirectHandler(MsrKingfisher()),
        
        // 使用 Kingfiser 的圆角处理
        .processor(RoundCornerImageProcessor(cornerRadius: 10 as CGFloat, targetSize: CGSize(width: BookListTableViewCell.BookThumbnailSize.width * BookListTableViewCell.BookThumbnailZoomFactor, height: BookListTableViewCell.BookThumbnailSize.height * BookListTableViewCell.BookThumbnailZoomFactor), roundingCorners: .all, backgroundColor: nil))
    ]
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, needThumbnail: Bool = false) {
        self.needThumbnail = needThumbnail
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        payload = nil
    }
    
    override func updateConstraints() {
        if needThumbnail {
            ivThumbnail.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().offset(LeadingMargin)
                make.top.equalToSuperview().offset(TopMargin)
                make.size.equalTo(CGSize(width: BookListTableViewCell.BookThumbnailSize.width * BookListTableViewCell.BookThumbnailZoomFactor, height: BookListTableViewCell.BookThumbnailSize.height * BookListTableViewCell.BookThumbnailZoomFactor))
                make.bottom.lessThanOrEqualToSuperview().offset(-BottomMargin)
            }
        }
        
        lbTitle.snp.makeConstraints { (make) in
            make.leading.equalTo(needThumbnail ? ivThumbnail.snp.trailing : realContentView).offset(LeadingMargin)
            make.trailing.equalToSuperview().offset(-TrailingMargin)
            make.top.equalToSuperview().offset(TopMargin)
            make.height.greaterThanOrEqualTo(30)
        }
        
        lbDetail.snp.makeConstraints { (make) in
            make.leading.equalTo(needThumbnail ? ivThumbnail.snp.trailing : realContentView).offset(LeadingMargin)
            make.trailing.equalToSuperview().offset(-TrailingMargin)
            make.top.equalTo(lbTitle.snp.bottom).offset(TopMargin)
            make.height.greaterThanOrEqualTo(30)
        }
        
        lbDigest.snp.makeConstraints { (make) in
            make.leading.equalTo(needThumbnail ? ivThumbnail.snp.trailing : realContentView).offset(LeadingMargin)
            make.trailing.equalToSuperview().offset(-TrailingMargin)
            make.top.equalTo(lbDetail.snp.bottom).offset(TopMargin)
            make.height.greaterThanOrEqualTo(30)
            make.bottom.lessThanOrEqualToSuperview().offset(-BottomMargin)
        }
        
        super.updateConstraints()
    }
    
    override class var realContentCornerRadius: CGFloat {
        return 10
    }
    
    private func setupSubviews() {
        if needThumbnail {
            realContentView.addSubview(ivThumbnail)
        }
        contentViewBackgroundColor = Color(hexString: ThemeConst.mainBackgroundColor)
        realContentView.addSubviews([
            lbTitle,
            lbDetail,
            lbDigest,
        ])
        selectionStyle = .none
    }
}
