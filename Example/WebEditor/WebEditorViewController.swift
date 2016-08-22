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
    
    private enum EditorModel {
        case Edit, New
    }
    
    private let toolBar = WebEditorToolBar()
    private let webEditor = WebEditorView()
    private let titleTextField = UITextField()
    private let segmentedControl = UISegmentedControl(items: ["新建","编辑"])
    
    private var webViewTopConstraint: Constraint!
    private var toolBarBottomConstraint: Constraint!
    private var keybaordHasShowed = false
    
    private var editorModel: EditorModel = .New {
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
        segmentedControl.addTarget(self, action: #selector(WebEditorViewController.switchModel), forControlEvents: UIControlEvents.ValueChanged)
        navigationItem.titleView = segmentedControl
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .Plain, target: self, action: #selector(WebEditorViewController.showData))
        edgesForExtendedLayout = .None
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WebEditorViewController.keyboardWillShowOrHide(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WebEditorViewController.keyboardWillShowOrHide(_:)), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        titleTextField.resignFirstResponder()
        titleTextField.resignFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        webEditor.resignFirstResponder()
        titleTextField.becomeFirstResponder()
    }
    
    func keyboardWillShowOrHide(notification: NSNotification) {
        if keybaordHasShowed {
            return
        }
        
        let info = notification.userInfo ?? [:]
        let duration = NSTimeInterval((info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.floatValue ?? 0.25)
        let curve = UInt((info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.unsignedLongValue ?? 0)
        let options = UIViewAnimationOptions(rawValue: curve)
        let keyboardRect = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() ?? CGRectZero
        
        if notification.name == UIKeyboardWillShowNotification {
            toolBarBottomConstraint.updateOffset(-keyboardRect.height)
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
        } else if notification.name == UIKeyboardDidShowNotification {
            keybaordHasShowed = true
            toolBarBottomConstraint.updateOffset(-keyboardRect.height)
        }
    }
    
    private func setUp() {
        titleTextField.font = UIFont.systemFontOfSize(16)
        titleTextField.placeholder = "标题"
        
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor.darkGrayColor()
        
        titleTextField.addSubview(seperatorView)
        seperatorView.snp_makeConstraints() {make in
            make.leading.equalTo(titleTextField)
            make.trailing.equalTo(titleTextField)
            make.bottom.equalTo(titleTextField)
            make.height.equalTo(0.5)
        }
        
        view.addSubview(titleTextField)
        titleTextField.snp_makeConstraints() {make in
            make.leading.equalTo(view).offset(15)
            make.trailing.equalTo(view)
            make.top.equalTo(view)
            make.height.equalTo(44)
        }
        
        let seperatorToolView = UIView()
        seperatorToolView.backgroundColor = UIColor.darkGrayColor()
        toolBar.addSubview(seperatorToolView)
        seperatorToolView.snp_makeConstraints() {make in
            make.leading.equalTo(toolBar)
            make.trailing.equalTo(toolBar)
            make.top.equalTo(toolBar)
            make.height.equalTo(0.5)
        }
        
        setToolBar()
        view.addSubview(toolBar)
        toolBar.snp_makeConstraints() {make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(50)
            toolBarBottomConstraint = make.bottom.equalTo(view).constraint
        }
        
        webEditor.webView.scrollView.delegate = self
        view.addSubview(webEditor)
        webEditor.snp_makeConstraints() {make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            webViewTopConstraint = make.top.equalTo(view).offset(44).constraint
            make.bottom.equalTo(toolBar.snp_top)
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
                case .Clear: strongSelf.webEditor.removeFormat()
                case .Undo: strongSelf.webEditor.undo()
                case .Redo: strongSelf.webEditor.redo()
                case .Bold: strongSelf.webEditor.bold()
                case .Italic: strongSelf.webEditor.italic()
                case .Subscript: strongSelf.webEditor.subscriptText()
                case .Superscript: strongSelf.webEditor.superscript()
                case .Strike: strongSelf.webEditor.strikethrough()
                case .Underline: strongSelf.webEditor.underline()
                case .Header(let h): strongSelf.webEditor.header(h)
                case .Indent: strongSelf.webEditor.indent()
                case .Outdent: strongSelf.webEditor.outdent()
                case .OrderedList: strongSelf.webEditor.orderedList()
                case .UnorderedList: strongSelf.webEditor.unorderedList()
                case .AlignLeft: strongSelf.webEditor.alignLeft()
                case .AlignCenter: strongSelf.webEditor.alignCenter()
                case .AlignRight: strongSelf.webEditor.alignRight()
                case .Image: strongSelf.webEditor.insertImage("https://img.shields.io/travis/reactjs/redux/master.svg?style=flat-square", classStr: "test", alt: "test")
                case .Link: strongSelf.webEditor.insertLink("http://www.apple.com/cn/", title: "insert link")
                }
            }
            
            items.append(toolItem)
        }
        toolBar.items = items
    }
    
    private func loadData() {
        webEditor.resignFirstResponder()
        titleTextField.becomeFirstResponder()
        
        switch editorModel {
        case .New:
            webEditor.loadWebViewData(nil, body: nil)
        default:
            titleTextField.text = "this is a title"
            let quote = "<blockquote><p>this is a quotation</p></blockquote>"
            let body = "<p>this is a body</p><ol><li>Coffee</li><li>Tea</li><li>Milk</li></ol><img src=https://img.shields.io/travis/reactjs/redux/master.svg?style=flat-square />"
            webEditor.loadWebViewData(quote, body: body)
        }
        webEditor.loadWithFocus = titleTextField.text?.characters.count > 0
    }
    
    func switchModel() {
        editorModel = segmentedControl.selectedSegmentIndex == 0 ? .New : .Edit
    }
    
    func showData() {
        let resultViewController = TextResultViewController()
        resultViewController.text = webEditor.getBody()
        navigationController?.pushViewController(resultViewController, animated: true)
    }
}

extension WebEditorViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 22 {
            titleTextField.hidden = true
            webViewTopConstraint.updateOffset(0)
        }else if scrollView.contentOffset.y <= 0 {
            titleTextField.hidden = false
            webViewTopConstraint.updateOffset(44)
        }
    }
}