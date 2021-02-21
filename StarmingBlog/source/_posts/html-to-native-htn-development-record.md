---
title: HTML 转原生 HTN 项目开发记录
date: 2017-10-16 15:49:00
tags: [Web, Swift]
categories: Programming
---

## 前言
本文主要是记录 HTN 项目开发的过程。关于这个项目先前在 Swift 开发者大会上我曾经演示过，不过当时项目结构不完善，不易扩展，也没有按照标准来。所以这段时间，我研究了下 W3C 的标准和 WebKit 的一些实现，对于这段时间的研究也写了篇文章[深入剖析 WebKit](http://www.starming.com/2017/10/11/deeply-analyse-webkit/)。重构了下这个项目，我可以先说下已经完成的部分，最后列下后面的规划。项目已经放到了 Github 上：[https://github.com/ming1016/HTN](https://github.com/ming1016/HTN) 后面可以对着代码看。

## 项目使用介绍
通过解析 html 生成 DOM 树，解析 CSS，生成渲染树，计算布局，最终生成原生 Textrue 代码。下面代码可以看到完整的过程的各个方法。
```swift
let treeBuilder = HTMLTreeBuilder(htmlStr) //htmlStr 就是 需要转的 html 代码
_ = treeBuilder.parse() //解析 html 生成 DOM 树
let cssStyle = CSSParser(treeBuilder.doc.allStyle()).parseSheet() //解析 CSS
let document = StyleResolver().resolver(treeBuilder.doc, styleSheet: cssStyle) //生成渲染树

//转 Textrue
let layoutElement = LayoutElement().createRenderer(doc: document) //计算布局
_ = HTMLToTexture(nodeName:"Flexbox").converter(layoutElement); //生成原生 Textrue 代码
```

比如有下面的 html

![04](/uploads/html-to-native-htn-development-record/04.png)

在浏览器里显示是这样

![06](/uploads/html-to-native-htn-development-record/06.png)

通过 HTN 生成的原生代码

![05](/uploads/html-to-native-htn-development-record/05.png)

在 iPhone X 模拟器的效果如下

![07](/uploads/html-to-native-htn-development-record/07.png)

下面详细介绍下具体的实现关键点

## HTML
这部分最关键的部分是在 HTML/HTMLTokenizer.swift 里。首先会根据 W3C 里的 Tokenization 的标准 [https://dev.w3.org/html5/spec-preview/tokenization.html](https://dev.w3.org/html5/spec-preview/tokenization.html) 来定义一个状态的枚举，如下，可以目前完成这些状态的情况
```swift
//枚举
    enum S: HTNStateType {
        case DataState //half done
        case CharacterReferenceInDataState
        case RCDATAState
        case CharacterReferenceInRCDATAState
        case RAWTEXTState
        case ScriptDataState
        case PLAINTEXTState
        case TagOpenState //half done
        case EndTagOpenState
        case TagNameState //half done
        
        case RCDATALessThanSignState
        case RCDATAEndTagOpenState
        case RCDATAEndTagNameState
        
        case RAWTEXTLessThanSignState
        case RAWTEXTEndTagOpenState
        case RAWTEXTEndTagNameState
        
        //Script
        case ScriptDataLessThanSignState
        case ScriptDataEndTagOpenState
        case ScriptDataEndTagNameState
        case ScriptDataEscapeStartState
        case ScriptDataEscapeStartDashState
        case ScriptDataEscapedState
        case ScriptDataEscapedDashState
        case ScriptDataEscapedDashDashState
        case ScriptDataEscapedLessThanSignState
        case ScriptDataEscapedEndTagOpenState
        case ScriptDataEscapedEndTagNameState
        case ScriptDataDoubleEscapeStartState
        case ScriptDataDoubleEscapedState
        case ScriptDataDoubleEscapedDashState
        case ScriptDataDoubleEscapedDashDashState
        case ScriptDataDoubleEscapedLessThanSignState
        case ScriptDataDoubleEscapeEndState
        
        //Tag
        case BeforeAttributeNameState
        case AttributeNameState //half done
        case AfterAttributeNameState
        case BeforeAttributeValueState
        case AttributeValueDoubleQuotedState //half done
        case AttributeValueSingleQuotedState
        case AttributeValueUnquotedState
        case CharacterReferenceInAttributeValueState
        case AfterAttributeValueQuotedState //half done
        case SelfClosingStartTagState
        case BogusCommentState
        case ContinueBogusCommentState
        case MarkupDeclarationOpenState //half done
        
        //Comment
        case CommentStartState //half done
        case CommentStartDashState
        case CommentState
        case CommentEndDashState //half done
        case CommentEndState //half done
        case CommentEndBangState
        
        //DOCTYPE
        case DOCTYPEState //half done
        case BeforeDOCTYPENameState //half done
        case DOCTYPENameState
        case AfterDOCTYPENameState //half done
        case AfterDOCTYPEPublicKeywordState //half done
        case BeforeDOCTYPEPublicIdentifierState //half done
        case DOCTYPEPublicIdentifierDoubleQuotedState //half done
        case DOCTYPEPublicIdentifierSingleQuotedState
        case AfterDOCTYPEPublicIdentifierState //half done
        case BetweenDOCTYPEPublicAndSystemIdentifiersState
        case AfterDOCTYPESystemKeywordState
        case BeforeDOCTYPESystemIdentifierState
        case DOCTYPESystemIdentifierDoubleQuotedState
        case DOCTYPESystemIdentifierSingleQuotedState
        case AfterDOCTYPESystemIdentifierState
        case BogusDOCTYPEState
        
        case CDATASectionState
        case CDATASectionRightSquareBracketState
        case CDATASectionDoubleRightSquareBracketState
    }
```
处理这些状态采用的是状态机原理。根据状态机数学模型提取出需要的状态集合，事件集合，事件集合在这里是所遇字符的集合做了一个状态机，具体实现在 HTNFundation/HTNStateMachine.swift。状态转移函数我定义的是 func listen(_ event: E, transit fromState: S, to toState: S, callback: @escaping (HTNTransition<S, E>) -> Void) ，这里的 block 是在状态转移时需要做的事情定义 。为了能够减少状态转移太多太碎，也多写了几个函数来处理比如一组来源状态到同一个转移状态和针对某些事件状态不变的函数。

有了状态机后面的处理就会很方便，这里的事件就是一个一个的字符，不同字符在不同的状态下的处理。下面可以举个多状态转同一状态的实现，具体代码如下：
```swift
let anglebracketRightEventFromStatesArray = [S.DOCTYPEState,
                                             S.CommentEndState,
                                             S.TagOpenState,
                                             S.EndTagOpenState,
                                             S.AfterAttributeValueQuotedState,
                                             S.BeforeDOCTYPENameState,
                                             S.AfterDOCTYPEPublicIdentifierState]
stateMachine.listen(E.AngleBracketRight, transit: anglebracketRightEventFromStatesArray, to: S.DataState) { (t) in
    if t.fromState == S.TagOpenState || t.fromState == S.EndTagOpenState {
        if self._bufferStr.count > 0 {
            self._bufferToken.data = self._bufferStr.lowercased()
        }
    }
    self.addHTMLToken()
    self.advanceIndexAndResetCurrentStr()
}
```

W3C 也定义每个状态的处理，非常详细完整，WebKit 基本把这些定义都实现了，HTN 目前只实现了能够满足构建 DOM 树的部分。W3C 的定义可以举个 StartTags 的状态如下图
![01](/uploads/html-to-native-htn-development-record/01.png)

在进入构建 DOM 树之前我们需要设计一些类和结构来记录我们的内容，这里采用了 WebKit 类似的类结构设计，下图是 WebKit 的 DOM 树相关的类设计图
![02](/uploads/html-to-native-htn-development-record/02.png)

完成了这些状态处理，接下来就可以根据这些 HTMLToken 来组装我们的 DOM 树了。这部分的实现在 HTML/HTMLTreeBuilder.swift 里。构建 DOM 树同样使用了先前的写的状态机，只是这里的状态集和事件集不同而已，W3C 也定义一些状态可以用
```swift
enum S: HTNStateType {
    case InitialModeState
    case BeforeHTMLState
    case BeforeHeadState
    case InHeadState
    case AfterHeadState
    case InBodyState
    case AfterBodyState
    case AfterAfterBodyState
}
```
从名字就能很方便的看出每个状态的意思。这里的事件集使用的是 HTMLToken 里的类型，根据不同类型来放置到合适的位置。树的父级子级是通过定义的一个堆栈来控制，具体构建实现可以看 func parse() -> [HTMLToken] 这个函数。

## CSS
解析 CSS 需要先了解下 CSS 的 BNF，它的定义如下：
```
ruleset
  : selector [ ',' S* selector ]*
    '{' S* declaration [ ';' S* declaration ]* '}' S*
  ;
selector
  : simple_selector [ combinator selector | S+ [ combinator selector ] ]
  ;
simple_selector
  : element_name [ HASH | class | attrib | pseudo ]*
  | [ HASH | class | attrib | pseudo ]+
  ;
class
  : '.' IDENT
  ;
element_name
  : IDENT | '*'
  ;
attrib
  : '[' S* IDENT S* [ [ '=' | INCLUDES | DASHMATCH ] S*
    [ IDENT | STRING ] S* ] ']'
  ;
pseudo
  : ':' [ IDENT | FUNCTION S* [IDENT S*] ')' ]
  ;
```

根据 BNF 来确定状态集和事件集。下面是我定义的状态集和事件集
```swift
enum S: HTNStateType {
    case UnknownState     //
    case SelectorState    // 比如 div p, #id
    case PropertyKeyState   // 属性的 key
    case PropertyValueState // 属性的 value
    
    //TODO:以下后期支持，优先级2
    case PseudoClass      // :nth-child(2)
    case PseudoElement    // ::first-line
    
    //TODO:以下后期支持，优先级3
    case PagePseudoClass
    case AttributeExact   // E[attr]
    case AttributeSet     // E[attr|="value"]
    case AttributeHyphen  // E[attr~="value"]
    case AttributeList    // E[attr*="value"]
    case AttributeContain // E[attr^="value"]
    case AttributeBegin   // E[attr$="value"]
    case AttributeEnd
    //TODO:@media 这类 @规则 ，后期支持，优先级4
}
enum E: HTNEventType {
    case SpaceEvent   //空格
    case CommaEvent   // ,
    case DotEvent     // .
    case HashTagEvent // #
    case BraceLeftEvent  // {
    case BraceRightEvent // }
    case ColonEvent // :
    case SemicolonEvent  // ;
}
```

同样在状态的处理过程中也需要一个合理的类结构关系设计来满足，这里也参考了 WebKit 里的设计，如下：
![03](/uploads/html-to-native-htn-development-record/03.png)

## 布局
布局处理目前 HTN 主要是将样式属性和 DOM 树里的 Element 对应上。具体实现是在 Layout/StyleResolver.swift 里。思路是先将所有 CSSRule 和对应的 CSSSelector 做好映射，接着在递归 DOM 树的过程中与每个 Element 对应上。主要代码实现如下：
```swift
public func resolver(_ doc:Document, styleSheet:CSSStyleSheet) -> Document{
    //样式映射表
    //这种结构能够支持多级 Selector
    var matchMap = [String:[String:[String:String]]]()
    for rule in styleSheet.ruleList {
        for selector in rule.selectorList {
            guard let matchLast = selector.matchList.last else {
                continue
            }
            var matchDic = matchMap[matchLast]
            if matchDic == nil {
                matchDic = [String:[String:String]]()
                matchMap[matchLast] = matchDic
            }
            
            //这里可以按照后加入 rulelist 的优先级更高的原则进行覆盖操作
            if matchMap[matchLast]![selector.identifier] == nil {
                matchMap[matchLast]![selector.identifier] = [String:String]()
            }
            for a in rule.propertyList {
                matchMap[matchLast]![selector.identifier]![a.key] = a.value
            }
        }
    }
    for elm in doc.children {
        self.attach(elm as! Element, matchMap: matchMap)
    }
    
    return doc
}
//递归将样式属性都加上
func attach(_ element:Element, matchMap:[String:[String:[String:String]]]) {
    guard let token = element.startTagToken else {
        return
    }
    if matchMap[token.data] != nil {
        //TODO: 还不支持 selector 里多个标签名组合，后期加上
        addProperty(token.data, matchMap: matchMap, element: element)
    }
    
    //增加 property 通过处理 token 里的属性列表里的 class 和 id 在 matchMap 里找
    for attr in token.attributeList {
        if attr.name == "class" {
            addProperty("." + attr.value.lowercased(), matchMap: matchMap, element: element)
        }
        if attr.name == "id" {
            addProperty("#" + attr.value.lowercased(), matchMap: matchMap, element: element)
        }
    }
    
    if element.children.count > 0 {
        for element in element.children {
            self.attach(element as! Element, matchMap: matchMap)
        }
    }
}

func addProperty(_ key:String, matchMap:[String:[String:[String:String]]], element:Element) {
    guard let dic = matchMap[key] else {
        return
    }
    for aDic in dic {
        var selectorArr = aDic.key.components(separatedBy: " ")
        if selectorArr.count > 1 {
            //带多个 selector 的情况
            selectorArr.removeLast()
            if !recursionSelectorMatch(selectorArr, parentElement: element.parent as! Element) {
                continue
            }
        }
        guard let ruleDic = dic[aDic.key] else {
            continue
        }
        //将属性加入 element 的属性列表里
        for property in ruleDic {
            element.propertyMap[property.key] = property.value
        }
    }
    
}
```

这里通过 recursionSelectorMatch 来按照 CSS Selector 从右到左的递归出是否匹配路径，具体实现代码如下：
```swift
//递归找出匹配的多路径
func recursionSelectorMatch(_ selectors:[String], parentElement:Element) -> Bool {
    var selectorArr = selectors
    guard var last = selectorArr.last else {
        //表示全匹配了
        return true
    }
    guard let parent = parentElement.parent else {
        return false
    }
    
    var isMatch = false
    
    if last.hasPrefix(".") {
        last.characters.removeFirst()
        //TODO:这里还需要考虑attribute 空格多个 class 名的情况
        guard let startTagToken = parentElement.startTagToken else {
            return false
        }
        if startTagToken.attributeDic["class"] == last {
            isMatch = true
        }
    } else if last.hasPrefix("#") {
        last.characters.removeFirst()
        guard let startTagToken = parentElement.startTagToken else {
            return false
        }
        if startTagToken.attributeDic["id"] == last {
            isMatch = true
        }
    } else {
        guard let startTagToken = parentElement.startTagToken else {
            return false
        }
        if startTagToken.data == last {
            isMatch = true
        }
    }
    
    if isMatch {
        //匹配到会继续往前去匹配
        selectorArr.removeLast()
    }
    return recursionSelectorMatch(selectorArr, parentElement: parent as! Element)
    
}
```

## 转原生
已完成一部分简单布局属性转换 Texture 原生代码。具体实现部分可以参看 HTMLToTexture.swift 文件。

## 已完成
* 解析 HTML 构建 DOM 树，解析 CSS 构建渲染树
* CSS Selector 的 Tag 路径支持，Tag 和 class，id 的组合选择。
* flexbox 属性，margin 和 padding 映射 Texture 原生代码

## 规划
* 支持图片标签，支持 CSS background 背景属性
* html 的 class 属性还不支持空格多个 class 名
* text-transform 属性的支持
* em 转 pt，em 是相对父元素值的乘积值。
* 支持CSS选择器的 :before 和 :after

* HTN 的 Objective-C 版。
* 支持转 Objective-C 的原生代码。
* 解析转换器内嵌在应用程序内部，支持服务器下发 h5 代码转换。
* 应用内转换时的缓存的处理，将render树结构体进行缓存的处理

* HTML 内 JS 解析，支持逻辑控制 HTML










