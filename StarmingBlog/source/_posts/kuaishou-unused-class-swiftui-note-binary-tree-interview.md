---
title: 在快手做分享、无用类检查、在广州做 SwiftUI 学习笔记分享、InfoQ二叉树视频
date: 2020-01-05 15:57:05
tags: [Swift, iOS, SwiftUI]
categories: Programming
---

## 在快手做分享

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/00.jpeg)

前滴滴同事邀请我去快手做分享。下面是分享时的 Slides：

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/01.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/02.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/03.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/04.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/05.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/06.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/07.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/08.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/09.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/10.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/11.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/12.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/13.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/14.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/15.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/16.png)


详细文章介绍：[如何对 iOS 启动阶段耗时进行分析 | 星光社 - 戴铭的博客](https://ming1016.github.io/2019/12/07/how-to-analyze-startup-time-cost-in-ios/)

代码：[GitHub - ming1016/MethodTraceAnalyze: 方法耗时分析](https://github.com/ming1016/MethodTraceAnalyze)

## 无用类检查

如果包里有一堆没用的类，不光会影响用户下载速度，也会影响启动加载速度。检查无用类，一次是无法获得全部无用类的，因为无用的类里用了其他无用的类就算是有用了，所以需要进行递归查找，这样才能够连根拔起。这个过程如果是手动做比较费劲、收益无法一次评估，很难推动。同时还需要在线上灰度运行时检查实际类的使用情况，很多静态层面关联的类使用，实际运行过程中也可能用不到。

思路和关键代码如下。

### 第一步

使用 [MethodTraceAnalyze](https://github.com/ming1016/MethodTraceAnalyze) 里 ParseOC 类的 ocNodes 函数，通过传入 workspace 路径获取所有节点的结构体 OCNode。

```swift
let allNodes = ParseOC.ocNodes(workspacePath: workSpacePath)
```

找出类型是方法的结构体，因为类的初始化和使用都是在这些方法中进行的。OCNode 针对不同类型所存储的数据也是不同的，所以我定义一个 OCNodeValueProtocol 协议属性，这样就可以针对不同类型的节点存储不同的数据。

```swift
public struct OCNodeDefaultValue: OCNodeValueProtocol {
    public var defaultValue: String
    init() {
        defaultValue = ""
    }
}

public struct OCNodeMethod: OCNodeValueProtocol {
    public var belongClass: String
    public var methodName: String
    public var tokenNodes: [OCTokenNode]
}

public struct OCNodeClass: OCNodeValueProtocol {
    public var className: String
    public var baseClass: String
    public var hMethod: [String]
    public var mMethod: [String]
    public var baseClasses: [String]
}
```

可以看到对方法类型会存所属类、方法名和方法内所有 token以便进行进一步分析。对类这种类型会记录他的基类、类名、头文件方法列表和实现文件方法列表，还用一个栈记录继承链。

### 第二步

获取所有类的节点，通过对方法内所有 token 的分析来看使用了哪些类，并记录使用的类。

获取所有类节点的代码如下：

```swift
// 获取所有类节点
var allClassSet:Set<String> = Set()
for aNode in allNodes {
    if aNode.type == .class {
        let classValue = aNode.value as! OCNodeClass
        allClassSet.insert(classValue.className)
        if classValue.baseClass.count > 0 {
            baseClasses.insert(classValue.baseClass)
        }
        
    }
} // end for aNode in allNodes
```

记录使用的类关键代码：

```swift
static func parseAMethodUsedClass(node: OCNode, allClass: Set<String>) -> Set<String> {
    var usedClassSet:Set<String> = Set()
    guard node.type == .method else {
        return usedClassSet
    }
    
    let methodValue:OCNodeMethod = node.value as! OCNodeMethod
    for aNode in methodValue.tokenNodes {
        if allClass.contains(aNode.value) {
            usedClassSet.insert(aNode.value)
        }
    }
    
    return usedClassSet
}
```

### 第三步

有了所有使用的类和所有的类，就能够获取没用到的类。为了跑一次就能够将所有没用的类找出，所以需要在找到无用类后，将这些类自动去掉再进行下一次查找。我这里写了个递归来干这件事。具体代码如下：

```swift
var recursiveCount = 0

func recursiveCheckUnUsedClass(unUsed:Set<String>) -> Set<String> {
    recursiveCount += 1
    print("into recursive!!!!第\(recursiveCount)次")
    print("----------------------\n")
    for a in unUsed {
        print(a)
    }
    var unUsedClassSet = unUsed
    
    // 缩小范围
    for aUnUsed in unUsedClassSet {
        if allClassSet.contains(aUnUsed) {
            allClassSet.remove(aUnUsed)
        }
    }
    
    var allUsedClassSet:Set<String> = Set()
    for aNode in allNodes {
        if aNode.type == .method {
            let nodeValue:OCNodeMethod = aNode.value as! OCNodeMethod
            // 过滤已判定无用类里的方法
            guard !unUsedClassSet.contains(nodeValue.belongClass) else {
                continue
            }
            
            let usedSet = ParseOCMethodContent.parseAMethodUsedClass(node: aNode, allClass: allClassSet)
            if usedSet.count > 0 {
                for aSet in usedSet {
                    allUsedClassSet.insert(aSet)
                }
            } // end if usedSet.count > 0
        } // end if aNode.type == .method
    } // end for aNode in allNodes
    var hasUnUsed = false
    // 找出无用类
    for aSet in allClassSet {
        if !allUsedClassSet.contains(aSet) {
            unUsedClassSet.insert(aSet)
            hasUnUsed = true
        }
    }
    
    if hasUnUsed {
        // 如果发现还有无用的类，需要继续递归调用进行分析
        return recursiveCheckUnUsedClass(unUsed: unUsedClassSet)
    }
    
    return unUsedClassSet
}

// 递归调用
var unUsedClassFromRecursive = recursiveCheckUnUsedClass(unUsed: Set<String>())
```

通过递归进行多次能够取到最终的结果。

### 第四步

对于继承和系统的类还需要进行过滤，进一步提高准确性。

```swift
let unUsedClassSetCopy = unUsedClassFromRecursive
for aSet in unUsedClassSetCopy {
    // 过滤系统控件
    let filters = ["NS","UI"]
    var shouldFilter = false
    for filter in filters {
        if aSet.hasPrefix(filter) {
            shouldFilter = true
        }
    }
    // 过滤基类
    if baseClasses.contains(aSet) {
        shouldFilter = true
    }
    
    // 开始过滤
    if shouldFilter {
        unUsedClassFromRecursive.remove(aSet)
    }
}
```

清理了通过这种静态扫描出的无用类，还可以通过运行时来判断类是否被初始化了，从而找出无用类。类运行时是否初始化的这个信息是个布尔值，叫 isInitialized，存储在元类 class_rw_t 结构体的 flags 字段里，在 1<<29 位记录。

完整代码见 ParseOCMethodContent 文件：[MethodTraceAnalyze/ParseOCMethodContent.swift at master · ming1016/MethodTraceAnalyze · GitHub](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/OC/ParseOCMethodContent.swift)


## 在广州做的 SwiftUI 学习笔记分享

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/45.jpg)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/46.jpg)

下面是笔记内容：

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/24.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/25.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/26.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/27.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/28.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/29.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/30.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/31.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/32.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/33.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/34.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/35.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/36.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/37.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/38.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/39.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/40.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/41.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/42.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/43.png)
![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/44.png)

