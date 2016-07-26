"use strict";

var RE = {};

window.onload = function() {
    RE.callback("ready");

    document.execCommand('insertBrOnReturn', false, false);
    document.execCommand('defaultParagraphSeparator', false, this.defaultParagraphSeparator);
    document.execCommand('styleWithCSS', false, false);
};

RE.editor = document.getElementById('field_content');
RE.quote = document.getElementById('field_quote_content');
RE.contentHeight = 244;

RE.getCaretYPosition = function() {
    var sel = window.getSelection();
    // Next line is comented to prevent deselecting selection. It looks like work but if there are any issues will appear then uconmment it as well as code above.
    //sel.collapseToStart();
    var range = sel.getRangeAt(0);
    var span = document.createElement('span');// something happening here preventing selection of elements
    range.collapse(false);
    range.insertNode(span);
    var topPosition = span.offsetTop;
    span.parentNode.removeChild(span);
    return topPosition;
}

RE.calculateEditorHeightWithCaretPosition = function() {

    var c = RE.getCaretYPosition(RE.editor);
    RE.callback("scrollTo="+c);

    //直接js移动有问题，开始移动正常，后来移动了但是再获取pageYOffset有问题，而且移动有时候不成功，不知道为什么。。。
//    var padding = 15;
//    var lineHeight = 24;
//    var offsetY = window.document.body.scrollTop;
//    var height = RE.contentHeight;
//    var newPos = window.pageYOffset;
//
//   // alert("c="+ c +"  Y=" + offsetY + "  height=" + height + "  newPos="+ newPos)
//
//    if (c < offsetY) {
//        newPos = c;
//    } else if (c > (offsetY + height - padding - lineHeight)) {
//        newPos = c - height + padding + lineHeight + lineHeight;
//    }
//  window.scrollTo(0, newPos);
}

// Not universally supported, but seems to work in iOS 7 and 8
document.addEventListener("selectionchange", function() {
                          RE.backuprange();
                          });

//looks specifically for a Range selection and not a Caret selection
RE.rangeSelectionExists = function() {
    var sel = document.getSelection();
    if (sel && sel.type == "Range") {
        return true;
    }
    return false;
};

RE.rangeOrCaretSelectionExists = function() {
    var sel = document.getSelection();
    if (sel && (sel.type == "Range" || sel.type == "Caret")) {
        return true;
    }
    return false;
};

RE.editor.addEventListener("input", function() {
                           RE.updatePlaceholder();
                           RE.backuprange();
                           RE.calculateEditorHeightWithCaretPosition();
                           RE.callback("input");
                           });

RE.editor.addEventListener("focus", function() {
                           RE.backuprange();
                           RE.calculateEditorHeightWithCaretPosition();
                           RE.callback("focus");
                           });

RE.editor.addEventListener("blur", function() {
                           RE.callback("blur");
                           });

RE.editor.addEventListener("touchend", function(e) {
                           RE.handleTapEvent(e);
                           });

RE.customAction = function(action) {
    RE.callback("action/" + action);
};

RE.updateHeight = function() {
    RE.callback("updateHeight");
}

RE.callbackQueue = [];
RE.runCallbackQueue = function() {
    if (RE.callbackQueue.length === 0) {
        return;
    }

    setTimeout(function() {
               window.location.href = "re-callback://";
               }, 0);
};

RE.getCommandQueue = function() {
    var commands = JSON.stringify(RE.callbackQueue);
    RE.callbackQueue = [];
    return commands;
};

RE.callback = function(method) {
    RE.callbackQueue.push(method);
    RE.runCallbackQueue();
};

RE.setHtml = function(contents) {
    var tempWrapper = document.createElement('div');
    tempWrapper.innerHTML = contents;
    var images = tempWrapper.querySelectorAll("img");

    for (var i = 0; i < images.length; i++) {
        images[i].onload = RE.updateHeight;
    }

    RE.editor.innerHTML = tempWrapper.innerHTML;
    RE.updatePlaceholder();
};

