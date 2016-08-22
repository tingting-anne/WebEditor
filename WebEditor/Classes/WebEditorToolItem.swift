//
//  WebEditorToolItem.swift
//  WebEditor
//
//  Created by liutingting on 16/7/12.
//  Copyright (c) 2016 liutingting. All rights reserved.
//

import Foundation

public enum WebEditorToolOptions {
    
    case Clear
    case Undo
    case Redo
    case Bold       //粗体
    case Italic     //斜体
    case Subscript
    case Superscript
    case Strike
    case Underline
    case Header(Int)
    case Indent         //缩进
    case Outdent
    case OrderedList
    case UnorderedList
    case AlignLeft
    case AlignCenter
    case AlignRight
    case Image
    case Link
    
    public static func all() -> [WebEditorToolOptions] {
        return [
            Clear,
            Undo, Redo, Bold, Italic,
            Subscript, Superscript, Strike, Underline,
            Header(1), Header(2), Header(3), Header(4), Header(5), Header(6),
            Indent, Outdent, OrderedList, UnorderedList,
            AlignLeft, AlignCenter, AlignRight,
            Image, Link
        ]
    }
    
    public var image: UIImage? {
        var name = ""
        switch self {
        case .Clear: name = "clear"
        case .Undo: name = "undo"
        case .Redo: name = "redo"
        case .Bold: name = "bold"
        case .Italic: name = "italic"
        case .Subscript: name = "subscript"
        case .Superscript: name = "superscript"
        case .Strike: name = "strikethrough"
        case .Underline: name = "underline"
        case .Header(let h): name = "h\(h)"
        case .Indent: name = "indent"
        case .Outdent: name = "outdent"
        case .OrderedList: name = "ordered_list"
        case .UnorderedList: name = "unordered_list"
        case .AlignLeft: name = "justify_left"
        case .AlignCenter: name = "justify_center"
        case .AlignRight: name = "justify_right"
        case .Image: name = "insert_image"
        case .Link: name = "insert_link"
        }
        
        let bundle = NSBundle(forClass: WebEditorView.self)
        return UIImage(named: name, inBundle: bundle, compatibleWithTraitCollection: nil)
    }
}

public class WebEditorToolItem: UIButton {
    
    public var itemSize = CGSizeMake(22, 22)
    public var itemAction: (() -> Void)?
    
    public convenience init(image: UIImage?) {
        self.init()
        setImage(image, forState: .Normal)
        addTarget(self, action: #selector(WebEditorToolItem.barTapped), forControlEvents: .TouchUpInside)
    }
    
    func barTapped() {
        itemAction?()
    }
}