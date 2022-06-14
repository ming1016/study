---
title: A站 的 Swift 实践
date: 2021-05-22 18:16:12
tags: [iOS, Apple, Swift]
categories: Programming
banner_img: /uploads/acfun-swift-practice/01.png
---

文章已发在快手大前端公众号，欢迎关注，文章地址如下：
* [A站 的 Swift 实践 —— 上篇](https://mp.weixin.qq.com/s/rUZ8RwhWf4DWAa5YHHynsQ)
* [A站 的 Swift 实践 —— 下篇](https://mp.weixin.qq.com/s/EIPHLdxBMb5MiRDDfxzJtA)

新文章写得贼累。完美错过了一览祖国大好人海的机会，TIANROAST🦔咖啡也没喝成，新买Switch怪物猎人崛起也仅限于炎火村。如果喜欢的话，求转发、“在看”和一个大大的赞。

下面是正文内容，我转到博客里来。

## 背景介绍

![](/uploads/acfun-swift-practice/01.png)

AcFun俗称为“A站”，作为一款二次元内容社区产品，以“认真你就输了”为文化导向，倡导轻松欢快的亚文化。AcFun涵盖了中长视频，小视频，番剧，文章等众多内容，支撑这些内容的大部分功能都选择了用Swift开发，早在2019年，AcFun的iOS技术团队就已将Swift作为AcFun app和水母app的开发首选语言。Swift的出现为用户提供了更稳定的使用体验和更快的产品更新节奏，同时也为研发工程师创造了更高效舒适的开发体验。Objective-C已成过去时，AcFun正全面拥抱Swift，驶入iOS开发快车道。

### 苹果推出Swift的原因

谷歌作为苹果最大的竞争对手，除了Android上的Kotlin，还推出了Flutter和Fuchsia里在用的Dart语言，这些语言的口碑和易用性远高于苹果的Objective-C（后面简称OC）。OC历史久远，是C语言的超集，因此其发展受C语言限制。在这样的背景下，大家都以为苹果会忽视其它新语言，但其实苹果对于那些新语言特性垂涎已久，将想法施于行动的是当时还在苹果的_ Chris Lattner_。_Chris_是狂热的编译器和编程语言爱好者，C、C++、OC语言编译器LLVM的创造者，在LLVM开发过程中，Chris对类C语言有着很多不满意的地方，比如预处理器、Trigraphs还有多年积累的奇怪东西。

为了能够兼顾类似React一样的编程范式和具备Java等正流行的语言的优秀特性，Swift经历了长期的ABI稳定和语言特性迭代增加的过程，最终推出了能和JSX声明式UI匹敌的Result Builders，并且通过SwiftUI和Combine这种能极大提升开发效率的框架让开发者收获了惊喜。

可能是Swift的ABI稳定得太晚，不止各大APP里已经积累了大量的OC库和业务代码，苹果系统里的OC占比也依然很高，[_博客《Evolution of the programming languages from iPhone OS 1.0 to iOS 14》 _](https://blog.timac.org/2020/1019-evolution-of-the-programming-languages-from-iphone-os-to-ios-14/)统计了 iOS 历史版本 OC 占比，从文章中可以看到最近的iOS 14版本里OC占比高达88%，C和C++主要用于音视频、电话、网络等比较基础的模块，其占比相对稳定，特别是C并没有明显增加。不过在最近几个版本中，Swift占比持续增高，iOS 14达到了8%，可以看出苹果正在使用Swift重构以前的库。

### 苹果实际采取的行动
为了让广大开发者能够用上更方便安全的Swift，苹果采取了一系列实际行动。比如不再给OC新加接口，而是用Swift替换SDK，WWDC17之后就已经看不到OC的例子了，苹果主推的一些前沿技术，比如AR、AI、Health等，在新版里也都只有Swift版本。所以，在未来的发展中，企业不考虑Swift或是缺少Swift人才，都将会影响到新技术的引入。

另外，苹果的RealityKit、CareKit、Create ML、System、WidgetKit、CryptoKit、Combine、SwiftUI等框架在与OC混编时都非常困难，从这些方面可以看出，苹果所有新开发的框架都在避免和OC产生关系，甚至自WWDC2020起新增加的App Widget只能用SwiftUI开发。

对于苹果一系列的行动，社区与之对应的反应是没有热情去回答OC的Bug了，因为有了更好的追求。OC三方库作者也没有维护的意愿，更新周期比Swift长很多，比如大家都知道的OC网络库AFNetworking，最新版本更新用了2年多时间，而该作者用Swift开发的对应的网络库Alamofire，更新频率接近半个月，作者对Swift的热情可见一斑。

iOS开发首选语言也是Swift，以后可能会面临OC工程师后继无人的局面，物以稀为贵，OC开发者的成本也会大增。使用Swift相关技术栈的团队在吸引人才方面也存在一定优势，AcFun的工程师田赛同学此前选择了快手，而拒绝了另外一家公司的offer，一个重要因素就是AcFun可以使用Swift开发。AcFun的iOS开发工程师关旭航说：“起初我们团队在业务开发中探索Swift时，对Swift不够熟悉，并不敢主动尝试使用，通过组内的培训以及业余时间的学习，我对这门语言越来越感兴趣，看到其他同学写的Swift代码既简洁又易懂，我也慢慢开始尝试使用，现在我已经不想写Objective-C了”。

按照目前这个趋势，使用Swift势在必行。

### Swift在AcFun的演进
2019年AcFun完成了Swift的调研和初期基础设施建设，团队Swift培训以及业务的试点。在Swift调研探索过程中，AcFun开发同学体验到了Swift的优雅、精简以及安全，也经历混编构建时间长和代码补全慢等问题。其中构建问题只要遵循官方Module的最佳实践就可以规避，代码补全问题在Xcode12中得到了很好的改善。2020年上半年AcFun开始了混编工程优化、组件化以及二进制化建设，借LLVM Module抹平模块API在语言上的差异，基础库进行了Module化问题修复，并基于主站二进制化方案，完善了对Swift混编的支持。目前二进制化率为80%，约50%的组件完成了LLVM Module化，构建速度提升了60%以上。

AcFun 当前的 Swift & OC 混编架构如下图所示。Infra层包含自研基础库、快手系中台SDK以及第三方库。Business Support层为各业务Feature提供通用业务支撑。Business Modules层包含当前已完成解耦和Module化的业务模块，模块之间通过依赖注入容器和路由进行通信。当前Main Target中仍然存在尚未解耦的混编代码，OC 和 Swift 之间通过桥接进行交互，另外有一些尚未Module化的OC基础库仍然需要通过Bridging Header桥接给Swift使用。这些桥接是影响编译时间以及代码补全速度的主要因素。

![](/uploads/acfun-swift-practice/02.png)

随着架构的演进和组件化的推进，未来理想目标架构愿景如下图所示。Infra 和 Business Support 层为业务提供更完整的基础和通用业务支撑，业务模块全面解耦、Module化和二进制化，组件均以Module的形式组织和聚合，Main Target 实现壳工程化。

![](/uploads/acfun-swift-practice/03.png)

目前AcFun的Swift文件数占工程总数40%之多，崩溃率减少了52%。AcFun采用混编后，性能方面，比如启动时间、页面流畅度、内存、CPU/GPU负载等方面差别不大。AcFun的QA负责人邵国强不禁感叹：“AcFun的移动端研发同学开始探索Swift时，QA团队起初没有明显感知，但随着研发团队Swift建设的推进，发版频率也提速到单周以后，研发同学能持续高质量交付，真是太棒了。”

Swift的内存管理是通过严格的、确定性的引用计数来自动管理的，可以将内存的使用量降到最低，还可以避免垃圾收集在错误线程使用Finalizer，执行多次不能管理数据库句柄之类资源的问题。ARC的Retain和Release开销在垃圾收集里也会有，比如在存储一个对象属性时用Write Barrier。ARC的算法类似Go的Tricolor算法。垃圾回收还会移动和压缩对象，如果调用C代码，可能还会得到一个Dangling Pointer，比如JNI，就明确需要引入和维护对象，无形中增加了复杂度，还很容易出问题。

在atp播客205期节目中 [_Episode 205: Chris Lattner Interview Transcript_](https://atp.fm/205-chris-lattner-interview-transcript)，Chris Lattner 指出OC之所以不安全的原因是因为OC是基于C语言，有指针，有不完全初始化的变量，会数组越界，即使对工具链和编译器有完全的控制权，也无法很好地解决以上的问题，解决Dangling Pointer就需要解决生命周期问题，而C没有一个框架能解决，改成兼容方式进入系统也是行不通的。因此苹果团队经过思考，决定创建一门“安全”的编程语言，这种安全不止是指没有Bug，而是在保持安全的同时还能够保证高性能，进而推动整个编程模型前进。

Swift消除了整个类别的不安全代码。变量在使用前总是被初始化，数组和整数会被检查是否有溢出，内存会被自动管理，对内存的独占访问可以防止许多编程错误。

Swift有静态调度安全的特性，比C语言更安全，很多问题能在编译时提前发现。代码中发生内存溢出，编译器会发出诊断信息，比如常量中的内存溢出很难查。数组越界检查，还有函数返回可达性检测，确保返回值和函数定义的类型一致。

编译器中的类型安全性可以让问题更早暴露。例如Swift Optional的设计在编译期阻断了空值访问，又如利用范型类型推导在编译期提供约束，从而避免Unsafe Type Casting。水母的研发工程师赵赫在使用Swift过程中，发现代码中的很多问题和隐患都可以在编译期暴露出来，在大部分情况下代码只要能编译通过，运行效果就不会离预期有很大的偏差，这让他对其代码交付质量更加充满信心。

### Swift语言的演进

Swift的演进比较稳定，并没有在初期版本一股脑把特性都加上，而是每个版本迭代增加特性。演进之路如下图所示：

![](/uploads/acfun-swift-practice/04.png)

Swift第一个版本推出了基本语法，Swift2.0主要是将泛型和协议能力做了提升，并对Linux进行了支持，后端框架Vapor和Perfect也是在Swift2.0时出现的，Swift也是在这个版本开源的。Swift3.0出了Swift Package Manager，对标准库API进行了重新的设计。4.0 推出Codable协议和Key path。5.0终于ABI稳定，Swift运行时内置到了iOS12系统里。5.1版本推出了让大家感到苹果活力的SwiftUI和Combine，新增了一大堆围绕提升开发舒适度的Property Wrapper、Opaque Type等语言特性，随之，社区开始异常活跃起来，与之对应的技术文章大量输出。AcFun就使用了5.1版本的Property Wrapper包装了UserDefaults，Codable，RxSwift Relay等，业务开发过程中避免雷同代码的编写。

Swift 6的 [_Roadmap_](https://forums.swift.org/t/on-the-road-to-swift-6/32862)_ _表明了Swift下一步发展方向是优化Swift部署安装，比如LSP和包管理等；丰富开源生态，包括完善标准库，开发类似科学计算这样的新库；围绕开发体验的构建和代码补全提速、丰富诊断信息、稳定调试体验等；DSL能力提升；完善低级别系统编程和机器学习等重要领域的拓展；提供内存所有权和并发等主要语言特性的方案，要做到出色为止。

目前Swift这个项目的负责人叫 [_Ted Kremenek_](https://twitter.com/tkremenek)，斯坦福博士，他之前还是Rust的主力开发。在苹果工作的十年，一个人做了Clang的静态分析器，后面一直管理着Clang和Swift项目，向Chris汇报。Swift项目团队核心成员还有Dave Abrahams（已退出）、John McCall、Doug Gregor、Joe Groff、Saleem Abdulrasool（移植Swift到windows）、Tom Doron（创建SwiftNIO）等，他们的身影活跃在Github的Swift各个提案中。

回到我们身边，国内Swift用的情况怎么样？

一些耳熟能详的App，比如微信、淘宝、百度、支付宝、拼多多、京东、哔哩哔哩、优酷、小红书等都已经开始尝试使用Swift，这些App无一例外都采用了Swift和OC混编开发。由于国内业务竞争压力大，很难像国外公司Uber那样花大半年时间全部用Swift重构，因此如果要在现有工程基础上引入Swift开发，不可避开采用混编开发。很多App使用Swift混编，也是因为苹果对Widget功能开发语言设置了限制，即只能使用Swift，看来苹果公司这个策略是相当有效的。

## 框架选择
而正式进入混编开发前，需要先做开发框架的选型，我们先从架构演进开始说起。

### 架构演进
一般App经过多年发展，架构都会经过如下四个阶段：

![](/uploads/acfun-swift-practice/05.png)


如图所示，App架构从单Module，MVC架构到几百个Module，无依赖，动态跳转。团队从小变大，如今App的架构更偏重高质量、稳定性和高可维护性。苹果公司也是顺应发展趋势，先后推出提高稳定性的Swift语言，而后推出提高可维护性的SwiftUI和Combine。


### SwiftUI
对于一个基于UIKit的项目是没有必要全部用SwiftUI重写的，在UIKit里使用SwiftUI的视图非常容易，UIHostingController是UIViewController的子类，可以直接用在UIKit里，因此直接将SwiftUI视图加到UIHostingController中，就可以在UIKit里使用SwiftUI视图了。

SwiftUI的布局核心是 GeometryReader、View Preferences和Anchor Preferences。如下图所示：

![](/uploads/acfun-swift-practice/06.png)

SwiftUI的数据流更适合Redux结构，如下图所示：

![](/uploads/acfun-swift-practice/07.png)

如上图，Redux结构是真正的单向单数据源结构，易于分割，能充分利用SwiftUI内置的数据流Property Wrapper。UI组件干净、体量小、可复用并且无业务逻辑，因此开发时可以聚焦于UI代码。业务逻辑放在一起，所有业务逻辑和数据Model都在Reducer里。[_ACHNBrowserUI_](https://github.com/Dimillian/ACHNBrowserUI) 和 [_MovieSwiftUI_](https://github.com/Dimillian/MovieSwiftUI) 开源项目都是使用的Redux架构。最近比较瞩目的TCA（The Composable Architecture）也是类Redux/Elm的架构的框架，[_项目地址见_](https://github.com/pointfreeco/swift-composable-architecture)。

提到数据流就不得不说下苹果公司新出的Combine，对标的是RxSwift，由于是苹果公司官方的库，所以应该优先选择。不过和SwiftUI一样，这两个新库对APP支持最低的系统版本都要求是iOS13及以上。那么怎么能够提前用上SwiftUI和Combine呢？或者说现在使用什么库可以以相同接口方式暂时替换它们，又能在以后改为SwiftUI和Combine时成本最小化呢？

对于SwiftUI，AcFun自研了声明式UI Ysera，类似SwiftUI的接口，并且重构了AcFun里收藏模块列表视图和交互逻辑，如下图所示：

![](/uploads/acfun-swift-practice/10.png)

通过上图可以看到，swift代码量相比较OC减少了65%以上，原先使用Objective-C实现的相同功能代码超过了1000行，而Swift重写只需要350行，对于AcFun的业务研发工程师而言，同样的需求实现代码比之前少了至少30%，面对单周迭代这样的节奏，团队也变得更从容。代码可读性增加了，后期功能迭代和维护更容易了，Swift让AcFun驶入了iOS开发生态的“快车道”。

SwiftUI全部都是基于Swift的各大可提高开发效率特性完成的，比如前面提到的，能够访问只给语言特性级别行为的Property Wrapper，通过Property Wrapper包装代码逻辑，来降低代码复杂度，除了SwiftUI和Combine里@开头的Property Wrapper外，Swift还自带类似[_@dynamicMemberLookup_](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md) 和[_@dynamicCallable_](https://github.com/apple/swift-evolution/blob/master/proposals/0216-dynamic-callable.md) 这样重量级的Property Wrapper。还有[_ResultBuilder_](https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md)_ _这种能够简化语法的特性，有些如GraphQL、REST和Networking实际使用ResultBuilder的[_范例可以参考_](https://github.com/carson-katri/awesome-result-builders)。这些Swift的特性如果也能得到充分利用，即使不用SwiftUI也能使开发效率得到大幅提升。

网飞（Netflix）App已使用SwiftUI重构了登录界面，网飞增长团队移动负责人故胤道长记录了SwiftUI在网飞的落地过程，详细描述了[_SwiftUI的收益_](https://mp.weixin.qq.com/s/oRPRCx78owLe3_gROYapCw)。网飞能够直接使用SwiftUI得益于他们最低支持iOS 13系统。


不过如最低支持系统低于iOS 13，还有开源项目[_AltSwiftUI_](https://github.com/rakutentech/AltSwiftUI)_ _也实现了SwiftUI的语法和特性，能够向前兼容到iOS 11。

对于Combine，也有开源实现[_OpenCombine_](https://github.com/OpenCombine/OpenCombine)，目前都未完全实现所有特性。因此，具体在工程中使用还是需要了解Combine的核心原理。

### RxSwift
Combine的灵感来源于RxSwift。RxSwift的核心，这里有份实现了RxSwift核心逻辑的[_简版样例代码_](https://github.com/sergdort/HandMadeRx/tree/master/HandMadeRx.playground/Sources)，可以窥视其核心逻辑。整体流程如下图：

![](/uploads/acfun-swift-practice/08.png)

如上图所示，RxSwift整体流程非常简单，主要就是订阅者和发布者之间进行订阅、发布、取消操作，订阅者会监听和处理这些事件。具体RxSwift数据传递关系如下图：

![](/uploads/acfun-swift-practice/09.png)

上图中的Observable是发布者，Observer是订阅者。取消订阅是通过CompositeDisposable来进行管理，管理方式就是加个中间订阅者来决定是否发送事件给原订阅者。SinkDisposable是一个中间层用来把中间订阅者和原订阅者还有事件转发的逻辑放到一起。新增一个操作符就会新增一个SinkDisposable，比如新增filter操作符就会新增FilterObserver和FilterObservable，如果没有操作符就是AnoymousObserver和AnoymousObservable。订阅是通过Disposer类来管理的，会判断是否完成或者出错，执行Dispose方法。

### Combine

Combine的思路基本和RxSwift一样，只是接口命名不同，这里有份[_表格_](https://github.com/CombineCommunity/rxswift-to-combine-cheatsheet)，列出了Combine和RxSwift功能的对应关系，可以看出目前Combine相较于RxSwift还缺少很多能力，Combine毕竟新生儿，还需要时间成长。但是Combine有个特性是RxSwift没有的，那就是Backpressure，Backpressure可自定义策略控制Subscribe能够接收的数量。

除了SwiftUI和Combine，在Swift开发中还有哪些库是可以直接拿来使用的呢？这里有份 [_Swift开源库的awesome_](https://github.com/matteocrippa/awesome-swift)，在这里可以查缺补漏。AcFun主要使用了Swift开源库有[_Protobuf_](https://github.com/apple/swift-protobuf),_ _[_RxSwift_](https://github.com/ReactiveX/RxSwift), [_Cache_](https://github.com/hyperoslo/Cache), [_Observable_](https://github.com/slazyk/Observable-Swift)。

以上，为《A站 的 Swift 实践》的上篇内容，下篇我们会继续详细介绍OC和Swift是怎么混编的，以及Swift的动态性。

## 如何混编

昨天刚刚结束的Google I/O让人想起了Kotlin在三年前曾经上过一次热搜，Google I/O官宣Kotlin替代Java，正式成为Android开发的首选语言。正所谓演进的力量，这一切都要归功于苹果公司在2014年推出的Swift替代了Objective-C，成为iOS乃至苹果全平台首选的开发语言，从而提高了iOS开发者的热情。上篇介绍了Swift的技术背景以及如何选择开发框架。下篇的内容会介绍大多数以OC为主体的工程如何与Swift共舞，以及如何利用Swift动态性解决工程难题。

![](/uploads/acfun-swift-practice/11.png)

如果你的工程是OC开发的，要用上Swift就需要进行OC和Swift的混编开发。

然而，混编开发应该怎么开始呢？有没有什么前置条件？

### 前置条件

混编本质上就是把OC语法的声明通过编译工具生成Swift语法的声明，这样Swift就可以通过生成的声明直接调用OC接口。反之，OC调用Swift接口也可以通过相同的方法，把Swift语法的声明生成OC语法的头文件。这些转换生成的编译工具都集成在开发工具Xcode里。

Xcode其实就是执行多命令行的工具，比如Clang、ld等等。Xcode、Project文件里包含了这些命令的参数和它们执行的顺序，也有所有待编译文件和它们的依赖关系。[_llbuild_](https://github.com/apple/swift-llbuild/)是低等级构建系统，根据Xcode Project里的配置按顺序执行命令。命令行工具的参数配置是在Xcode的Build Settings里进行设置的。如果是在同一个Project里混编，首先需要将Build Settings里Always Embed Swift Standard Libraries设置为YES，然后在桥接文件，也就是ProductName-Bridging-Header.h里导入需要暴露给Swift的OC类。如果Swift要调用的OC在不同Project里，则需要将OC的Project设置为Module，将Defines Module设为YES，再把Module里的头文件导入到OC Modulemap文件里的Umbrella Header里。

### 如何设置CocoaPods

Swift Pod的Podspec需要写明对OC Pod的依赖。在工程Podfile中，OC Pod后面要写 :modular_headers => true。开启Modular Header就是把Pod转换为Module。那CocoaPods究竟做了什么？执行  Pod Install -- Verbose就可以看到，在生成Pod Targets时，CocoaPods会生成Module Map File和Umbrella Header。

每个工程设置的情况千奇百怪，而CocoaPods主要是通过自己的dsl配置来完成这些编译参数的设置，所以就需要先了解些混编设置的编译参数和概念：

- 前面提到的Defines Module，需要设置为YES。
- Module Map File表示 Module Map的路径。
- Header Search Paths代表Module Map定义的OC头文件路径。
- Product Module Name的默认设置和Target Name一样。
- Framework Search Paths是设置依赖Framework的搜索路径。
- Other C Flags可以用来配置依赖其它Module文件路径。
- Other Swift Flags可以配置其Module Map文件路径。

CocoaPods的主要组件有解析命令的[_CLAide_](https://github.com/CocoaPods/CLAide)_、_用来解析Pod描述文件，比如Podfile、Podfile.lock和PodSpec文件的[_Cocoapods-core_](https://github.com/CocoaPods/Core)_、_拉仓库代码和资源的[_Cocoapods-downloader_](https://github.com/CocoaPods/cocoapods-downloader)_、_分析依赖的[_Molinillo_](https://github.com/CocoaPods/Molinillo)_、_以及创建和编辑Xcode的.xcodeproj和.xcworkspace文件的[_Xcodeproj_](https://github.com/CocoaPods/Xcodeproj)。在执行了Pod Install以后，组件调用流程以及配置Module所处流程位置，如下图所示：

![](/uploads/acfun-swift-practice/12.png)

按照上图的逻辑，Integrates这一步主要是用来配置Module的。先检查Targets，主要是对于包括Swift版本和Module依赖等问题的检查，然后再使用Xcodeproj组件做Module的工程配置。

完成以上工作后，如果我们想要在Swift里使用OC开发的库FMDB，就可以直接使用Import来导入，代码如下：

```swift
import UIKit
import FMDB

class SwiftTestClass: NSObject {
    var db:FMDB.FMDatabase?

    override init() {
        super.init()
        self.db = FMDB.FMDatabase(path: "dbname")
        print("init ok")

    }
}
```

可以看到，Import FMDB将FMDB的Module倒入进来后，接口依然能够直接使用Swift语法调用。

这里需要注意的是，Module依赖的Pod也需要是Module。因此改造时需要从底向上地改造成Module。另外，开启Module后，如果某个头文件在Umbrella Header里，那么其它包含这个头文件的Pod也需要打开Module。

### 为什么要用Module？

在Module被使用之前，开发者们需要对要导入的C语言编译器处理方式类头文件进行预处理，查找头文件里还导入了哪些头文件，递归直到找到全部头文件。但是，预处理的方式会遇到许多问题。其一，编译的复杂度高且耗时长，这是因为每个可编译的文件都会单独编译进行预处理，所以在预处理过程中递归查找导入头文件的工作会重复很多次，尤其是当包含关系很深的头文件被很多.m所导入的时候；其二，会出现宏定义冲突时需要重新排序以及和解依赖的问题等。

Module相对来说更加简易，它的头文件只需要解析一次，所以编译的复杂度会指数级降低，且编译器对Module的处理方式和C语言的预处理方式是完全不同的。编译器会将要编译的文件导入的头文件生成二进制格式，存储在Module Cache中，编译时如果碰到需要导入模块时，会先检查Module Cache，有对应的二进制文件就直接加载，没有才会解析，以此来保证Module解析只有一次。重新解析编译Module只会发生在头文件包含的任何头文件有变动，或者依赖另外一个模块有更新的时候。比如下面的代码：

```swift
#import <FMDB/FMDatabase.h>
```

Clang会先从FMDB.framework的Headers目录里查找FMDatabase.h，再去FMDB.framework的Modules目录里查找module.modulemap文件，分析module.modulemap来判断FMDatabase.h是否是模块的一部分。Module Map用来定义Module和头文件之间的关系。FMDB.framework的module.modulemap的内容如下：

```ruby
framework module FMDB {
  umbrella header "FMDB-umbrella.h"

  export *
  module * { export * }
}
```

想要确定FMDatabase.h是否是Module的一部分就要看module.modulemap里的Umbrella Header文件，即FMDB-umbrella.h目录里是否包含了FMDatabase.h。在Headers目录里查看FMDB-umbrella.h文件，内容如下：

```objectivec
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabasePool.h"
#import "FMDatabaseQueue.h"
#import "FMDB.h"
#import "FMResultSet.h"

FOUNDATION_EXPORT double FMDBVersionNumber;
FOUNDATION_EXPORT const unsigned char FMDBVersionString[];
```

上面代码中可以看到FMDatabase.h已经包含在文件中，因此Clang会将FMDB作为Module导入。Umbrella框架是对框架的一个封装，目的是隐藏各个框架之间的复杂依赖关系。构建完的Module会被存放到 ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/ 这个目录下面。

Clang编译单个OC文件是通过导入头文件方式进行的，而Swift没有头文件，所以Swift编译器Swiftc就需要先查找声明，再来生成接口。除此之外，Swiftc还会在Module Map文件和Umbrella Header文件中暴露的声明里查找OC声明。

如果工程要构建二进制库，需要支持Swift 5.1加的Module Stability和Library Evolution。

### Name Mangling

找到OC声明后，Swiftc就需要进行Name Mangling。Name Mangling的作用在一方面是会像C++那样防止命名冲突，另外一方面是会对OC接口命名进行Swift风格化重命名。如果对Name Mangling命名的效果不满意，还可以回到OC源码中用NS_SWIFT_NAME重新定义想要在Swift使用的名字。

Swiftc的Name Mangling相比较于C和C++的Name Mangling会生成更多信息，比如下面的代码：

```swift
public func int2string(number: Int) -> String {
    return "\(number)"
}
```

Swiftc编译后，使用nm -g查看生成如下的信息：

```swift
0000000000003de0 T _$s8demotest10int2string6numberSSSi_tF
```

如上所示，信息中的$s表示全局，8demotest的demotest是Module名，8是Module名的长度。int2string是函数名，前面的10是类名长度，6number是参数名。SS表示参数类型是Int。Si表示的是String类型，_tF表示前面的Si是返回类型。

接下来对比一下Clang和Swiftc的编译过程，首先是Clang的编译过程，如下图：

![](/uploads/acfun-swift-practice/13.png)

其次是Swift的编译过程，如下图：

![](/uploads/acfun-swift-practice/14.png)

从两者的对比中可以看出，Swift编译过程缺少了头文件，因为它通过分组编译模糊了文件的概念，减少了很多重复查找声明的工作，这样不仅仅可以简化代码的编写，还可以给编译器更多的发挥空间。

至于OC怎样调用Swift接口，Swiftc会生成一个头文件，代码中有Public的声明会先按文件生成Swiftmodule，文件链接完会合并Swiftmodule，最后整体生成到一个头文件里。过程如下图所示：

![](/uploads/acfun-swift-practice/15.png)

### 为什么可以调OC接口？

Swift代码之所以可以调OC接口，是因为OC的接口会被编译器自动生成为Swift语法接口文件。在Xcode中，在OC头文件中点击左上角的 Related Items，选择Generated Interface，就可以选择查看生成的Swift版本接口文件。自动转换成的Swift接口文件可以直接供Swift调用，在转换过程中，编译器会将NSString这种OC的基础库转换成Swift里对应的String、Date等Swift库。OC的初始化方法也会被转换成Swift的构造器方法。错误处理也会被转换成Swift风格。下面是OC和Swift转换对应的类型：

![](/uploads/acfun-swift-practice/16.png)

但是，仅仅只依赖于编译器的转换肯定是不够的，为了能让Swift调用得更加舒服，还需要对OC接口做些修改适配，比如将函数改成使用OC泛型，NSArray paths转成Swift是open var paths:[Any]；如果使用了泛型，将其改成 NSArray paths，那对应的Swift就是open var paths:[KSPath]，这种接口Swift使用起来会更方便有效。

苹果公司也提供了一些宏来帮助生成好用的Swift接口。

众所周知，OC之前一直缺少是非空的类型信息，可以通过 NS_ASSUME_NONNULL_BEGIN和NS_ASSUME_NONNULL_END包起来，这样就不用逐个去指定是非空了。NS_DESIGNATED_INITIALIZER宏可以将初始化设置为Designated，不加这个宏为Convenience。NS_SWIFT_NAME用来重命名Swift中使用的名称，NS_REFINED_FOR_SWIFT可以解决数据不一致的问题。

在iOS开发的过程中不可避免地需要访问 Core Foundation 类型，Core Fundation框架一旦导入到Swift混编环境中，它的类型就会被自动转为Swift类，Swift也会自动管理Annotated Core Foundation对象的内存，而不用像在OC中那样手动调用CFRetain、CFRelease或者CFAutorelease函数。Unannotated的对象会被包装在一个Unmanaged结构里，比如下面的代码：

```objectivec
CFStringRef showTwoString(CFStringRef s1, CFStringRef s2)
```

转成Swift就是：

```swift
func showTwoString(_: CFString!, _: CFString!) -> Unmanaged<CFString>! {
    // ...
}
```

如上面代码所示，Core Fundation 类型的名字转换后会去掉后缀Ref，这是因为在Swift中所有类都是引用类型，Ref后缀比较多余。上面的Unmanaged结构有两个方法，一个是takeUnretainedValue()，另一个是takeRetainedValue()，这两个方法都是用来返回对象的原始未封装类型。如果对象之前没有Retain就用takeUnretainedValue()，已经Retain了，就用takeRetainedValue()。

在Swift里用getVaList(_:_:_:) 或withVaList(_:_:) 函数调用C的Variadic函数，比如 vasprintf(_:_:_:)。

调用指针参数的C函数，和Swift映射如下图：

![](/uploads/acfun-swift-practice/17.png)

Swift也有无法调用的C接口，比如复杂的宏、C风格的Variadic参数，复杂的Array成员等。简单赋值的宏会被转换成Swift里的常量赋值，对于复杂的宏定义，编译器无法自动转换，如果还是想享受宏带来的好处，比如可以避免重复输入大量模板代码和避免类型检查约束，可以通过函数和泛型替换获取同样的好处。

Swift写出来的Module也可以给OC来调用。但是这样的调用会有很多限制，因为Swift中有很多类型是没法给OC用的，比如在Swift里定义的枚举、Swift定义的结构体、顶层定义的函数、全局变量、Typealiases、Nested类型，但是如果绕过这些类型，Swift也变得不那么Swift了。

即使是实现了混编，开发者们还需要面对许多难题。因为在OC时代的很多问题，例如Hook，无痕埋点等可以在OC运行时很方便地实现，而Swift却缺少天然的支持。下面介绍一下Swift的动态性，在官方完善前，我们应该怎么使用它。

## 动态性

Swift在处理纯粹的Swift语言时是有自己的运行时的，但是对于“这个运行时是不提供访问的接口”的问题，Swift核心团队不是不做动态特性，而是因为如果想要支持动态特性就需要处理虚函数表（Virtual Method Table）的动态调用对SIL函数优化的影响，比如类没有被Override就会自动优化到静态调用，而这需要大量的时间。现阶段还有优先级更高的事情要做，比如并发模型、系统编程、静态分析支持类型状态等。因此，有人选择自己去实现一套Swift运行时，使得Swift代码具有动态特性。[_Jordan Rose_](https://twitter.com/UINT_MIN)实现了一个[_精简版的Swift_](https://belkadan.com/source/ppc-swift-project/tree/refs/heads/dev:/stdlib/_Runtime)运行时，更加严谨的运行时实现可以参考[_Echo_](https://github.com/Azoy/Echo)和[_Runtime_](https://github.com/wickwirew/Runtime)。

有人可能会问，SwiftUI的Preview不就是典型的在运行时替换方法的吗？他是怎么做到的呢？其实他使用的是@_dynamicReplacement属性，这是一个可以直接拿着用来进行方法替换的内部使用属性。

```swift
@_dynamicReplacement(for: runSomething())
static func _replaceRunSomething() -> String {
    "replaced"
}
```

如果想要把上面的代码放到一个库中，并且在运行时加载这个库进行运行时方法替换可以通过这样的方式：

```swift
runSomething()

let file = URL(fileURLWithPath: "/path/of/replaceLib.dylib")

guard let handle = dlopen(file.path, RTLD_NOW) else {
    fatalError("oops dlopen failed")
}

runSomething()
```

除了这个方法以外，还有其他办法可以进行运行时的方法替换吗？

### 值类型的方法替换

通过 AnyClass和class_getSuperclass方法可以查看Swift对象的继承链，没有继承NSObject的Swift类，会有一个隐含的Super Class，这个类会带有一个生成的带前缀的SwiftObject，比如_TtCs12_SwiftObject。Swift是实现了NSObject的一个objc运行时的类型，这个类型不能和OC交互。但是如果继承了NSObject就可以和OC交互。

如果方法或属性声明了 @objc dynamic，那么就可以在运行时通过动态派发在Swift对象上去调用，方法是：使用AnyObject的Perform方法去执行NSSelectorFromString里传入的方法或属性名。

对于Swift里的值类型，比如Struct、Enum、Array等，可以遵循_ObjectiveCBridgeable协议，经过Type Casting（显示或隐式）转成对应的OC对象类型。举个例子，如果想要查看Array的类继承关系，代码如下：

```swift
func classes(of cls: AnyClass) -> [AnyClass] {
    var clses:[AnyClass] = []
    var cls: AnyClass? = cls
    while let _cls = cls {
        clses.append(_cls)
        cls = class_getSuperclass(_cls)
    }
    return clses
}
let arrays = ["jone", "rose", "park"]
print(classes(of: object_getClass(arrays)!))
// [Swift.__SwiftDeferredNSArray, Swift.__SwiftNativeNSArrayWithContiguousStorage, Swift.__SwiftNativeNSArray, __SwiftNativeNSArrayBase, NSArray, NSObject]
```

如上面代码所示，Swift的Array最终都是继承自NSObject，其它值类型也类似。可以看出，所有Swift类型都是可兼容objc运行时的。因此可以给这些值类型添加objc运行时方法，代码如下：

```swift
// MARK: 为Swift类型提供动态派发的能力
struct structWithDynamic {
    public var str: String
    public func show(_ str: String) -> String {
        print("Say \(str)")
        return str
    }
    internal func showDynamic(_ obj: AnyObject, str: String) -> String {
        return show(str)
    }
}
let structValue = structWithDynamic(str: "Hi!")
// 为 structValue 添加Objc运行时方法
let block: @convention(block)(AnyObject, String) -> String = structValue.showDynamic
let imp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
let dycls: AnyClass = object_getClass(structValue)!
class_addMethod(dycls, NSSelectorFromString("objcShow:"), imp, "@24@0:8@16")
// 使用Objc动态派发
_ = (structValue as AnyObject).perform(NSSelectorFromString("objcShow:"), with: String("Bye!"))!
```

如上面代码所示，取出函数闭包可以通过 @convertion(block)转换成C函数Call Convention来调用，C函数也可以直接去执行这个指针。使用 Memory Dump 工具可以查看Swift函数内存结构，以及解析出符号信息DL_Info。Memory Dump工具有Mikeash的[_memorydumper2_](https://github.com/mikeash/memorydumper2)，源码解读可以参考[_Swift Memory Dumping_](https://www.mikeash.com/pyblog/friday-qa-2014-08-29-swift-memory-dumping.html)。逆向查看内存布局可以参考[_《初探Swift Runtime：使用Frida实现针对Alamofire的抓包工具》_](https://github.com/neil-wu/FridaHookSwiftAlamofire/blob/master/howto.md)
__

### 类的方法替换

在运行时进行类方法的替换时，先将方法的Block以AnyObject类型传入imp_implementationWithBlock方法，返回一个imp，然后使用 class_getInstanceMethod 来获取实例的原方法，再通过 class_replaceMethod 进行方法替换，完整代码可以参看[_InterposeKit_](https://github.com/steipete/InterposeKit)，另外还有一个使用libffi的方法替换库，参见[_SwiftHook_](https://github.com/623637646/SwiftHook)。

另外，通过获取函数地址来改变函数指向位置的方法在Swift里实现比较困难，这是因为NSInvocation不可用了，因此需要通过C的函数来Hook Swift。在Swift的AnyClass中有类似OC的布局，记录了指向类和类成员函数的数据，这样就可以使用汇编来做函数指针替换的事情。思路是：保存寄存器，调用新函数，然后恢复寄存器，还原函数。具体可以参考项目[_SwiftTrace_](https://github.com/johnno1962/SwiftTrace)。

### 插桩

使用编译插桩的方式也可以实现运行中的方法替换，关键步骤在于编译时，需要使用DYLD_INSERT_LIBRARIES进行拦截，CommandLine.arguments可以得到Swiftc的执行参数，以查找待编译的Swift文件。通过苹果公司的[_SwiftSyntax_](https://github.com/apple/swift-syntax)源代码解析、生成和转换的工具可以查出所有方法，并插入特定的方法替换逻辑代码。修改完通过-output-file-map来获取mach-o的地址去覆盖先前产物。使用self.originalImplementation(...)调用原始的实现作为闭包传入execute(arguments:originalImpl:)方法。

### ClassContextDescriptorBuilder

Swift运行时给每个类型保留了Metadata信息。Metadata是由编译器静态生成的，有了Metadata的调试才能够发现类型的信息。Metadata偏移-1是Witness table 指针，Witness Table 提供分配、复制和销毁类型的值，Witness Table 还记录了类型大小、对齐、Stride等其它属性。Metadata偏移量0的地方是Kind字段，其描述了Metadata所描述的类型的种类，例如Class、Struct、Enum、Optional、Opaque、Tuple、Function、Protocol等类型。这些类型的Metadata具体详述可见[_Type Metadata 的官方文档_](https://github.com/apple/swift/blob/main/docs/ABI/TypeMetadata.rst)，代码描述可以在[_include/swift/ABI/MetadataValues.h_](https://github.com/apple/swift/blob/3ed11125f3e987722c14c10ac9c1c7ec25a86c65/include/swift/ABI/MetadataValues.h)里看到。比如在Metadata里类的方法数量会比实际代码里写的方法数量要多，那是因为编译器会自动生成一些方法，这些方法的种类在MethodDescriptorFlags类中Kind里描述了，代码如下：

```swift
enum class Kind {
    Method,
    Init,
    Getter,
    Setter,
    ModifyCoroutine,
    ReadCoroutine,
};
```

可以看到，Getter、Setter以及线程相关读写的ModifyCoroutine、ReadCoroutine类型都是自动生成的。

Class的内存结构生成方法可以在[_/lib/IRGen/GenMeta.cpp_](https://github.com/apple/swift/blob/3ed11125f3e987722c14c10ac9c1c7ec25a86c65/lib/IRGen/GenMeta.cpp)里找到：

- ClassContextDescriptorBuilder这个类是用来生成Class内存结构的，它继承于TypeContextDescriptorBuilderBase。
- Enum、Struct等类型的内存结构Builder基类都是继承于ContextDescriptorBuilderBase的TypeContextDescriptorBuilderBase。
- ContextDescriptorBuilderBase 是最基础的基类，Module、Extension、Anonymous、Protocol、Opaque Type、Generic都是继承于它。
- Struct的Metadata和Enum的Metadata共享内存布局，Struct会多个指向Type Context Descriptor的指针。

内存布局指的是使用一个Struct或者Tuple，根据每个字段的大小和对齐方式决定怎样来安排内存中的字段，在这个过程中，不仅需要描述清楚每个字段的偏移量，还有Struct或Tuple整体的大小和对齐方式。下面就是GenMeta里和Class类型相关的内存方法代码：

```cpp
// 最底层基类 ContextDescriptorBuilderBase的布局方法
void layout() {
  asImpl().addFlags();
  asImpl().addParent();
}

// TypeContextDescriptorBuilderBase的布局方法
void layout() {
  asImpl().computeIdentity();

  super::layout();
  asImpl().addName();
  asImpl().addAccessFunction();
  asImpl().addReflectionFieldDescriptor();
  asImpl().addLayoutInfo();
  asImpl().addGenericSignature();
  asImpl().maybeAddResilientSuperclass();
  asImpl().maybeAddMetadataInitialization();
}

// ClassContextDescriptorBuilder的布局方法
void layout() {
  super::layout();
  addVTable();
  addOverrideTable();
  addObjCResilientClassStubInfo();
  maybeAddCanonicalMetadataPrespecializations();
}
```

根据GenMeta可以看到Swift的Class类型内存布局是根据ContextDescriptorBuilderBase、TypeContextDescriptorBuilderBase再到ClassContextDescriptorBuilder继承层层叠加的，因此对应Class类型的Nominal Type Descriptor就可以用如下C结构来描述：

```c
struct SwiftClassInfo {
    uint32_t flag;
    uint32_t parent;
    int32_t name;
    int32_t accessFunction;
    int32_t reflectionFieldDescriptor;
    ...
    uint32_t vtable;
    uint32_t overrideTable;
    ...
};
```

代码中可见，add的前缀就是增加的偏移记录，addFlags后面的addParent就是下一个偏移的记录。FieldDescriptor换成ReflectionFieldDescriptor是苹果公司在5.0版本对Metadata做的改变，官方Mirror反射目前还不完善，有些信息还没法提供，因此在Metadata里增加了一些反射相关信息。

OC动态调用方法会把_cmd作为第一个参数，第二个参数是Self，后面是可变参数列表，动态调度可以在运行时添加类、变量和方法。而在Swift中动态调用方法是基于VTable的，运行时没法对方法进行动态搜索，地址在编译时静态写在了VTable里，运行时不能改，可以用静态地址调用，或dlsym来搜索名称。

VTable的地址在TypeContextDescriptor之后，OverrideTable存储位置在VTable之后，有三个字段来描述，第一个是记录哪个类被重写，第二个是被重写的函数，第三个是用来重写的函数相对的地址。因此通过OverrideTable就可以找到重写前和重写后函数指针，这样就有机会在VTable里找到对应函数进行函数指针的替换，达到Hook的效果。要注意，在Swift编译器设置优化时VTable的函数地址可能会清空或使用直接地址调用，这两种情况发生的话就没法通过VTable进行方法替换。

那么还有其它思路吗？

### Mach_override

使用[_Wolf Rentzsch_](https://github.com/rentzsch)写的[_Mach_override_](https://github.com/rentzsch/mach_override)也是一种方法，可以在原始函数的汇编里加个jmp，跳到自定义函数，然后再跳回原始函数。Mach_override_ptr的三个参数分别是，一，要覆盖函数的指针；二，去覆盖函数的指针；三，参数可以设置为原函数的指针地址，待Mach_override_ptr返回成功，就可以调原函数。Mach_override会分配一个虚拟内存页，使其可写可执行。需要注意的是，Mach_override_ptr初始函数和重入函数指针相同，调用后，重入函数将调用替换函数而不是原始函数。在Swift中如何使用Mach_override可参考[_SwiftOverride_](https://github.com/lombax85/SwiftOverride)。

## 总结

通过上下篇的介绍，想必你已经了解到A站为拥抱Swift都做了哪些事情。基于A站以及快手主站的一些架构师对于Swift的热爱，以及为之付于的实践，A站的开发体验才得以蜕变。

为了让OC开发同学能够掌握Swift，以更“Swift”的方式进行开发，A站组织了十多次Swift组内的培训和分享，并规范了Swift代码风格和静态检查流程。针对开发体验上的痛点，A站在2020年上半年就开始了混编工程的优化、组件化以及二进制化的建设。完成了分层设计，渐进式地将模块解耦下沉到对应的分层，进而可以借助LLVM Module来抹平模块API在语言上的差异，从而代替Swift和Objective-C在主工程的桥接，为10+ A站和中台的基础库进行了Module化问题修复，并基于主站的二进制化方案 （GUNDAM）完善了对Swift以及混编的支持。从Swift ABI Stability进化为Module Stability的XCFramework，WWDC的[_Session_](https://developer.apple.com/videos/play/wwdc2019/416/)很好的说明XCFramework的原理，同时表示XCFramework格式对Objective-C/C/C++也有很好的支持。目前组件的二进制化率约为80%，约有50%的组件已经完成了LLVM Module化，构建时间提升了60%以上。随着Swift优势的逐渐体现以及团队Swift能力建设的推进，A站更多的工程师开始倾向于使用Swift进行业务开发，而Swift带来的“加速度”，也让技术团队切实地感受到了强烈的“推背感“。

当然，A站也曾遇到一些Swift的Bug，比如打包RxSwift5后遇到模块名和类名一样所产生的Bug和[_Issue_](https://bugs.swift.org/browse/SR-12647)，RxSwift6通过避免使用Typealias的类型曲线形地解决了这个问题，目前此问题已被官方标记为“解决”，后面的版本可以正常使用。另外还有两个未解决的问题，一个是在Module的接口中出现Ambiguous Type Name Error问题，参考[_Issue_](https://bugs.swift.org/browse/SR-12646)_；_另一个是Import后产生.swiftinterface出现的错误，参见网站[_Issue_](https://bugs.swift.org/browse/SR-11422)。

最后想说的是，Swift开发并不容易，不要被Swift简洁的语法所迷惑，各种大小括号组合会让开发者们感到困惑，还有一些特性会让直观理解变得很困难，比如下面的代码：

```swift
let str:String! = "Hi"
let strCopy = str
```

根据Swift类型推导的特性，按道理str类型加上感叹符号后，strCopy就会被自动推导为非可选String类型。但实际情况是，按照[_官方文档_](https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html)的说法，strCopy没有直接指明类型，即隐式可选值时，str类型是String后加上感叹号，这种是属于隐含解包可选值String无法推导出非可选String类型，因此Swift会先将strCopy作为一个普通可选值来用，这样和直观的感觉非常不一样。

本以为5.0的ABI在稳定后，Swift学起来会更容易，但是其实新的SwiftUI和Combine这样重量级的框架需要开发者继续钻研，真是“Write Swift, Learn Every Year”。Swift不断从其它语言中吸取精髓，接下来的async/await，你准备好了吗？要用上，先得看咱家APP系统最低版本是不是能够支持这些新特性。

虽说不容易，但为了稳定和效率，终究跟上了时代的步伐。
































