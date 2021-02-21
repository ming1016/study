---
title: 用 Swift 编写的工程代码静态分析命令行工具 smck
date: 2017-04-01 22:00:31
tags: [smck, Swift, iOS]
categories: Programming
---
## 前言
最近几周在用 swift 做一个命令行工具 smck 用来对现有 OC 工程的代码做些分析和处理。日后工程切换成 Swift 可以加上对 Swift 工程代码的支持。昨天看到喵神在微博上说他下周要直播 live coding 一个 swift 的命令行工具，传送门： [现场编程 - 用 Swift 创建命令行工具 fengniao-cli Part1](http://m.quzhiboapp.com/?liveId=391&fromUserId=12049#!/intro/391) ，其实蛮期待。想想跟喵神挺有缘的，最近下了他开发的 iOS 应用 Mail Me，随时能够记录工作和准备讲座时一些灵感，smck 的一些实现还有模块的设计灵感也是通过这个应用随时记录了下来呢，所以也推荐大家使用，真心方便。还有先前 Segmentfault 邀请我这个月31号在他们的直播平台上做个讲座，传送门： [深入剖析 iOS 编译 Clang / LLVM - 戴铭 - SegmentFault 讲堂](https://segmentfault.com/l/1500000008514518) ，先前写过一篇文章，直播可能更利于演示和详细说明一些细节吧。看来这段时间我要跟喵神做好多类似的事情了。smck 的代码今天已经放到了 Github 上，地址：https://github.com/ming1016/smck

## smck 可以做哪些事情呢？
* 简单的比如命名规则的检查，按照团队标准来，如所有继承 UIViewController 的命名末尾统一成 VC，继承 JSONModel 的命名末尾统一成 Model，还有特定功能基类的子类按照一定的命名规则来。
* 再比如查找所有中文字符串列出每个字符串分别使用在哪个控件上。
* 根据类是否被初始化或直接调用等规则检查来分析哪些类从来没有调用过来判断是否是没有用的类。
* 对工程质量的检查，比如 NSString，block，NSArray 的属性检查否是为 copy，还有 protocol 是否为 weak，Array 的操作是否使用具有安全操作的 Category 来做等等。
当然需要检查分析和处理的肯定不止这些，所以在 smck 这个程序设计成了一种非常利于添加各种检查功能模块的结构，通过简单的代码编写每个人或团队都可以方便编写添加各种 checker。

## 是怎么做到简单编写就能够添加功能呢？
因为代码分析的过程会通过一系列已经编写好的 parser 来完成，parser 会完成 token 的分析和上下文还有工程全局分析输出所有节点的数据信息，根据这些完整的信息和已经定义好的一系列具有完整包含关系的结构体就能够进行各种各样功能的定制化了。下面是一些 parser 和功能介绍：

![parser](https://github.com/ming1016/smck/blob/master/README/5.png?raw=true)
* ParsingMethod.swift ：会返回 Method 结构体，包含了方法名，各个参数，方法内使用过的方法，方法内定义的临时变量等信息。
* ParsingMethodContent.swift ：会分析方法内的 token 根据语法形成数组结构进行处理。这里需要处理的东西很多，目前还在根据计划添加更多的数据输出。
* ParsingMacro.swift ：处理宏定义，主要是输出 token 给其它 parser 来处理。
* ParsingImport.swift ：返回 Import 结构体，包含引入的类名，包名
* ParsingProperty.swift ：会分析定义的属性 Property 信息
* ParsingInterface.swift ：会根据这个分析出一个文件中定义了多少各类，类的结构体 Object 里类名，父类名，类别名会在这里解析出。
* ParsingProtocol.swift ：会将分析出的协议设置到 Object 结构体中。
* ParsingObject.swift ： 目前主要是分析出使用过的类的信息。

生成的 File 结构体里面套装各个子结构体，断点如图：
![结构体](https://github.com/ming1016/smck/blob/master/README/6.png?raw=true)
## 如何调试 smck？
先填上对应的命令行参数和值，设置参数参考下图。然后运行即可。
![命令行参数](https://github.com/ming1016/smck/blob/master/README/2.png?raw=true)
## 导出成命令行工具
在 Xcode 里选择 Product - Archive - Export 即可，如图：
![导出](https://github.com/ming1016/smck/blob/master/README/3.png?raw=true)
执行
```bash
./smck -o /User/your_project_path
```
输出如下
![执行效果](https://github.com/ming1016/smck/blob/master/README/4.png?raw=true)
## 如何编写自己的检查功能？
由于工程检查规则非常多样化，所以需要编写一些 Plugin，后面我会逐渐抽出一些具有共性的放上来，目前在 Plugin 目录下我放了两个例子，在例子里可以看出来怎么通过订阅 Parser 输出的不同节点的不同数据来进行不同的检查。在控制台管理相关的 Checker 类里关联 Parser 和 Plugin 的代码由于使用了 RxSwift 也变得非常简洁明了，如下：
```swift
func doO(path:String) {
    guard path.characters.count > 0 else {
        return
    }
    UnUseObjectPlugin().plug(ob: ParsingEntire.parsing(path: path))
}
```