推荐喵神的 SwiftUI 新书，[ObjC 中国 - SwiftUI 与 Combine 编程](https://objccn.io/products/swift-ui)。

这本介绍 Combine 的书也介绍的非常详细：[Using Combine](https://heckj.github.io/swiftui-notes/)

这个网站有大量 SwiftUI 的控件使用范例可以参考：[SwiftUI by Example - free quick start tutorials for Swift developers](https://www.hackingwithswift.com/quick-start/swiftui)

这个博客每篇都是 SwiftUI 相关的，而且更新非常频繁：[Home | Majid’s blog about Swift development](https://swiftwithmajid.com/)


## InfoQ二叉树视频

五分钟的视频，在导演构思下需要一天在四个地方进行拍摄，由于前一天晚上庆功宴喝高了，拍摄当天 iPad 笔也忘带了，头还有些懵。导演中午饭都没吃专门回家拿了他的笔给我用。下午地点安排在央美，先访谈再画一张。北京电影学院毕业14年专业绘画经验的导演贾成斌，在我画时边帮我改画边传授了经验，我觉得这些经验会让我更进一步。

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/17.jpg)

下面是记者剡沛在 InfoQ 上发布的采访内容和视频，原文在：[“创造，就值得被肯定”，一名程序员的艺术人生丨二叉树视频](https://mp.weixin.qq.com/s/Xz2TcGjG14AXr_zmXMwUxg)

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/18.jpg)

他是一名程序员，同时也用自己的业余时间画画。无论是技术分享还是珍藏回忆，他都用画笔记录自己，连接他人。他觉得程序员很酷，无论编程还是画画，都是在创造，这就是最值得肯定的事情。

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/19.jpg)

他在高德负责架构研发工作，也是大家眼中的艺术家，在他身上总能看到那些执念与决心，它们发着光，无时无刻不影响着周围的人。

他就是戴铭，一名酷酷的程序员。

当聊到”连接“这个词的时候，他的眼神异常坚定。

他觉得自己坚持创作，坚持做很多没有门槛的技术分享，很大一部分动力就来自这种渴望，渴望连接自己的过去，也渴望连接他人。

他就是戴铭，一个有点酷，还有点文艺的程序员，在高德地图负责架构研发工作。除了把自己活的很年轻，在他身上总能看到一些发着光的东西。

“是信念吗？”

“是执念。”

### “当漫画家，可能连饭都吃不饱。”

故事的开头，多少有些遗憾。

戴铭最早接触画画，是小学之前报过的一个高阶国画班，因为老师在上海，所以他每画完一张都要寄过去并等待回信，当其中一幅画改到第三遍的时候老师回信说：这孩子可能没什么天赋。因为这件事，当时戴铭心里对画画的渴望，几乎降到了冰点，对于画画的兴趣也就此搁置。

直到六年级的一次美术作业，平时酷爱看漫画的戴铭，才再一次下定决心把自己喜欢的角色搬到纸上。

“同学都说画的太像了，那种被再次肯定的开心，很难忘记。”

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/21.jpg)

后来整个初中，戴铭都在课余时间画漫画，也没再报班，一直到初中毕业戴铭跟父亲说不想上学了，“想去画漫画，做一名漫画家”。不难预料，这个想法并没有得到父亲的支持，“当漫画家，可能连饭都吃不饱”。

但从戴铭的话语中，并没有因为父亲这次选择而听到丝毫气馁，似乎心里的种子已经生根。

“兴趣不是说喜欢漫画，就要去从事漫画。当我们从被动的行为中获得成就感时，也会在无形中培养出兴趣，画画如此，编程也是一样。“

### “我不想让自己投入了生命的热爱，停滞不前。”

“从那后来，就一直在坚持画画了。”

从临摹简单的漫画，到更复杂的画风、更多元的角色，再到临摹写实人物、影视剧照，期间还专门自学过素描，直到现在的再创作，戴铭除了把自己的爱好和回忆画出来，还把自己的专业内容做成漫画，用更容易传达的方式去做每一次技术分享。

“大概是从四、五年前开始，空闲的时候会花很长的时间画画，平时每天也会挤出一个多小时坚持练手，因为我不希望自己热爱的东西，停滞不前，兴趣不该只是兴趣而已。”

后来戴铭接触了数绘，就开始把很多创作留在屏幕上。

“用 ipad 画，更适合我现在的角色，因为可以随时开始和结束，不受环境和工具的影响，另一方面数字绘图也让他的作品在色彩方面，有了更多的提升空间。”

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/22.jpg)