RE.getBodyHtml = function() {
    var images = document.querySelectorAll("img.DXYEditorNeedReplaceRemoteURL"), index;
    for (index = 0; index < images.length; ++index) {
        var image = images[index];
        image.src = image.getAttribute("remoteSrc");
        image.classList.remove("DXYEditorNeedReplaceRemoteURL");
        image.removeAttribute("remoteSrc");
    }
    var body = RE.editor.innerHTML;

    //去掉最开头的<br> ,body.startsWith("<br>") iOS8下解析不过
    if (body.substring(0, 4) == "<br>") {
        body = body.substring(4, body.length);
    }
    return body;
};

RE.getBodyHtmlLength = function() {
    var body = RE.editor.innerHTML;
    body = body.replace('&nbsp;', ' ');
    body = body.replace('&nbsp', ' ');
    return body.length;
};

RE.getText = function() {
    return RE.editor.innerText;
};

RE.setPlaceholderText = function(body) {
    RE.editor.setAttribute("placeholder", body);
    RE.updatePlaceholder();
};

RE.updatePlaceholder = function() {
   // var nbsp = '\xa0';
   // var text = RE.editor.innerText.replace(nbsp, '');

    //输入后再删除最后还是会留个<br>
    if (RE.checkContentEmpty() == true) {
        RE.editor.classList.add("placeholder");
    } else {
        RE.editor.classList.remove("placeholder");
    }
};

RE.checkContentEmpty = function() {
    var html = RE.editor.innerHTML;
    var ret = false;
    if ((html.length == 0 || html == "<br>") && RE.quote.innerHTML.length == 0) {
        ret = true;
    }
    return ret;
};

RE.removeFormat = function() {
    document.execCommand('removeFormat', false, null);
};

RE.setFontSize = function(size) {
    RE.editor.style.fontSize = size;
};

RE.setBackgroundColor = function(color) {
    RE.editor.style.backgroundColor = color;
};

RE.setHeight = function(size) {
    RE.editor.style.height = size;
};

RE.undo = function() {
    document.execCommand('undo', false, null);
};

RE.redo = function() {
    document.execCommand('redo', false, null);
};

RE.setBold = function() {
    document.execCommand('bold', false, null);
};

RE.setItalic = function() {
    document.execCommand('italic', false, null);
};

RE.setSubscript = function() {
    document.execCommand('subscript', false, null);
};

RE.setSuperscript = function() {
    document.execCommand('superscript', false, null);
};

RE.setStrikeThrough = function() {
    document.execCommand('strikeThrough', false, null);
};

RE.setUnderline = function() {
    document.execCommand('underline', false, null);
};

RE.setTextColor = function(color) {
    RE.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('foreColor', false, color);
    document.execCommand("styleWithCSS", null, false);
};

RE.setTextBackgroundColor = function(color) {
    RE.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('hiliteColor', false, color);
    document.execCommand("styleWithCSS", null, false);
};

RE.setHeading = function(heading) {
    document.execCommand('formatBlock', false, '<h' + heading + '>');
};

RE.setIndent = function() {
    document.execCommand('indent', false, null);
};

RE.setOutdent = function() {
    document.execCommand('outdent', false, null);
};

RE.setOrderedList = function() {
    document.execCommand('insertOrderedList', false, null);
};

RE.setUnorderedList = function() {
    document.execCommand('insertUnorderedList', false, null);
};

RE.setJustifyLeft = function() {
    document.execCommand('justifyLeft', false, null);
};

RE.setJustifyCenter = function() {
    document.execCommand('justifyCenter', false, null);
};

RE.setJustifyRight = function() {
    document.execCommand('justifyRight', false, null);
};

RE.insertImage = function(url, classStr, alt) {
    var img = document.createElement('img');
    img.setAttribute("src", url);
    img.setAttribute("class", classStr)
    img.setAttribute("alt", alt);
    img.onload = RE.updateHeight;

    RE.insertHTML(img.outerHTML);
    RE.callback("input");
};

