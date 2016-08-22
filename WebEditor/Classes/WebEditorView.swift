//
//  WebEditorView.swift
//  WebEditor
//
//  Created by liutingting on 16/1/5.
//  Copyright (c) 2016 liutingting. All rights reserved.
//

import Foundation
import SnapKit

public class WebEditorView: UIView {
    /// placeholder
    public var placeholderBody = "正文"
    
    /// 初始打开时编辑器是否 focus
    public var loadWithFocus = true

    /// 编辑器 focus 状态变化回调，focus 表示当前是否处于 focus 状态
    public var focusStateCallback: ((focus: Bool) -> Void)?
    public private(set) var webView: UIWebView
    
    private var lastScrollPos: CGFloat? //上次需要移动的位置
    
    override init(frame: CGRect) {
        webView = UIWebView()
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        webView = UIWebView()
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        webView.frame = self.bounds
        webView.delegate = self
        webView.keyboardDisplayRequiresUserAction = false
        webView.scalesPageToFit = true
        webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        webView.dataDetectorTypes = .None
        webView.scrollView.bounces = false
        webView.scrollView.clipsToBounds = true
        
        //解决webView最后显示一条黑色线的问题
        webView.opaque = false
        webView.backgroundColor = UIColor.clearColor()
        
        //去掉默认扩展
        webView.setHackinputAccessoryView(nil)
        
        self.addSubview(webView)
        webView.snp_makeConstraints(){make in
            make.edges.equalTo(self)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(WebEditorView.viewWasTapped(_:)))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
    }

    /**
        加载编辑器
     
        - parameter quote: 引用数据
        - parameter body: 正文数据
    */
    public func loadWebViewData(quote: String?, body: String?) {
        guard let path = NSBundle(forClass: WebEditorView.self).pathForResource("rich_editor", ofType: "html") else {
            return
        }
        let templateURL = NSURL(fileURLWithPath: path)
        let htmlTemp = try! String(contentsOfURL: templateURL, encoding: NSUTF8StringEncoding)
        let data = String(format: htmlTemp, quote ?? "", body ?? "")
        webView.loadHTMLString(data, baseURL: templateURL)
    }
}

// MARK: - UIWebViewDelegate

extension WebEditorView: UIWebViewDelegate {
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let callbackPrefix = "re-callback://"
        if request.URL?.absoluteString.hasPrefix(callbackPrefix) == true {
            let commands = runJS("RE.getCommandQueue();")
            if let data = (commands as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
                
                let jsonCommands: [String]?
                do {
                    jsonCommands = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String]
                } catch {
                    jsonCommands = nil
                    NSLog("Failed to parse JSON Commands")
                }
                
                if let jsonCommands = jsonCommands {
                    for command in jsonCommands {
                        performCommand(command)
                    }
                }
            }
            
            return false
        }

        if navigationType == .LinkClicked {
            return false
        }
        return true
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        setPlaceholderText()
        if loadWithFocus {
            focus()
        }
    }
    
    private func performCommand(method: String) {
        if method.hasPrefix("scrollTo=") {
            let rangeOfPos = method.startIndex.advancedBy(("scrollTo=" as NSString).length)..<method.endIndex
            let pos = CGFloat(Int(method[rangeOfPos])!)
            if pos > (webView.scrollView.contentOffset.y + self.frame.height - 15) {
                let newPos = pos - self.frame.height + 15 + 22
                if lastScrollPos == nil || lastScrollPos != newPos { //防止输入跳动
                    lastScrollPos = newPos
                    webView.scrollView.contentOffset.y = newPos
                }
            }
        }else if method.hasPrefix("handleTapEvent") {
            focusStateCallback?(focus: true)
        }
    }
}

// MARK: UIGestureRecognizerDelegate
extension WebEditorView: UIGestureRecognizerDelegate {

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func viewWasTapped(sender: UITapGestureRecognizer) {
        let tapPoint = sender.locationInView(self)
        handleViewTapped(tapPoint.y)
    }
}

extension WebEditorView {
    public func getBody() -> String {
        return runJS("RE.getBodyHtml();")
    }
    
    public func checkContentEmpty() -> Bool {
        let ret = runJS("RE.checkContentEmpty();")
        return ret != "true"
    }
    
    public func getBodyHtmlLength() -> Int {
        let ret = runJS("RE.getBodyHtmlLength();")
        return Int(ret) ?? 0
    }
    
