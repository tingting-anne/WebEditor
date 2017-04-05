//
//  WebEditorViewController.swift
//  WebEditor
//
//  Created by liutingting on 16/7/7.
//  Copyright (c) 2016 liutingting. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import WebEditor

class WebEditorViewController: UIViewController {
    
    private enum EditorModel: Int {
        case new = 0, edit = 1, reply = 2
    }
    
    private let toolBar = WebEditorToolBar()
    private let webEditor = WebEditorView()
    private let segmentedControl = UISegmentedControl(items: ["新建","编辑", "回复"])
    private var toolBarBottomConstraint: Constraint!
    
    private var editorModel: EditorModel = .new {
        didSet {
            loadData()
        }
    }
    
    override func viewDidLoad() {
        setUp()
        loadData()
        
        segmentedControl.frame = CGRect(x: 0, y: 0, width: 140, height: 27)
        segmentedControl.selectedSegmentIndex = 0
        switchModel()
        segmentedControl.addTarget(self, action: #selector(WebEditorViewController.switchModel), for: UIControlEvents.valueChanged)
        navigationItem.titleView = segmentedControl
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .plain, target: self, action: #selector(WebEditorViewController.showData))
        edgesForExtendedLayout = []
        
        NotificationCenter.default.addObserver(self, selector: #selector(WebEditorViewController.keyboardWillShowOrHide(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WebEditorViewController.keyboardWillShowOrHide(notification:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WebEditorViewController.keyboardWillShowOrHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShowOrHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let rectValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else {
            return
        }
        
        let keyboardRect = view.convert(rectValue.cgRectValue, from: nil)
        let duration = TimeInterval(animationDuration.floatValue)
        let animationCurve = UIViewAnimationCurve(rawValue: curve) ?? UIViewAnimationCurve.easeInOut
        
        
        var animationOptions: UIViewAnimationOptions
        switch animationCurve {
        case .easeInOut:
            animationOptions = UIViewAnimationOptions()
        case .easeIn:
            animationOptions = UIViewAnimationOptions.curveEaseIn
        case .easeOut:
            animationOptions = UIViewAnimationOptions.curveEaseOut
        case .linear:
            animationOptions = UIViewAnimationOptions.curveLinear
        }
        
        switch notification.name {
        case NSNotification.Name.UIKeyboardWillShow:
            toolBarBottomConstraint.update(offset: -keyboardRect.height)
            UIView.animate(withDuration: duration, delay: 0, options: animationOptions, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
          
        case NSNotification.Name.UIKeyboardDidShow:
            toolBarBottomConstraint.update(offset: -keyboardRect.height)
            
        case NSNotification.Name.UIKeyboardWillHide:
            toolBarBottomConstraint.update(offset: 0)
            UIView.animate(withDuration: duration, delay: 0, options: animationOptions, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            
        default:
            break
        }
    }
    
    private func setUp() {
        setToolBar()
        view.addSubview(toolBar)
        toolBar.snp.makeConstraints() {make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(50)
            toolBarBottomConstraint = make.bottom.equalTo(view).constraint
        }
    
        view.addSubview(webEditor)
        webEditor.snp.makeConstraints() {make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.top.equalTo(view)
            make.bottom.equalTo(toolBar.snp.top)
        }
    }
    
    private func setToolBar() {
        var items = [WebEditorToolItem]()
        let allItemsToAdd = WebEditorToolOptions.all()
        for item in allItemsToAdd {
            let toolItem = WebEditorToolItem(image: item.image)
            toolItem.itemAction = {[weak self] in
                guard let strongSelf = self else {
                    return
                }
                switch item {
                case .clear: strongSelf.webEditor.removeFormat()
                case .undo: strongSelf.webEditor.undo()
                case .redo: strongSelf.webEditor.redo()
                case .bold: strongSelf.webEditor.bold()
                case .italic: strongSelf.webEditor.italic()
                case .subscript: strongSelf.webEditor.subscriptText()
                case .superscript: strongSelf.webEditor.superscript()
                case .strike: strongSelf.webEditor.strikethrough()
                case .underline: strongSelf.webEditor.underline()
                case .header(let h): strongSelf.webEditor.header(h: h)
                case .indent: strongSelf.webEditor.indent()
                case .outdent: strongSelf.webEditor.outdent()
                case .orderedList: strongSelf.webEditor.orderedList()
                case .unorderedList: strongSelf.webEditor.unorderedList()
                case .alignLeft: strongSelf.webEditor.alignLeft()
                case .alignCenter: strongSelf.webEditor.alignCenter()
                case .alignRight: strongSelf.webEditor.alignRight()
                case .image: strongSelf.webEditor.insertImage(url: "https://img.shields.io/travis/reactjs/redux/master.svg?style=flat-square", classStr: "test", alt: "test")
                case .link: strongSelf.webEditor.insertLink(href: "http://www.apple.com/cn/", title: "insert link")
                }
            }
            
            items.append(toolItem)
        }
        toolBar.items = items
    }
    
    private func loadData() {
        switch editorModel {
        case .new:
            webEditor.loadWebViewData(showTitle: true, title: nil, body: nil)
        case .edit:
            let title = "this is a title"
            let body = "<blockquote><p>this is a quotation</p></blockquote><p>this is a body</p><ol><li>Coffee</li><li>Tea</li><li>Milk</li></ol><img src=https://img.shields.io/travis/reactjs/redux/master.svg?style=flat-square />"
            webEditor.loadWebViewData(showTitle: true, title: title, body: body)
        case .reply:
            webEditor.loadWebViewData(showTitle: false, title: nil, body: nil)
        }
        
        webEditor.becomeFirstResponder()
        if editorModel == .new || editorModel == .edit {
            webEditor.focusTitle()
        }else {
            webEditor.focusContent()
        }
    }
    
    func switchModel() {
        editorModel = EditorModel(rawValue: segmentedControl.selectedSegmentIndex) ?? .new
    }
    
    func showData() {
        let resultViewController = TextResultViewController()
        resultViewController.text = webEditor.getContent()
        navigationController?.pushViewController(resultViewController, animated: true)
    }
}