RE.insertLocalImage = function(localUrl, remoteUrl, classStr, alt) {
    var img = document.createElement('img');
    img.setAttribute("src", localUrl);
    img.setAttribute("remoteSrc", remoteUrl);
    img.setAttribute("class", classStr + " DXYEditorNeedReplaceRemoteURL");
    img.setAttribute("alt", alt);
    img.onload = RE.updateHeight;

    RE.insertHTML(img.outerHTML);
    RE.callback("input");
};

RE.setBlockquote = function() {
    document.execCommand('formatBlock', false, '<blockquote>');
};

RE.insertHTML = function(html) {
    RE.restorerange();
    document.execCommand('insertHTML', false, html);
};

RE.insertLink = function(url, title) {
    RE.restorerange();
    var sel = document.getSelection();
    if (sel.toString().length != 0) {
        if (sel.rangeCount) {

            var el = document.createElement("a");
            el.setAttribute("href", url);
            el.setAttribute("title", title);

            var range = sel.getRangeAt(0).cloneRange();
            range.surroundContents(el);
            sel.removeAllRanges();
            sel.addRange(range);
        }
    }
    RE.callback("input");
};

RE.prepareInsert = function() {
    RE.backuprange();
};

RE.backuprange = function() {
    var selection = window.getSelection();
    if (selection.rangeCount > 0) {
        var range = selection.getRangeAt(0);
        RE.currentSelection = {
            "startContainer": range.startContainer,
            "startOffset": range.startOffset,
            "endContainer": range.endContainer,
            "endOffset": range.endOffset
        };
    }
};

//backspace-----
RE.backspace = function() {
    var range = document.createRange();
    range.setStart(RE.currentSelection.startContainer, RE.currentSelection.startOffset);
    range.setEnd(RE.currentSelection.endContainer, RE.currentSelection.endOffset);
    range.collapse(false);

    var span = document.createElement('span');
    range.insertNode(span);
    var preNode = span.previousSibling;
    var parentNode = span.parentNode;

    if (preNode.nodeName.toLowerCase() == 'img') {

        parentNode.removeChild(span);
        var preNodePre = preNode.previousSibling;
        if (preNodePre == null) {
            if (parentNode.parentNode.tagName.toLowerCase() == "body") {
                parentNode.removeChild(preNode);
                RE.backSpaceReset();
            }else {
                parentNode.removeChild(preNode);
                preNodePre = parentNode.parentNode.lastChild;
                RE.backSpaceLocate(preNodePre);
            }
        }else {
            parentNode.removeChild(preNode);
            RE.backSpaceLocate(preNodePre);
        }

    }else if (preNode.nodeName.toLowerCase() == '#text') {

        parentNode.removeChild(span);
        var text = preNode.textContent;
        preNode.textContent = text.slice(0, -1);

        if (preNode.textContent.length <= 0) {
            var preNodePre = preNode.previousSibling;
            if (preNodePre == null) {
                if (parentNode.parentNode.tagName.toLowerCase() == "body") {
                    parentNode.removeChild(preNode);
                    RE.backSpaceReset();
                }else {
                    parentNode.removeChild(preNode);
                    preNodePre = parentNode.parentNode.lastChild;
                    RE.backSpaceLocate(preNodePre);
                }
            }else {
                parentNode.removeChild(preNode);
                RE.backSpaceLocate(preNodePre);
            }

        }else {
            RE.backSpaceLocate(preNode);
        }
    }
};

RE.backSpaceReset = function() {
    var rangeBak = document.createRange();
    rangeBak.selectNodeContents(RE.editor);
    rangeBak.collapse(false);
    RE.currentSelection = {
        "startContainer": rangeBak.startContainer,
        "startOffset": rangeBak.startOffset,
        "endContainer": rangeBak.endContainer,
        "endOffset": rangeBak.endOffset
    };
};

RE.backSpaceLocate = function(destNode) {
    var rangeBak = document.createRange();
    rangeBak.setStartAfter(destNode);
    rangeBak.collapse(true);
    
    RE.currentSelection = {
        "startContainer": rangeBak.startContainer,
        "startOffset": rangeBak.startOffset,
        "endContainer": rangeBak.endContainer,
        "endOffset": rangeBak.endOffset
    };
};


