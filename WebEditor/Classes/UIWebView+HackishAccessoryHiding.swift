//
//  UIWebView+HackishAccessoryHiding.swift
//  WebEditor
//
//  Created by liutingting on 16/7/1.
//  Copyright (c) 2016 liutingting. All rights reserved.
//

import Foundation

let hackishFixClassName = "UIWebBrowserViewMinusAccessoryView"
var hackishFixClass: AnyClass? = nil

extension UIWebView {
    private struct AssociatedKeys {
        static var hackInputAccessoryViewName = "hackInputAccessoryViewName"
    }
    
    func hackInputAccessoryView() -> UIView? {
        return objc_getAssociatedObject(self, &AssociatedKeys.hackInputAccessoryViewName) as? UIView
    }
    
    func setHackinputAccessoryView(view: UIView?) {
        objc_setAssociatedObject(self, &AssociatedKeys.hackInputAccessoryViewName, view, .OBJC_ASSOCIATION_RETAIN)
        if let browserView = hackishlyFoundBrowserView() {
            ensureHackishSubclassExistsOfBrowserViewClass(browserView.dynamicType)
            object_setClass(browserView, hackishFixClass)
            browserView.reloadInputViews()
        }
    }

    
    func hackishlyFoundBrowserView() -> UIView? {
        var browserView: UIView? = nil
        
        for subview in self.scrollView.subviews {
            if NSStringFromClass(subview.dynamicType).hasPrefix("UIWebBrowserView") {
                browserView = subview;
                break;
            }
        }
        return browserView;
    }
    
    func methodReturningCustomInputAccessoryView() -> UIView? {
        var view: UIView? = self
        while view != nil && !view!.isKindOfClass(UIWebView.self) {
            view = view!.superview
        }
        
        var customInputAccessoryView: UIView? = nil
        if let webview = view as? UIWebView {
            customInputAccessoryView = webview.hackInputAccessoryView()
        }
        return customInputAccessoryView
    }
    
    func ensureHackishSubclassExistsOfBrowserViewClass(browserViewClass: AnyClass) {
        if hackishFixClass == nil {
            let newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0)
            let nilImp = self.methodForSelector("methodReturningCustomInputAccessoryView")
            class_addMethod(newClass, "inputAccessoryView", nilImp, "@@:")
            objc_registerClassPair(newClass)
            hackishFixClass = newClass
        }
    }
}
