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
    var placeholderTitle = "讨论标题"
    var placeholderBody = "讨论正文"
    
    public private(set) var webView: UIWebView
    fileprivate var showTitle = true
    
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
        webView.autoresizingMask = [.flexibleHeight]
        webView.dataDetectorTypes = UIDataDetectorTypes()
        webView.scrollView.bounces = false
        webView.scrollView.clipsToBounds = true
        
        //解决webView最后显示一条黑色线的问题
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        
        //去掉默认扩展
        webView.setHackinputAccessoryView(view: nil)
        
        addSubview(webView)
        webView.snp.makeConstraints(){make in
            make.edges.equalTo(self)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(WebEditorView.viewWasTapped(_:)))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
    }

    /**
        加载编辑器
     
        - parameter showTitle: 是否显示标题
        - parameter title: 标题
        - parameter body: 正文
    */
    public func loadWebViewData(showTitle: Bool, title: String?, body: String?) {
        guard let path = Bundle(for: WebEditorView.self).path(forResource: "rich_editor", ofType: "html") else {
            return
        }
        
        let templateURL = URL(fileURLWithPath: path)
        let htmlTemp = try! String(contentsOf: templateURL, encoding: .utf8)
        
        let displayTitle = showTitle ? "" : "no"
        let data = String(format: htmlTemp,
            displayTitle, title ?? "",    //标题
            displayTitle,                 //分割线
            body ?? "")                   //正文
        webView.loadHTMLString(data, baseURL: templateURL)
        self.showTitle = showTitle
    }
}

// MARK: - UIWebViewDelegate

extension WebEditorView: UIWebViewDelegate {
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        // Handle pre-defined editor actions
        let callbackPrefix = "re-callback://"
        if request.url?.absoluteString.hasPrefix(callbackPrefix) == true {
            
            // When we get a callback, we need to fetch the command queue to run the commands
            // It comes in as a JSON array of commands that we need to parse
            let commands = runJS("RE.getCommandQueue();")
            if let data = (commands as NSString).data(using: String.Encoding.utf8.rawValue) {
                
                let jsonCommands: [String]?
                do {
                    jsonCommands = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String]
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
        
        if navigationType == .linkClicked {
            return false
        }
        return true
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        setPlaceholder()
        if showTitle {
            focusTitle()
        }else {
            focusContent()
        }
        
        if showTitle || checkContentEmpty() {
            webView.scrollView.contentOffset.y = 0
        }
    }
    
    fileprivate func performCommand(_ method: String) {
        enum MethodType: String {
            case inputContent = "inputContent"
            case inputTitle = "inputTitle"
            case focusTitle = "focusTitle"
            case blurFocusTitle = "blurFocusTitle"
            case contentAreaTapped = "contentAreaTapped"
        }
        
        guard let methodType = MethodType(rawValue: method) else {
            return
        }
        
        switch methodType {
        case .inputContent:
            scrollCaretToVisible()
        default:
            break
        }
    }
    
    fileprivate func getRelativeCaretYPosition() -> [Int]? {
        let string = runJS("RE.getRelativeCaretYPosition();")
        let resultArray = string.components(separatedBy: "+")
        var caretInfo = [Int]()
        for value in resultArray {
            if let intValue = Int(value) {
                caretInfo.append(intValue)
            }
        }
        return caretInfo.count == 2 ? caretInfo : nil
    }
    
    fileprivate func scrollCaretToVisible() {
        guard let caretPosition = getRelativeCaretYPosition() else {
            return
        }
        
        let scrollView = self.webView.scrollView
        let visiblePosition = CGFloat(caretPosition[0])
        let cursorHeight = CGFloat(caretPosition[1])
        var offset: CGPoint?
        
        if visiblePosition + cursorHeight > scrollView.bounds.size.height {
            // Visible caret position goes further than our bounds
            offset = CGPoint(x: 0, y: (visiblePosition + cursorHeight) - scrollView.bounds.height + scrollView.contentOffset.y)
            
        } else if visiblePosition < 0 {
            // Visible caret position is above what is currently visible
            var amount = scrollView.contentOffset.y + visiblePosition
            amount = amount < 0 ? 0 : amount
            offset = CGPoint(x: scrollView.contentOffset.x, y: amount)
            
        }
        
        if let offset = offset {
            scrollView.setContentOffset(offset, animated: true)
        }
    }
    
    @discardableResult
    func runJS(_ js: String) -> String {
        let string = webView.stringByEvaluatingJavaScript(from: js) ?? ""
        return string
    }
    
    fileprivate func escape(_ string: String) -> String {
        let unicode = string.unicodeScalars
        var newString = ""
        for char in unicode {
            if char.value < 9 || (char.value > 9 && char.value < 32) // < 32 == special characters in ASCII, 9 == horizontal tab in ASCII
                || char.value == 39 { // 39 == ' in ASCII
                let escaped = char.escaped(asASCII: true)
                newString.append(escaped)
            } else {
                newString.append(String(char))
            }
        }
        return newString
    }
}

// MARK: UIGestureRecognizerDelegate
extension WebEditorView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func viewWasTapped(_ sender: UITapGestureRecognizer) {
        let tapPoint = sender.location(in: self)
        handleContentAreaTapped(tapPoint.y)
    }
}

extension WebEditorView {
    
    func handleContentAreaTapped(_ position: CGFloat) {
        runJS("RE.handleContentAreaTapped('\(position)');")
    }
    
    public func getTitle() -> String {
        return runJS("RE.getTitle();")
    }
    
    public func checkTitleEmpty() -> Bool {
        let ret = runJS("RE.checkTitleEmpty();")
        return ret == "true"
    }
    
    public func getTitleHtmlLength() -> Int {
        let ret = runJS("RE.getTitleHtmlLength();")
        return Int(ret) ?? 0
    }
    
    public func getContent() -> String {
        return runJS("RE.getContent();")
    }
    
    public func checkContentEmpty() -> Bool {
        let ret = runJS("RE.checkContentEmpty();")
        return ret == "true"
    }
    
    public func getContentLength() -> Int {
        let ret = runJS("RE.getContentLength();")
        return Int(ret) ?? 0 //在webView还没有loadHTML时，stringByEvaluatingJavaScriptFromString 返回""
    }
    
    public func setPlaceholder() {
        runJS("RE.setTitlePlaceholder('\(escape(placeholderTitle))');")
        runJS("RE.setContentPlaceholder('\(escape(placeholderBody))');")
    }
    
    public func focusTitle() {
        runJS("RE.focusTitle();")
    }
    
    public func focusContent() {
        runJS("RE.focusContent();")
    }
    
    public func blurFocus() {
        runJS("RE.blurFocus();")
    }
    
    public func backspace() {
        runJS("RE.backspace();")
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
}