    func handleViewTapped(position: CGFloat) {
        runJS("RE.handleViewTapped('\(position)');")
    }
    
    func setPlaceholderText() {
        runJS("RE.setPlaceholderText('\(escape(placeholderBody))');")
    }
    
    func setContentHeight(contentHeight: CGFloat) {
        runJS("RE.contentHeight = '\(contentHeight)';")
    }
    
    func runJS(js: String) -> String {
        let string = webView.stringByEvaluatingJavaScriptFromString(js) ?? ""
        return string
    }
    
    private func escape(string: String) -> String {
        let unicode = string.unicodeScalars
        var newString = ""
        for i in unicode.startIndex ..< unicode.endIndex {
            let char = unicode[i]
            if char.value < 9 || (char.value > 9 && char.value < 32) // < 32 == special characters in ASCII, 9 == horizontal tab in ASCII
                || char.value == 39 { // 39 == ' in ASCII
                let escaped = char.escape(asASCII: true)
                newString.appendContentsOf(escaped)
            } else {
                newString.append(char)
            }
        }
        return newString
    }
}

extension WebEditorView {
    public func focus() {
        runJS("RE.focus();")
        focusStateCallback?(focus: true)
    }
    
    public func blurFocus() {
        runJS("RE.blurFocus();")
        focusStateCallback?(focus: false)
    }
    
    public func backspace() {
        runJS("RE.backspace();")
    }
    
    public func removeFormat() {
        runJS("RE.removeFormat();")
    }
    
    public func setFontSize(size: Int) {
        runJS("RE.setFontSize('\(size))px');")
    }
    
    public func undo() {
        runJS("RE.undo();")
    }
    
    public func redo() {
        runJS("RE.redo();")
    }
    
    public func bold() {
        runJS("RE.setBold();")
    }
    
    public func italic() {
        runJS("RE.setItalic();")
    }
    
    // "superscript" is a keyword
    public func subscriptText() {
        runJS("RE.setSubscript();")
    }
    
    public func superscript() {
        runJS("RE.setSuperscript();")
    }
    
    public func strikethrough() {
        runJS("RE.setStrikeThrough();")
    }
    
    public func underline() {
        runJS("RE.setUnderline();")
    }
    
    public func header(h: Int) {
        runJS("RE.setHeading('\(h)');")
    }
    
    public func indent() {
        runJS("RE.setIndent();")
    }
    
    public func outdent() {
        runJS("RE.setOutdent();")
    }
    
    public func orderedList() {
        runJS("RE.setOrderedList();")
    }
    
    public func unorderedList() {
        runJS("RE.setUnorderedList();")
    }
    
    public func blockquote() {
        runJS("RE.setBlockquote()");
    }
    
    public func alignLeft() {
        runJS("RE.setJustifyLeft();")
    }
    
    public func alignCenter() {
        runJS("RE.setJustifyCenter();")
    }
    
    public func alignRight() {
        runJS("RE.setJustifyRight();")
    }
    
    public func insertLink(href: String, title: String) {
        runJS("RE.prepareInsert();")
        runJS("RE.insertLink('\(escape(href))', '\(escape(title))');")
    }
    
    /**
        插入图片
        
        - parameter url: 图片地址， 可以是本地或者远端的地址。
        - parameter classStr: img 标签中的 class
        - parameter alt: img 标签中的 alt
    */
    public func insertImage(url: String, classStr: String, alt: String) {
        runJS("RE.prepareInsert();")
        runJS("RE.insertImage('\(escape(url))', '\(escape(classStr))', '\(escape(alt))');")
    }
    
    /**
        可以插入本地图片，避免去下载。在 getBody 时，会把 img 标签的 src 替换成 remoteUrl。可用于插入表情等客户端和服务端有固定链接对应的情况。
     
        - parameter localUrl: 本地地址
        - parameter remoteUrl: 远端地址
        - parameter classStr: img 标签中的 class
        - parameter alt: img 标签中的 alt
    */
    public func insertLocalImage(localUrl: String, remoteUrl: String, classStr: String, alt: String) {
        runJS("RE.prepareInsert();")
        runJS("RE.insertLocalImage('\(escape(localUrl))', '\(escape(remoteUrl))','\(escape(classStr))', '\(escape(alt))');")
    }
}
