//
//  WebEditorToolBar.swift
//  WebEditor
//
//  Created by liutingting on 16/7/12.
//  Copyright (c) 2016 liutingting. All rights reserved.
//

import Foundation
import SnapKit

public class WebEditorToolBar: UIView {
    
    public var leading: CGFloat = 15
    public var trailing: CGFloat = 15
    public var itemSpacing: CGFloat = 15
    
    public var items: [WebEditorToolItem] = [] {
        didSet {
            for value in oldValue {
                value.removeFromSuperview()
            }
            
            updateItems()
        }
    }
    
    private let containerView = UIScrollView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        containerView.bounces = false
        containerView.showsHorizontalScrollIndicator = false
        self.addSubview(containerView)
        containerView.snp.makeConstraints() {make in
            make.edges.equalTo(self)
        }
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1)
        self.addSubview(lineView)
        lineView.snp.makeConstraints() {make in
            make.height.equalTo(0.5)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateItems() {
        let width: CGFloat = items.reduce(0) {sum, new in
            return sum + new.itemSize.width + itemSpacing
        }
        containerView.contentSize.width = width - itemSpacing + leading + trailing
        
        var leadingOffset = leading
        for value in items {
            containerView.addSubview(value)
            value.snp.makeConstraints() {make in
                make.leading.equalTo(containerView).offset(leadingOffset)
                make.size.equalTo(value.itemSize)
                make.centerY.equalTo(containerView)
            }
            leadingOffset += value.itemSize.width + itemSpacing
        }
    }
}
