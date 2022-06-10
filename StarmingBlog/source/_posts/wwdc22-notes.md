---
title: WWDC22 笔记
date: 2022-06-10 12:13:57
tags: [iOS, Apple, Swift]
categories: Programming
---

## 第一天

今年是 WWDC 的第39个年头了。今年的 WWDC.playground 活动()是 SwiftGG、T 沙龙和老司机技术一起会和社区开发者们一起聊聊这次 WWDC。WWDC.playground 活动在节日期间每天都会有直播，我会和 61、13 他们参加 6月11日晚上8点那场直播。

下面我整理了一份今年 WWDC 的指南，也算提供个方便的入口吧。

1. [WWDC22 直播地址](https://www.apple.com/apple-events/)、[微博直播](https://m.weibo.cn/p/2318180003_4873_423)、[WWDC22 YouTube 地址](https://www.youtube.com/watch?v=q5D55G7Ejs8)
2. [Apple WWDC22 页面](https://developer.apple.com/wwdc22)
3. [Apple WWDC22 指南](https://developer.apple.com/news/?id=v5kliro5)
4. [Apple Developer app](https://apps.apple.com/us/app/apple-developer/id640199958) 观看 Session 的 Apple 出的 App。
5. [Session 网页版](https://developer.apple.com/wwdc22/sessions/)
6. [Digital Lounge](https://developer.apple.com/wwdc22/digital-lounges/) 注册感兴趣的主题，到时候就可以和 Apple 工程师在 Slack 上一起看 Session，交流。
7. [Labs](https://developer.apple.com/wwdc22/labs/) 可以获得和 Apple 专家一对一指导。6号 keynote 完后就可以开始预约。
8. [Beyond WWDC22](https://developer.apple.com/wwdc22/beyond-wwdc/) 和去年一样，这里是 Apple 制作的世界各地的社区活动。
9. [weak self Discord WWDC22 Keynote Watch Party](https://discord.com/invite/YseNtkGS) 全球最多听众的 iOS 中文 Podcast 之一 weak self 的活动。
10. [Swiftly Rush WWDC22](https://www.swiftlyrush.com/category/wwdc22/)
11. [iOS Feeds 的 WWDC 2022 新闻聚合](https://iosfeeds.com/wwdc22)
12. [WWWDC.io App](https://wwdc.io/) 社区的看 Session 的 App。
13. Keynote 后的 Platforms State of the Union 这个主题是对后面一周 Session 的总结，开发者可以重点关注下。
14. [WWDC Notes](https://www.wwdcnotes.com/) 汇聚了大家的 Session 笔记，可以快速看到各个 Session 的重点。
15. [Technologies](https://developer.apple.com/documentation/technologies) 这里是 Apple 框架 API 分类地址，看完 Session 可以直接在这里找对应 API 的更新。还有个网站 [Apple Platform SDK API Differences](http://codeworkshop.net/objc-diff/sdkdiffs/) 会列出新 SDK 里有哪些框架更新了。
16. [Apple Design Awards 提名作品](https://developer.apple.com/design/awards/)

Apple Design Awards 提名作品，我先列几个我喜欢的：

1. procreate
2. Wylde Flowers
3. 笼中窥梦
4. Gibbon: Beyond the Trees
5. Vectornator: Design Software
6. Wylde Flowers
7. Behind the Frame
8. MD Clock - Live in the present
9. 专注面条
10. Townscaper

## 第二天

![](/uploads/wwdc22-notes/01.png)

今天最让我印象深刻是 M2、Lock screen widgets、Stage manager、Swift Charts、WeatherKit、SwiftUI Navigation API、只要一个 1024x1024 App Icon、Sticky headers on Xcode scrolling、Xcode View Debugger 可以用于 SwiftUI 了，还有 iOS 16 原生的支持 Nintendo Switch Pro 手柄了。

后面我将更多内容使用点对点的分发，可以用 [Planet](https://www.planetable.xyz/) 关注，我的 IPNS 是：k51qzi5uqu5dlorvgrleqaphsd1suegn8w40xwhxl0bgsyxw3zerivt59xbk74

Keynote 要点：

- iOS 16
  - new lock screen
  - live activities
  - extend focus to lock screen
  - forcus filter for apps
  - dictation improvements
  - live text in video
  - visual lookup
  - maps
    - multistop routing
    - transit(add card to wallet)
    - new details
    - lookaround api
  - iCloud shared photo library
  - persanalized spatial audio
  - quick notes on iPhone
  - fitness app without watch
  - messages
    - edit messages
    - delete messages
    - mark as unread
    - share play
  - pay
    - tap to pay on iPhone
    - order tracking
  - carplay
    - widgets
    - more personalization
    - multi-screen
  - safety check
    - quickly remove access for others
  - home
    - introduce matter as new standard
    - redesign of app
- M2
  - 15.8 trillion operations per seconds
  - 10-core GPU
  - macbook air and macbook pro 13”
  - better and faster
  - silent design
  - fast charge
  - new colors
  - magsafe
  - audio jack
- macOS Ventura
  - improved spotlight
  - undo send and more
  - shared tab groups
  - passkeys
  - desk view
  - stage manager
  - continuity for facetime
  - use iPhone as camera on macbook
- iPadOS 16
  - weather app
  - WeatherKit
  - collaborations api
  - freeform board
  - stage manager
- WatchOS 9
  - four new watch faces
  - new ShareKit api
  - improved metrics for running
  - heart rate zones
  - create custom workouts


重要的几个信息：

- [Platforms State of the Union](https://developer.apple.com/videos/play/wwdc2022/102/) 汇总 WWDC22 技术的 Session，必看。
- [iOS 16 新 API 和功能](https://developer.apple.com/ios/) Apple 的整理。
- [New Technologies WWDC22](https://developer.apple.com/documentation/New-Technologies-WWDC22) Apple 整理的 WWDC22 上的新技术。
- [WWDC22 Sample Code](https://developer.apple.com/sample-code/wwdc/2022/)  
- [iOS and iPadOS 16 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-16-release-notes) 系统接口更新说明，包括 SwiftUI 更新了啥。
- [下载 Xcode 14 beta](https://developer.apple.com/download/applications/) 直接在开发者官方下载地方下。7个G，这次做了裁剪，手表和电视都做成了可选。
- [Webkit 大量更新](https://webkit.org/blog/12824/news-from-wwdc-webkit-features-in-safari-16-beta/)


大赞的库：

- [SwiftUI 更新介绍](https://developer.apple.com/xcode/swiftui/)
- [Swift Charts](https://developer.apple.com/documentation/Charts) 今年 WWDC 的惊喜。Swifty Rush 的文章介绍 [Swift Charts with SwiftUI](https://www.swiftlyrush.com/swift-charts-with-swiftui/)。
- Navigation API 又一个惊喜。从以前的 Navigation 迁移到新 API 的文档说明 [Migrating to New Navigation Types](https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types?changes=latest_minor)。可以看 [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack?changes=latest_minor) 、[NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)。相关 Session 是 [The SwiftUI cookbook for navigation](https://developer.apple.com/videos/play/wwdc2022/10054/)。Natalia Panferova 的文章的介绍 [Overview of the New SwiftUI Navigation APIs](https://nilcoalescing.com/blog/SwiftUINavigation2022/)
- macOS Window 支持，等到了。参看这个示例 [Bringing multiple windows to your SwiftUI app](https://developer.apple.com/documentation/swiftui/bringing_multiple_windows_to_your_swiftui_app)。
- [RegexBuilder](https://developer.apple.com/documentation/RegexBuilder)  构建正则表达式的 DSL
- Live Text API
- [Weatherkit 指南](https://developer.apple.com/weatherkit/get-started/) 每月在 500k 次调用内是免费。
- [RoomPlan 接口文档](https://developer.apple.com/documentation/RoomPlan) 用摄像头扫描物理环境，创建房间的 3D 模型。[Introducing RoomPlan](https://developer.apple.com/augmented-reality/roomplan/) 介绍 RoomPlan。
- [Spatial](https://developer.apple.com/documentation/spatial) 轻量 3D 数学库。
- Passkey (FIDO) 原理和 Web3 钱包核心逻辑差不多。
- DriverKit 安全的 USB 和 PCI 硬件设备连接到 iPad 的库。

好用的功能和组件：

- [UICalendarView](https://developer.apple.com/documentation/uikit/uicalendarview) 日历视图
- [BADownloadManager](https://developer.apple.com/documentation/backgroundassets/badownloadmanager) 下载队列管理器。
- [backgroundTask(_:action:)](https://developer.apple.com/documentation/swiftui/scene/backgroundtask(_:action:)?changes=latest_minor) 
- ImageRenderer 将 View 生成图片。
- presentationDetents 优秀。示例 [Using Presentation Detents in SwiftUI](https://www.swiftlyrush.com/using-presentation-detents-in-swiftui/)
- [String Index 升级](https://github.com/apple/swift-evolution/blob/main/proposals/0180-string-index-overhaul.md)

一些方便上手的例子：

- [Configuring a multiplatform app](https://developer.apple.com/documentation/Xcode/configuring-a-multiplatform-app-target) 单代码，多平台 in Xcode 14。
- [Food Truck: Building a SwiftUI multiplatform app](https://developer.apple.com/documentation/swiftui/food_truck_building_a_swiftui_multiplatform_app/) 示例了 NavigationSplitView、Layout、Chart 和 WeatherKit 的运用。


一些感兴趣的 Session：

- [Session 按主题分类](https://developer.apple.com/wwdc22/topics/)
- [What’s new in Swift](https://developer.apple.com/videos/play/wwdc2022/110354/)
- [Swift Session、Lab 和 Digital Lounges 合集](https://developer.apple.com/wwdc22/topics/swift/) Apple 专门为 Swift 制作的 WWDC22 页面。
- [Visualize and optimize Swift concurrency](https://developer.apple.com/videos/play/wwdc2022/110350/)
- [Link fast: Improve build and launch times](https://developer.apple.com/videos/play/wwdc2022/110362/) 构建和启动加快
- [Demystify parallelization in Xcode builds](https://developer.apple.com/videos/play/wwdc2022/110364/)
- [Create macOS or Linux virtual machines](https://developer.apple.com/videos/play/wwdc2022/10002/)

## 第三天

![](/uploads/wwdc22-notes/02.jpg)
![](/uploads/wwdc22-notes/03.jpg)

WWDC.playground 很精彩，怎么感觉昨天的 WWDC.playground 像是听了一期枫言枫语呢。预感 11 号可能会变成为一期 weak self 呢。

昨天老司机还整理了份 WWDC22 Session 观看介绍的[列表](https://wwdc-reference.feishu.cn/wiki/wikcnXl4ioToZuW4yvfAqUoNQFS?sheet=Lqblfd&table=tblGVOzKgFhVpBWg&view=vewysxfUqf)

Apple 出的内容看不够的话，可使用 [Follow WWDC 2022 News!](https://iosfeeds.com/wwdc22) 来看最新的 WWDC 相关的社区文章。

下面是我今天的一些记录。

### Xcode
代码补全的更新。以前多个可选参数的体验很差，这次输入参数比如 frame 里的 maxWidth，会只显示当前要补全的参数。而且速度快了很多。

以前是编完源码再生成 module，然后 link编好的文件，最后再 link。现在整个过程改成并行执行，同时 link 还快了两倍。结果是比以前快了25%，核越多效果越明显。还有可可视化整个过程。

多平台以前是多个 tagets，现在是在一个 target 里管理。

Hangs 是官方线上主线程被卡了的检查工具，在 Organizer 里查看对应问题堆栈也很方便。

当然最爱的还是 sticky headers，秒杀其它编辑器 （虽然我还是觉得 Emacs 最好，由于会暴露年龄，一般我都不说）。

还有内存也好了很多，总体来说，这次 Xcode 更新很棒。

完整 [Xcode release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes) 

### WidgetKit
WidgetKit 将 WatchOS 上的 Circular、Rectangle 还有 Inline 带到了 iOS 和其他平台。

### WeatherKit
安全方便获得用户位置信息，只用于天气。

### VisionKit
Live Text API，感觉这类库都是为了以后出眼镜做铺垫的。

### macOS
macOS 支持window，menuBar也支持了。

### Swift
distrubuted actor 更安全，还可以在设备间（`本地设备<->本地设备`，`本地设备<->服务器`）进行通信保护。

泛型新语法 some 和 any 关键字写起来真的简化了很多。

Swift 的更新了什么，除了 Session 外，还可以参看 Paul Hudson 这篇文章 [What’s new in Swift 5.7](https://www.hackingwithswift.com/articles/249/whats-new-in-swift-5-7) ，还有 Donny Wals 的这篇 [What’s the difference between any and some in Swift 5.7?](https://www.donnywals.com/whats-the-difference-between-any-and-some-in-swift-5-7/) 。

### SwiftUI
SwiftUI里没有用属性包装的属性也能够和视图变化绑定了。

关于 SwiftUI 的更新，Paul Hudson 写了很多例子 [What’s new in SwiftUI for iOS 16](https://www.hackingwithswift.com/articles/250/whats-new-in-swiftui-for-ios-16) 。

Reda Lemeden 整理了 WWDC22 SwiftUI 的所有相关内容 [SwiftUI @ WWDC 2022](https://redalemeden.com/collections/swiftui-2022/) 。可见社区对 SwiftUI 热情依然是最高的。

### SPM
Swift Package Plugin，本来用其他语言，比如 ruby 、python 或 shell 做的事情，现在可以通过 Swift 语言来完成了，写的 plugin 还可以方便的在 Xcode 中使用。

### 虚机
使用 Virtualization 框架，享受 Rosetta 2 的优势，运行 x86-64 Linux 系统。

Apple 出虚机可运行 Linux 系统这点可以看得出 Apple 对开源的拥抱，原因还有一点是 Swift 也可以用在 Linux 服务器上了，Apple 用心良苦，也是想让开发者用本打算买其它硬件的钱来买 Apple 的硬件吧，更好的榨干 Apple 硬件过于优秀的性能，如同新出 Stage Manager 通过投到大屏来榨干 M1 的 iPad 性能。 不光是这样，还有文件，也就是存储设备也只需要一份了，更方便，还有苹果特有的 Trackpad 和 Magic mouse 也能够用于 Linux 系统中。

虚机运行 Linux 和 macOS 的区别是，启动 Linux 使用的是 EFI Boot Loader 来加载 Linux 文件，VirtioGraphicDevice 进行 Linux 系统图形界面的设置和渲染。使用Rosetta 运行 Linux 系统，运行 Linux 就是比其它虚机要快。

介绍的 session [Create macOS or Linux virtual machines](https://developer.apple.com/wwdc22/10002) ，代码说明 [Running GUI Linux in a virtual machine on a Mac](https://developer.apple.com/documentation/virtualization/running_gui_linux_in_a_virtual_machine_on_a_mac)，相关主题 [Virtualization](https://developer.apple.com/documentation/virtualization)

## 第四天

![](/uploads/wwdc22-notes/04.png)

今晚五神会现身 WWDC.playground 。内容涉及 SwiftUI 和 AR，不要错过。

### 今日零散记录

从 Apple 推出 WeatherKit 可以看出，Apple 喜欢把关键和有想象空间盈利价值的技术掌握在自己手上，WeatherKit 提供大量数据，包括分钟、小时、每日预报，还有提前警报，这些信息的商业价值本就很大。

今天看了 WeatherKit、Swift Chart 还有 SwiftUI 的 Layout，感觉 Apple 的接口设计能力很值得学习，可能具备了这些能力才能更好地沟通。

swift-algorithms 可以使用 .indexed() 来替代 zip。

Federico Zanetello 对 Platforms State of the Union 这个 Session 做的[笔记](https://www.wwdcnotes.com/notes/wwdc22/102/) 。

应用层面，今天还有好多 Swift Chart 的介绍。

### Layout
Grid、Layout、ViewThatFits、AnyLayout，特别是 Grid 还统一了 HStack 和 VStack。这些布局方式，让先前复杂的要借助 GeometryReader，且容易出错的布局有了更易的写法。Layout 协议可以为 layout 创建自定义属性，另外布局计算也会被缓存。

### Link
[Link fast: Improve build and launch time](https://developer.apple.com/videos/play/wwdc2022/110362/) 详细讲了 Apple 今年怎么改进了 link，思路很棒，很值得学习。

Static linking 和 Dynamic linking ，也就是静态链接和动态链接。

静态链接就是链接各个编译好的源文件以及链接源文件和编译好的库文件，通过将函数名放到符号表，链接新文件时确定先前是否有包含的 undefined 符号，给函数的数据指令分配地址，最后生成一个有 TEXT、DATA、LINKEDIT 段的可执行文件。

今年 Apple  通过利用多核优势让静态链接快了两倍。

具体做法是，并行的拷贝文件内容。并行构建 LINKEDIT 段的各个不同部分。并行改变 UUID 计算和 codesigning 哈希。然后是提高 exports-trie 构建器的算法。使用最新的 Crypto 库利用硬件加速的优势加速 UUID 计算。提高其它静态库处理算法库，debug-notes 生成也更快了。

Apple 推荐静态库最佳实践是：

使用 `-all_load` 或 `-force_load` 可以让 .a 文件像 .o 文件那样并行处理，不过开启这个选项需要先处理重复的符号。另外一个副作用是会将一些被判断无用的代码也被链接进来，使包体变大，因此开启之前可以先使用静态分析工具分析处理，这个过程定期做就行，不用放到每次编译过程中。演讲者推荐使用 `-dead_strip` 选项，但是这样做并没有真实去掉费代码，以后这些代码还是会被编译分析，如果只是暂时不用，可以先注释掉。

使用 `-no_exported_symbols` 选项。链接器生成的 LINKEDIT 段的一部分是 exports trie，这是一个前缀树，对所有导出的符号名称、地址和标志进行编码。动态库 是会导出符号的，但运行的二进制文件其实是不用这些符号的，因此可以用 `-no_exported_symbols` 选项来跳过 LINKEDIT 中 trie 数据结构的创建，这样链接起来就快多了。如果程序导出符号是一百万个，这个选项就可以减少 2 到 3 秒的时间。但需要注意的是，如果要加载插件链接回主程序就需要所有的导出的 trie 数据，无法用这个选项。

另外一个是 `-no_deduplicate` 选项。先前 Apple 给链接器加了个 pass 用来合并函数的指令相同，函数名不相同，这个 pass 会对每个函数的指令进行递归散列，用这种方式来找重复指令，这样做比较费 CPU，由于调试时其实是不需要关注包大小，因此可以加上 `-no_deduplicate` 选项来跳过这个 pass。

这些选项在 Xcode 的 Other Linker Flags 里进行设置即可。

动态库也就是 dylib，其它平台就是 DSO 或 DLL。 动态链接器不是将代码从库里考到主二进制里，而是记录某种承诺，记录从动态库中使用符号名称，还有库路径。这样做好处就是好复用动态库，不用拷贝多份。虚拟内存看到多进程使用相同动态库，就会重新给这个动态库用相同的物理内存页。

动态库好处是构建快了，启动加载慢了，多个动态库不光要加载，还要在启动时链接。也就是把链接成本从本地构建换到了用户启动时。动态库还有个缺点是基于动态库的程序会有更多的 dirty 页，因为静态链接时会把全局数据放到主程序同一个 DATA 页中，动态库的话，每个都在自己的 DATA 页中。

动态库工作的原理是，可执行的二进制会有不同权限的段，至少会有 TEXT、DATA 和 LINKEDIT。分段总是操作系统页大小的倍数。TEXT 段有执行的权限，CPU 可以将页上的字节当做机器代码指令。运行时，dyld 会根据每个段权限将可执行文件 mmap() 到内存，这些段是页大小和页对齐的，虚拟内存系统可以直接将程序或动态库文件设置为 VM 范围的备份存储。在这些页的内存访问前是不会被加载到 RAM 里，就会触发一个页 fault，导致 VM 去读取文件的子范围，将内存填充到需要 RAM 页中。光映射不够，还要用某种方式“wired up”或绑到动态库上。比如要调用动态库上的某个函数，会转换成调用 site，调用 site 成为一个在相同 TEXT 段合成的 sub 的调用，相对地址在构建时就知道了，就意味着可以正确的形成 BL 指令。这样做的好处是，stub 从 DATA 加载一个指针并跳到对应的位置，不用在运行时修改 TEXT 段，dyld 只在运行时改 DATA 段。dyld 所进行的修改很简单，就是在 DATA 段里设置了一个指针而已。

当 dyld 或应用程序的指针指向自己时要 rebase，ASLR 使 dyld 以随机地址加载动态库，内部指针不能在构建时设置，dyld 在启动时 rebase 这些指针，磁盘上，如果动态库在地址零出被加载，这些指针包含它们的目标地址。LINKEDIT 需要记录的就是每个重定位的位置。然后，dyld 只需将动态库的实际加载地址添加到每个 rebase 位置。还有种修改方式是绑定，绑定就是符号引用，符号存储在 LINKEDIT 中，dyld 在动态库的 exports tire 中找实际地址，然后 dyld 将该值存储在绑定指定的位置。

今年 Apple 发布了一个新的修改方式 chained fixups。较前面两种的优势就是可以使 LINKEDIT 更小。新格式只存储每个 DATA 页中第一个 fixup 位置和一个导入的符号列表。其它信息编码到 DATA 段。iOS 13.4 就开始支持了。

下面先说下 dyld 原理介绍。

dyld 从主可执行文件开始，解析 mach-o 找依赖动态库，对动态库进行 mmap()。然后对每个动态库进行遍历并解析 mach-o 结构，根据需要加载其它动态库。加载完毕，dyld 会查找所有需要绑定符号，并在修改时使用这些地址。最后修改完，dyld 自下而上运行初始化程序。先前做的优化是只要程序和动态库，dyld 很多步骤都可以在首次启动时被缓存。

今年 Apple 做了更多的优化，这个优化叫 page-in linking，就是 dyld 在启动时做的 DATA 页面修改放到 page-in 时，也可以理解为懒修改。以前，在 mmap() 区域的某些页面中第一次使用某些地址会触发内核读入该页面。现在如果它是一个数据页，内核会应用改页需要的修改。这种机制减少了 dirty 内存和启动时间。意味着 DATA_CONST 也是干净的，可以像 TEXT 页一样被 evicted 和重新创建，以减少内存压力。需要注意的是 page-in linking 只用于启动，dlopen() 不支持。你看，Apple 优化启动的思路也是按需加载。

Apple 还提供了追踪 dyld 运行情况的 dyld_usage 工具。检查磁盘和 dyld 缓存中的二进制文件的 dyld_info 工具。

### 今日推荐 Session
除了 link 外，还有 [Meet distributed actors in Swift](https://developer.apple.com/videos/play/wwdc2022/110356/) 也是比看的，Mike Ash 和 Doug Gregor 一年的心血就在这了。

## 第五天

![](/uploads/wwdc22-notes/05.png)

### 性能
性能的 [Improve app size and runtime performance](https://developer.apple.com/videos/play/wwdc2022/110363) Session 值得一看。

今年苹果通过更有效的检查 Swift 协议，使 OC 消息发送调用更小，使 autorelease elision 更快更小这几个个方面来让 App 体积更小，性能更高。

Swift 协议检查。

一个协议通过 as 操作符检查传递值是否符合协议，这种检查会在编译器的构建时间被优化掉，所以往往需要在运行时借助之前计算协议检查元数据来看对象是否真的符合了协议。一些元数据是在编译时建的，但还有很多元数据只能在启动时建立，特别是使用泛型时。协议多了，会增加耗时，差不多会多一半启动时间。

今年 Apple 推出新的 Swift 运行时，可以提前计算 Swift 协议元数据，作为 App 可执行文件和它在启动时使用的任何动态库的 dyld 闭包的一部分。这个是在系统上的，因此，只要是使用了今年最新系统的 App 都会享受这个优化，可以理解为，新系统上启动老 App 也会快些。

消息发送。

Xcode 14 中新的编译器和链接器已经将 ARM64 的消息发送调用从 12 字节减少到 8 字节。因此如果你的 App 都是 OC 代码的话，使用 Xcode 14 编出来的二进制文件可以少 2%。老系统也有效。

使用 objc_stubs_small 选项可以只优化大小，获得最大的大小优化。objc_msgSend 调动有 8 个字节指令，也就是2个指令是专门用来准备 selector 的，对于任何特定的 selector，总是相同的代码，由于始终是相同的代码，那么就可以对其共享，每个 selector 只 emit 一次，而不是每次发送消息时都 emit。共享这段代码地方是一个叫 selector stub 的函数。

ARC 会在编译器插入大量的 c 的 retain/release 函数调用。这些调用遵守平台应用二进制接口（ABI）所定义的 c 语言 call convention。也就意味着我们要更多代码来完成这些调用，用来传递正确寄存器的指针。Apple 今年推出了自定义的 call convention 根据指针位置，适时使用正确变量而不用移动它，从而摆脱了调用里的多余代码。Apple 果然是坚持用户体验优先，为了更好体验不惜修改 c 的 ABI。

autorelease elision 。

App 今年对 objc 运行时进行了修改，使 autorelease elision 更小更快。deployment target 为 iOS 16 今年新系统时才可享用哦。

Apple 怎么做的呢？

ARC 在调用方插入一个 retain，在被调用的函数中插入一个 release。当我们返回我们的临时对象时，我们需要在函数中先释放它，因为它要离开 scope。在它还没有任何其它引用时还不能这么做，不然返回前他就会被销毁。Apple 现在使用一个新的 convention ，让其可以返回临时对象。做法是当返回一个自动释放值，编译器会发出一个特殊标记，这个标记会告诉运行时这是符合自动释放条件的。它的后面是 retain，我们会在后面执行。获取返回地址，也就是一个指针，将它先保存起来，然后离开运行时的自动释放调用。在运行时，可以将保留时得到的指正和先前做自动释放时保存的指针进行比较，这样标记指令不再是数据之间的比较，比较指针内存访问少。比较成功就可以省去 autorelease/retain。

autorelease elision 的优化同样也可以减少 2% 大小。感谢 Apple 为了用户和开发者 OKR 的付出。

### SwiftUI
new navigation api，看完感觉我做的小册子还有幻灯应用要花些时间好好改改了。

接下来，有活干了。

### WWDC.playground

明天的 WWDC.playground 嘉宾有谜底科技和 weak self，欢迎来捧场。







