RE.handleTapEvent = function(e) {
    if (RE.editor != document.activeElement) {
        RE.callback("handleTapEvent");
    }

    if (e.target.nodeName.toLowerCase() == 'img') {
//        RE.focusToEnd();
        e.preventDefault(); //否则会定位

        var selection = window.getSelection();
        selection.removeAllRanges();
        var range = document.createRange();
        range.setStartAfter(e.target);
        range.collapse(true);
        selection.addRange(range);
        RE.backuprange();
    }
};

RE.handleViewTapped = function(position) {//外部调用，点击在内容外，不会触发聚焦行为，为防止覆盖默认的点击定位光标行为，导致光标位置不准需要判断
    if (RE.checkContentEmpty() == true) {
        RE.focusToEnd();
    }else if (RE.editor.offsetHeight + 15 < position) { //pading算在内，但不包括margin
        RE.focusToEnd();
    }
};

RE.addRangeToSelection = function(selection, range) {
    if (selection) {
        selection.removeAllRanges();
        selection.addRange(range);
    }
};

// Programatically select a DOM element
RE.selectElementContents = function(el) {
    var range = document.createRange();
    range.selectNodeContents(el);
    var sel = window.getSelection();
    // this.createSelectionFromRange sel, range
    RE.addRangeToSelection(sel, range);
};

RE.restorerange = function() {
    var selection = window.getSelection();
    selection.removeAllRanges();
    var range = document.createRange();
    range.setStart(RE.currentSelection.startContainer, RE.currentSelection.startOffset);
    range.setEnd(RE.currentSelection.endContainer, RE.currentSelection.endOffset);
    selection.addRange(range);
};

RE.focus = function() {
    //防止重复定位导致不能定位到指定位置
    if (RE.editor == document.activeElement) {
        return
    }

    if (RE.currentSelection != null) {
        RE.restorerange();
    }else {
        RE.focusToEnd();
    }
};

RE.blurFocus = function() {
    RE.editor.blur();
};

RE.focusToEnd = function() {
    var range = document.createRange();
    range.selectNodeContents(RE.editor);
    range.collapse(false);
    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    RE.editor.focus();
};

/**
 Recursively search element ancestors to find a element nodeName e.g. A
 **/
var _findNodeByNameInContainer = function(element, nodeName, rootElementId) {
    if (element.nodeName == nodeName) {
        return element;
    } else {
        if (element.id == rootElementId) {
            return null;
        }
        _findNodeByNameInContainer(element.parentElement, nodeName, rootElementId);
    }
};

var isAnchorNode = function(node) {
    return ("A" == node.nodeName);
};

RE.getAnchorTagsInNode = function(node) {
    var links = [];

    while (node.nextSibling != null && node.nextSibling != undefined) {
        node = node.nextSibling;
        if (isAnchorNode(node)) {
            links.push(node.getAttribute('href'));
        }
    }
    return links;
};

RE.countAnchorTagsInNode = function(node) {
    return RE.getAnchorTagsInNode(node).length;
};

/**
 * If the current selection's parent is an anchor tag, get the href.
 * @returns {string}
 */
RE.getSelectedHref = function() {
    var href, sel;
    href = '';
    sel = window.getSelection();
    if (!RE.rangeOrCaretSelectionExists()) {
        return null;
    }

    var tags = RE.getAnchorTagsInNode(sel.anchorNode);
    //if more than one link is there, return null
    if (tags.length > 1) {
        return null;
    } else if (tags.length == 1) {
        href = tags[0];
    } else {
        var node = _findNodeByNameInContainer(sel.anchorNode.parentElement, 'A', 'editor');
        href = node.href;
    }

    return href ? href : null;
};

RE.closerParentNode = function() {

    var parentNode = null;
    var selection = window.getSelection();
    var range = selection.getRangeAt(0).cloneRange();

    var currentNode = range.commonAncestorContainer;

    while (currentNode) {
        if (currentNode.nodeType == document.ELEMENT_NODE) {
            parentNode = currentNode;

            break;
        }

        currentNode = currentNode.parentElement;
    }

    return parentNode;
};
