//
//  WebEditorToolItem.swift
//  WebEditor
//
//  Created by liutingting on 16/7/12.
//  Copyright (c) 2016 liutingting. All rights reserved.
//

import Foundation

public enum WebEditorToolOptions {
    
    case clear
    case undo
    case redo
    case bold       //粗体
    case italic     //斜体
    case `subscript`
    case superscript
    case strike
    case underline
    case header(Int)
    case indent         //缩进
    case outdent
    case orderedList
    case unorderedList
    case alignLeft
    case alignCenter
    case alignRight
    case image
    case link
    
    public static func all() -> [WebEditorToolOptions] {
        return [
            .clear,
            .undo, .redo, .bold, .italic,
            .subscript, .superscript, .strike, .underline,
            .header(1), .header(2), .header(3), .header(4), .header(5), .header(6),
            .indent, .outdent, .orderedList, .unorderedList,
            .alignLeft, .alignCenter, .alignRight,
            .image, .link
        ]
    }
    
    public var image: UIImage? {
        var name = ""
        switch self {
        case .clear: name = "clear"
        case .undo: name = "undo"
        case .redo: name = "redo"
        case .bold: name = "bold"
        case .italic: name = "italic"
        case .subscript: name = "subscript"
        case .superscript: name = "superscript"
        case .strike: name = "strikethrough"
        case .underline: name = "underline"
        case .header(let h): name = "h\(h)"
        case .indent: name = "indent"
        case .outdent: name = "outdent"
        case .orderedList: name = "ordered_list"
        case .unorderedList: name = "unordered_list"
        case .alignLeft: name = "justify_left"
        case .alignCenter: name = "justify_center"
        case .alignRight: name = "justify_right"
        case .image: name = "insert_image"
        case .link: name = "insert_link"
        }
        
        let bundle = Bundle(for: WebEditorView.self)
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}

public class WebEditorToolItem: UIButton {
    
    public var itemSize = CGSize(width: 22, height: 22)
    public var itemAction: (() -> Void)?
    
    public convenience init(image: UIImage?) {
        self.init()
        setImage(image, for: .normal)
        addTarget(self, action: #selector(WebEditorToolItem.barTapped), for: .touchUpInside)
    }
    
    func barTapped() {
        itemAction?()
    }
}