从容地掏出平板，只要自己想，就能随时还原周遭的一切。这种感觉，就跟戴铭看待程序员时的表达一样，“都是很酷的事情，因为无论程序员的人还是艺术家，他们都在创造新的事物，仅这一点，就值得被肯定。”

### “工作不用心的人，生活也不会太精彩”

类似画画这种需要大量时间去“熬”的爱好，坚持总是最难的部分。

“时间永远都是紧缺的，这是肯定。如果工作很忙，就先把时间全部投入到工作上，用最快的速度做好、做完，才能有更多的精力和心情去做其他事情”。

戴铭上一份工作在滴滴，刚入职就希望拓宽自己的能力范围，几乎承担整个部门的研发任务，后来临近发版 Bug 实在解不完，第二天来公司发现都被领导默默解掉了，才意识到一个人的力量始终有限，“一个手指，肯定比不过一个拳头的力量。”

即便如此，戴铭也始终保持着对工作的热血，当时间不够用的时候，他会换个角度去看待问题。

“我觉得工作上面不上心、不拼命的人，生活也不会太精彩。工作是跟每个人的一生切实相关的事情，如果连这个都做不好，又如何能在其他事情上更用心的经营？”

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/23.jpg)

时间看透了，剩下的就是坚持。

当聊到坚持的原动力时，除了用回忆和分享去推动自己，在戴铭身上总散发着一股劲儿。一个兴趣爱好而已，谈信念可能过于悲壮，所以他认为，这股劲儿更像是决心和执念。

有刚入进入滴滴时，想肩扛所有工作的执念；

有为了兴趣上一个台阶，努力获得央美朋友肯定的执念；

也有怕自己的作品破坏了心中的完美角色，重复打磨的执念。

### 结尾

戴铭是很强大的人，他讲过的一段话令人印象深刻：

“幸福是面对过去，恐惧是面对未知的未来。我也忘记是从哪里看到的这句话，但我自己会这样理解：回忆是让人幸福的，未知是令人恐惧的。但如果我们沉湎在回忆中不敢面对未来，幸福始终是有限的，当我们用决心去面对未来，幸福就会越来越多，恐惧也会越来越少。”

裹着决心这把利剑，酷酷的戴铭就这样用代码和画笔勾勒着自己的一生，而画卷展开的部分就已经足够精彩，余下的，定会更值得期待。

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/20.jpg)






























