//
//  TextResultViewController.swift
//  WebEditor
//
//  Created by liutingting on 16/8/19.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class TextResultViewController: UIViewController {
    
    var text: String? {
        didSet {
            textView.text = text
        }
    }
    
    private let textView = UITextView()
    
    override func viewDidLoad() {
        textView.editable = false
        textView.font = UIFont.systemFontOfSize(14)
        view.addSubview(textView)
        textView.snp_makeConstraints() {make in
            make.edges.equalTo(view)
        }
    }
}