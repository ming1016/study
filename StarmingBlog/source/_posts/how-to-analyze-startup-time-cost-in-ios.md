---
title: 如何对 iOS 启动阶段耗时进行分析
date: 2019-12-07 09:25:33
tags: [Swift, iOS]
categories: Programming
---

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/01.png)

## 前言
启动优化一役后，超预期将所负责的 App 双端启动的耗时都降低了65%以上，iOS 在iPhone7上速度达到了400毫秒以内。就像产品们用后说的，快到不习惯。由于 App 日活用户过亿，算一下每天为用户省下的时间，还是蛮有成就感的。

![](/uploads/how-to-analyze-startup-time-cost-in-ios/01.jpeg)

## 启动阶段性能多维度分析
要优化，先要做到的是对启动阶段各个性能纬度做分析，包括主线程耗时、CPU、内存、I/O、网络。这样才能够更加全面的掌握启动阶段的开销，找出不合理的方法调用。启动越快，更多的方法调用就应该做成按需执行，将启动压力分摊，只留下那些启动后方法都会依赖的方法和库的初始化，比如网络库、Crash 库等。而剩下那些需要预加载的功能可以放到启动阶段后再执行。

启动有哪几种类型，启动有哪些阶段呢？

启动类型分为：

* Cold：App 重启后启动，不在内存里也没有进程存在。
* Warm：App 最近结束后再启动，有部分在内存但没有进程存在。
* Resume：App 没结束，只是暂停，全在内存中，进程也存在。

分析阶段一般都是针对 Cold 类型进行分析，目的就是要让测试环境稳定。为了稳定测试环境有时还需要找些稳定的机型，对于 iOS 来说iPhone7性能中等，稳定性也不错就很适合，Android 的 Vivo 系列也相对稳定，华为和小米系列数据波动就比较大。除了机型外控制测试机温度也很重要，一旦温度过高系统还会降频执行影响测试数据。有时候还会置飞行模式采用 Mock 网络请求的方式来减少不稳定的网络影响测试数据。最好时重启后退 iCloud 账号，放置一段时间再测，更加准确些。

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/05.png)

了解启动的阶段目的就是聚焦范围，从用户体验上来确定哪个阶段要快，以便能够让用户可视和响应用户操作的时间更快。

简单来说 iOS 启动分为加载 Mach-O 和运行时初始化过程，加载 Mach-O 会先判断加载的文件是不是 Mach-O，通过文件第一个字节，也叫魔数来判断，当是下面四种时可以判定是 Mach-O 文件：

* 0xfeedface 对应的 loader.h 里的宏是 MH_MAGIC
* 0xfeedfact 宏是 MH_MAGIC_64
* NXSwapInt(MH_MAGIC) 宏 MH_GIGAM
* NXSwapInt(MH_MAGIC_64) 宏 MH_GIGAM_64

Mach-O 分为主要分为 中间对象文件（MH_OBJECT）、可执行二进制（MH_EXECUTE）、VM 共享库文件（MH_FVMLIB）、Crash 产生的 Core 文件（MH_CORE）、preload（MH_PRELOAD）、动态共享库（MH_DYLIB）、动态链接器（MH_DYLINKER）、静态链接文件（MH_DYLIB_STUB）、符号文件和调试信息（MH_DSYM）这几种。确定是 Mach-O 后，内核会 fork 一个进程，execve 开始加载。检查 Mach-O Header。随后加载 dyld 和程序到 Load Command 地址空间。通过 dyld_stub_binder 开始执行 dyld，dyld 会进行 rebase、binding、lazy binding、导出符号，也可以通过 DYLD_INSERT_LIBRARIES 进行 hook。dyld_stub_binder 给偏移量到 dyld 解释特殊字节码 Segment 中，也就是真实地址，把真实地址写入到 la_symbol_ptr 里，跳转时通过 stub 的 jump 指令跳转到真实地址。 dyld 加载所有依赖库，将动态库导出的 trie 结构符号执行符号绑定，也就是 non lazybinding，绑定解析其他模块功能和数据引用过程，就是导入符号。

Trie 也叫数字树或前缀树，是一种搜索树。查找复杂度 O(m)，m 是字符串的长度。和散列表相比，散列最差复杂度是 O(N)，一般都是 O(1)，用 O(m)时间评估 hash。散列缺点是会分配一大块内存，内容越多所占内存越大。Trie 不仅查找快，插入和删除都很快，适合存储预测性文本或自动完成词典。为了进一步优化所占空间，可以将 Trie 这种树形的确定性有限自动机压缩成确定性非循环有限状态自动体（DAFSA），其空间小，做法是会压缩相同分支。对于更大内容，还可以做更进一步的优化，比如使用字母缩减的实现技术，把原来的字符串重新解释为较长的字符串；使用单链式列表，节点设计为由符号、子节点、下一个节点来表示；将字母表数组存储为代表 ASCII 字母表的256位的位图。

尽管 Trie 对于性能会做很多优化，但是符号过多依然会增加性能消耗，对于动态库导出的符号不宜太多，尽量保持公共符号少，私有符号集丰富。这样维护起来也方便，版本兼容性也好，还能优化动态加载程序到进程的时间。

然后执行 attribute 的 constructor 函数。举个例子：

```c
#include <stdio.h>

__attribute__((constructor))
static void prepare() {
    printf("%s\n", "prepare");
}

__attribute__((destructor))
static void end() {
    printf("%s\n", "end");
}

void showHeader() { 
    printf("%s\n", "header");
}
```

运行结果：

```c
ming@mingdeMacBook-Pro macho_demo % ./main "hi"
prepare
hi
end
```

运行时初始化过程 分为：

* 加载类扩展
* 加载 C++静态对象
* 调用+load 函数
* 执行 main 函数
* Application 初始化，到 applicationDidFinishLaunchingWithOptions 执行完
* 初始化帧渲染，到 viewDidAppear 执行完，用户可见可操作。

过程概括起来如下图：

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/02.png)

也就是说对启动阶段的分析以 viewDidAppear 为截止。这次优化之前已经对 Application 初始化之前做过优化，效果并不明显，没有本质的提高，所以这次主要针对 Application 初始化到 viewDidAppear 这个阶段各个性能多纬度进行分析。多维度具体包含内容如下图：

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/03.png)

工具的选择其实目前看来是很多的，Apple 提供的 System Trace 会提供全面系统的行为，可以显示底层系统线程和内存调度情况，分析锁、线程、内存、系统调用等问题。总的来说，通过 System Trace 你能清楚知道每时每刻 App 对系统资源使用情况。

System Trace 能查看线程的状态，可以了解高优线程使用相对于 CPU 数量是否合理，可以看到线程在执行、挂起、上下文切换、被打断还是被抢占的情况。虚拟内存使用产生的耗时也能看到，比如分配物理内存，内存解压缩，无缓存时进行缓存的耗时等。甚至是发热情况也能看到。

System Trace 还提供手动打点进行信息显式，在你的代码中 导入 sys/kdebug_signpost.h 后，配对 kdebug_signpost_start 和 kdebug_signpost_end 就可以了。这两个方法有五个参数，第一个是 id，最后一个是颜色，中间都是预留字段。

Xcode11开始 XCTest 还提供了测量性能的 Api。苹果在2019年 WWDC 启动优化专题 [Optimizing App Launch - WWDC 2019 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2019/423/) 上也介绍了 Instruments 里的最新模板 App launch 如何分析启动性能。但是要想达到对启动数据进行留存取均值、Diff、过滤、关联分析等自动化操作，App launch 目前还没法做到。

### 主线程耗时
多个维度性能纬度分析中最重要，最终用户体感到的是主线程耗时分析。对主线程方法耗时可以直接使用[Messier - 简单易用的Objective-C方法跟踪工具 - everettjf - 首先很有趣](https://everettjf.github.io/2019/05/06/messier/)
生成 trace json 进行分析，或者参看这个代码[GCDFetchFeed/SMCallTraceCore.c at master · ming1016/GCDFetchFeed · GitHub](https://github.com/ming1016/GCDFetchFeed/blob/master/GCDFetchFeed/GCDFetchFeed/Lib/SMLagMonitor/SMCallTraceCore.c)，自己手动 hook objc_msgSend 生成一份Objective-C 方法耗时数据进行分析。还有种插桩方式，可以解析 IR（加快编译速度），然后在每个方法前后插入耗时统计函数。文章后面我会着重介绍如何开发工具进一步分析这份数据，以达到监控启动阶段方法耗时的目的。

hook 所有的方法调用，对详细分析时很有用，不过对于整个启动时间影响很大，要想获取启动每个阶段更准确的时间消耗还需要依赖手动埋点。为了更好的分析启动耗时问题，手动埋点也会埋的越来越多，也会影响启动时间精确度，特别是当团队很多，模块很多时，问题会突出。但，每个团队在排查启动耗时往往只会关注自己或相关某几个模块的分析，基于此，可以把不同模块埋点分组，灵活组合，这样就可以照顾到多种需求了。

### CPU
为什么分析启动慢除了分析主线程方法耗时外，还要分析其它纬度的性能呢？

我们先看看启动慢的表现，启动慢意味着界面响应慢、网络慢（数据量大、请求数多）、CPU 超负荷降频（并行任务多、运算多），可以看出影响启动的因素很多，还需要全面考虑。

对于 CPU 来说，WWDC 的 [What’s New in Energy Debugging - WWDC 2018 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2018/228/) 里介绍了用 Energy Log 来查 CPU 耗电，当前台三分钟或后台一分钟 CPU 线程连续占用80%以上就判定为耗电，同时记录耗电线程堆栈供分析。还有一个 [MetrickKit](https://developer.apple.com/documentation/xcode/improving_your_app_s_performance) 专门用来收集电源和性能统计数据，每24小时就会对收集的数据进行汇总上报，Mattt 在 NShipster 网站上也发了篇文章[MetricKit - NSHipster](https://nshipster.com/metrickit/)专门进行了介绍。那么 CPU 的详细使用情况如何获取呢？也就是说哪个方法用了多少 CPU。

有好几种获取详细 CPU 使用情况的方法。线程是计算机资源调度和分配的基本单位。CPU 使用情况会提现到线程这样的基本单位上。task_theads 的 act_list 数组包含所有线程，使用 thread_info 的接口可以返回线程的基本信息，这些信息定义在 thread_basic_info_t 结构体中。这个结构体内的信息包含了线程运行时间、运行状态以及调度优先级，其中也包含了 CPU 使用信息 cpu_usage。获取方式参看 [objective c - Get detailed iOS CPU usage with different states - Stack Overflow](https://stackoverflow.com/questions/43866416/get-detailed-ios-cpu-usage-with-different-states)。GT [GitHub - Tencent/GT: GT (Great Tit) is a portable debugging tool for bug hunting and performance tuning on smartphones anytime and anywhere just as listening music with Walkman. GT can act as the Integrated Debug Environment by directly running on smartphones.](https://github.com/Tencent/GT) 里也有获取 CPU 的代码。

整体 CPU 占用率可以通过 host_statistics 函数可以取到 host_cpu_load_info，其中 cpu_ticks 数组是 CPU 运行的时钟脉冲数量。通过 cpu_ticks 数组里的状态，可以分别获取 CPU_STATE_USER、CPU_STATE_NICE、CPU_STATE_SYSTEM 这三个表示使用中的状态，除以整体 CPU 就可以取到 CPU 的占比。通过 NSProcessInfo 的 activeProcessorCount 还可以得到 CPU 的核数。线上数据分析时会发现相同机型和系统的手机，性能表现却截然不同，这是由于手机过热或者电池损耗过大后系统降低了 CPU 频率所致。所以如果取得 CPU 频率后也可以针对那些降频的手机来进行针对性的优化，以保证流畅体验。获取方式可以参考 [GitHub - zenny-chen/CPU-Dasher-for-iOS: CPU Dasher for iOS source code. It only supports ARMv7 and ARMv7s architectures.](https://github.com/zenny-chen/CPU-Dasher-for-iOS)

### 内存
要想获取 App 真实的内存使用情况可以参看 WebKit 的源码，[webkit/MemoryFootprintCocoa.cpp at 52bc6f0a96a062cb0eb76e9a81497183dc87c268 · WebKit/webkit · GitHub](https://github.com/WebKit/webkit/blob/52bc6f0a96a062cb0eb76e9a81497183dc87c268/Source/WTF/wtf/cocoa/MemoryFootprintCocoa.cpp) 。JetSam会判断 App 使用内存情况，超出阈值就会杀死 App，JetSam 获取阈值的代码在 [darwin-xnu/kern_memorystatus.c at 0a798f6738bc1db01281fc08ae024145e84df927 · apple/darwin-xnu · GitHub](https://github.com/apple/darwin-xnu/blob/0a798f6738bc1db01281fc08ae024145e84df927/bsd/kern/kern_memorystatus.c)。整个设备物理内存大小可以通过 NSProcessInfo 的 physicalMemory 来获取。

### 网络
对于网络监控可以使用 Fishhook 这样的工具 Hook 网络底层库 CFNetwork。网络的情况比较复杂，所以需要定些和时间相关的关键的指标，指标如下：

* DNS 时间
* SSL 时间
* 首包时间
* 响应时间

有了这些指标才能够有助于更好的分析网络问题。启动阶段的网络请求是非常多的，所以 HTTP 的性能是非常要注意的。以下是 WWDC 网络相关的 Session：

* [Your App and Next Generation Networks - WWDC 2015 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2015/719/)
* [Networking with NSURLSession - WWDC 2015 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2015/711/)
* [Networking for the Modern Internet - WWDC 2016 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2016/714/)
* [Advances in Networking, Part 1 - WWDC 2017 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2017/707/)
* [Advances in Networking, Part 2 - WWDC 2017 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2017/709/)
* [Optimizing Your App for Today’s Internet - WWDC 2018 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2018/714/)

### I/O
对于 I/O 可以使用 [Frida • A world-class dynamic instrumentation framework | Inject JavaScript to explore native apps on Windows, macOS, GNU/Linux, iOS, Android, and QNX](https://www.frida.re/) 这种动态二进制插桩技术，在程序运行时去插入自定义代码获取 I/O 的耗时和处理的数据大小等数据。Frida 还能够在其它平台使用。

关于多维度分析更多的资料可以看看历届 WWDC 的介绍。下面我列下16年来 WWDC 关于启动优化的 Session，每场都很精彩。

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/04.png)

* [Using Time Profiler in Instruments - WWDC 2016 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2016/418/)
* [Optimizing I/O for Performance and Battery Life - WWDC 2016 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2016/719/)
* [Optimizing App Startup Time - WWDC 2016 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2016/406/)
* [App Startup Time: Past, Present, and Future - WWDC 2017 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2017/413/)
* [Practical Approaches to Great App Performance - WWDC 2018 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2018/407/)
*  [Optimizing App Launch - WWDC 2019 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2019/423/) 

## 延后任务管理
经过前面所说的对主线程耗时方法和各个纬度性能分析后，对于那些分析出来没必要在启动阶段执行的方法，可以做成按需或延后执行。
任务延后的处理不能粗犷的一口气在启动完成后在主线程一起执行，那样用户仅仅只是看到了页面，依然没法响应操作。那该怎么做呢？套路一般是这样，创建四个队列，分别是：

* 异步串行队列
* 异步并行队列
* 闲时主线程串行队列
* 闲时异步串行队列

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/06.png)

有依赖关系的任务可以放到异步串行队列中执行。异步并行队列可以分组执行，比如使用 dispatch_group，然后对每组任务数量进行限制，避免 CPU、线程和内存瞬时激增影响主线程用户操作，定义有限数量的串行队列，每个串行队列做特定的事情，这样也能够避免性能消耗短时间突然暴涨引起无法响应用户操作。使用 dispatch_semaphore_t 在信号量阻塞主队列时容易出现优先级反转，需要减少使用，确保QoS传播。可以用dispatch group 替代，性能一样，功能不差。异步编程可以直接 GCD 接口来写，也可以使用阿里的协程框架 coobjc [coobjc](https://github.com/alibaba/coobjc)。

闲时队列实现方式是监听主线程 runloop 状态，在 kCFRunLoopBeforeWaiting 时开始执行闲时队列里的任务，在 kCFRunLoopAfterWaiting 时停止。

## 优化后如何保持？
攻易守难，就像刚到新团队时将包大小减少了48兆，但是一年多一直能够守住除了决心还需要有手段。对于启动优化来说，将各个性能纬度通过监控的方式盯住是必要的，但是发现问题后快速、便捷的定位到问题还是需要找些突破口。我的思路是将启动阶段方法耗时多的按照时间线一条一条排出来，每条包括方法名、方法层级、所属类、所属模块、维护人。考虑到便捷性，最好还能方便的查看方法代码内容。

接下来我通过开发一个工具，跟你详细说说怎么实现这样的效果。设计最终希望展示内容如下：

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/07.png)

### 解析 json
如前面所说在输出一份 Chrome trace 规范的方法耗时 json 后，先要解析这份数据。这份 json 数据类似下面的样子：
```json
{"name":"[SMVeilweaa]upVeilState:","cat":"catname","ph":"B","pid":2381,"tid":0,"ts":21},
{"name":"[SMVeilweaa]tatLaunchState:","cat":"catname","ph":"B","pid":2381,"tid":0,"ts":4557},
{"name":"[SMVeilweaa]tatTimeStamp:state:","cat":"catname","ph":"B","pid":2381,"tid":0,"ts":4686},
{"name":"[SMVeilweaa]tatTimeStamp:state:","cat":"catname","ph":"E","pid":2381,"tid":0,"ts":4727},
{"name":"[SMVeilweaa]tatLaunchState:","cat":"catname","ph":"E","pid":2381,"tid":0,"ts":5732},
{"name":"[SMVeilweaa]upVeilState:","cat":"catname","ph":"E","pid":2381,"tid":0,"ts":5815},
…
```
通过 Chrome 的 [Trace-Viewer](https://chromium.googlesource.com/catapult/+/HEAD/tracing/README.md) 可以生成一个火焰图。其中 name 字段包含了类、方法和参数的信息，cat 字段可以加入其它性能数据，ph 为 B 表示方法开始，为 E 表示方法结束，ts 字段表示。

#### json 分词

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/08.png)

读取 json 文件
```swift
// 根据文件路径返回文件内容
public static func fileContent(path: String) -> String {
    do {
        return try String(contentsOfFile: path, encoding: String.Encoding.utf8)
    } catch {
        return “”
    }
}

let bundlePath = Bundle.main.path(forResource: “startTrace”, ofType: “json”)
let jsonPath = bundlePath ?? “”
let jsonContent = FileHandle.fileContent(path: jsonPath)
```

jsonContent 就是 json 内容字符串。写一个字符切割函数将字符串按照自定义符号集来切割。
```swift
public func allTkFast(operaters:String) -> [Token] {
    var nText = text.replacingOccurrences(of: “ “, with: “ starmingspace “)
    nText = nText.replacingOccurrences(of: “\n”, with: “ starmingnewline “)
    let scanner = Scanner(string: nText)
    var tks = [Token]()
    var set = CharacterSet()
    set.insert(charactersIn: operaters)
    set.formUnion(CharacterSet.whitespacesAndNewlines)
    
    while !scanner.isAtEnd {
        for operater in operaters {
            let opStr = operater.description
            if (scanner.scanString(opStr) != nil) {
                tks.append(.id(opStr))
            }
        }
        var result:NSString?
        result = nil
        if (scanner.scanUpToCharacters(from: set) != nil) {
            let resultString = result! as String
            if resultString == “starmingnewline” {
                tks.append(.newLine)
            } else if resultString == “starmingspace” {
                tks.append(.space)
            } else {
                tks.append(.id(result! as String))
            }
        }
    }
    tks.append(.eof)
    return tks
}
```

将切割的字符保存为 Token 结构体的一个个 token。Token 结构体定义如下：
```swift
public enum Token {
    case eof
    case newLine
    case space
    case comments(String)      // 注释
    case constant(Constant)    // float、int
    case id(String)            // string
    case string(String)        // 代码中引号内字符串
}

public enum Constant {
    case string(String)
    case integer(Int)
    case float(Float)
    case boolean(Bool)
}
```

代码中的 eof 表示 token 是文件结束，newLine 是换行 token。Constant 是枚举关联值，通过枚举关联值可以使枚举能够具有更多层级。后面还需要将枚举值进行判等比较，所以还需要扩展枚举的 Equatable 协议实现：
```swift
extension Token: Equatable {
    public static func == (lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.eof, .eof):
            return true
        case (.newLine, .newLine):
            return true
        case (.space, .space):
            return true
        case let (.constant(left), .constant(right)):
            return left == right
        case let (.comments(left), .comments(right)):
            return left == right
        case let (.id(left), .id(right)):
            return left == right
        case let (.string(left), .string(right)):
            return left == right
        default:
            return false
        }
    }
}
```

通用的 token 结构解析完成。接下来就是设计一个 json 特有的 token 结构。对于 json 来说换行和空格可以过滤掉，写个函数过滤换行和空格的 token：
```swift
public func allTkFastWithoutNewLineAndWhitespace(operaters:String) -> [Token] {
    let allToken = allTkFast(operaters: operaters)
    let flAllToken = allToken.filter {
        $0 != .newLine
    }
    let fwAllToken = flAllToken.filter {
        $0 != .space
    }
    return fwAllToken
}
```

json 的操作符有：

```
{}[]”:,
```

所以 operaters 参数可以是这些操作符。完整的 Lexer 类代码在 [MethodTraceAnalyze/Lexer.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Core/Lexer.swift)。使用 Lexer 类的 allTkFastWithoutNewLineAndWhitespace 方法可以取得 token 集合。

#### JSONToken

为了转成 json 的 token，我先设计一个 json token 的结构 JSONToken。

```swift
public struct JSONToken {
    public let type: JSONTokenType
    public let value: String
}

public enum JSONTokenType {
    case startDic   // {
    case endDic     // }
    case startArray // [
    case endArray   // ]
    case key        // key
    case value      // value
}
```

根据 json 的本身设计，主要分为 key 和 value，另外还需要些符号类型，用来进行进一步的解析。解析过程的状态设计为三种，用 State 枚举表示：
```swift
private enum State {
    case normal
    case keyStart
    case valueStart
}
```

在 normal 状态下，会记录操作符类型的 json token，当遇到{符号后，下一个是“符号就会更改状态为 keyStart。另一种情况就是在遇到,符号后，下一个是”符号也会更改状态为 keyStart。

状态更改成 valueStart 的条件是遇到:符号，当下一个是“时进入 valueStart 状态，如果不是“符号，就需要做区分，是{或者[时直接跳过:符号，然后记录这两个操作符。其它情况表示 value 不是字符而是数字，直接记录为 json token 就可以了。完整 json token 的解析代码见 [MethodTraceAnalyze/ParseJSONTokens.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/JSON/ParseJSONTokens.swift)。

JSONToken 集合目前还只是扁平态，而 json 数据是有 key 和 value 的多级关系在的，比如 value 可能是字符串或数字，也可能是另一组 key value 结构或者 value 的数组集合。所以下面还需要定义一个 JSONItem 结构来容纳多级关系。

#### JSONItem

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/09.png)

JSONItem 的结构体定义如下：

```swift
public struct JSONItem {
    public var type: JSONItemType
    public var value: String
    public var kvs: [JSONItemKv]
    public var array: [JSONItem]
}

// 类型
public enum JSONItemType {
    case keyValue
    case value
    case array
}

// key value 结构体
public struct JSONItemKv {
    public var key: String
    public var value: JSONItem
}
```

JSONItem 的类型分三种，key value、value 和 array 的，定义在 JSONItemType 枚举中。分别对应的三个存储字段是 kvs，里面是 JSONItemKv 类型的集合；value 为字符串；array 是 JSONItem 的集合。

定义好了多层级的结构，就可以将 JSONToken 的集合进行分析，转到 JSONItem 结构上。思路是在解析过程中碰到闭合符号时，将扁平的闭合区间内的 JSONToken  放到集合里，通过递归函数 recursiveTk 递归出多层级结构出来。所以需要设置四个状态：
```swift
enum rState {
    case normal
    case startDic
    case startArr
    case startKey
}
```

当碰到{符号进入 startDic 状态，遇到[符号进入 startKey 状态，遇到}和]符号时会结束这两个状态。在 startDic 或 startKey 状态中时会收集过程中的 JSONToken 到 recursiveTkArr 集合里。这个分析完整代码在这 [MethodTraceAnalyze/ParseJSONItem.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/JSON/ParseJSONItem.swift)。

来一段简单的 json 测试下：
```json
{
    “key1”: “value1”,
    “key2”: 22,
    “key3”: {
        “subKey1”: “subValue1”,
        “subKey2”: 40,
        “subKey3”:[
            {
                “sub1Key1”: 10,
                “sub1Key2”:{
                    “sub3Key1”: “sub3Value1”,
                    “sub3Key2”: “sub3Value2”
                }
            },
            {
                “sub1Key1”: 11,
                “sub1Key2”: 15
            }
        ],
        “subKey4”: [
            “value1”,
            23,
            “value2”
        ],
        “subKey5”: 2
    }
}
```


使用 ParseJSONItem 来解析
```swift
let jsonOPath = Bundle.main.path(forResource: “test”, ofType: “json”)
let jOrgPath = jsonOPath ?? “”
let jsonOContent = FileHandle.fileContent(path: jOrgPath)

let item = ParseJSONItem(input: jsonOContent).parse()
```

得到的 item 数据如下图所示

![](/uploads/how-to-analyze-startup-time-cost-in-ios/02.png)

可以看到，item 的结构和前面的 json 结构是一致的。

#### json 单测

为了保证后面对 json 的解析修改和完善对上面列的测试 case 解析结果不会有影响，可以写个简单测试类来做。这个类只需要做到将实际结果和预期值做比较，相等即可通过，不等即可提示并中断，方便定位问题。因此传入参数只需要有运行结果、预期结果、描述就够用了。我写个 Test 协议，通过扩展默认实现一个比较的方法，以后需要单测的类遵循这个协议就可以使用和扩展单测功能了。Test 协议具体代码如下：
```swift
protocol Test {
    static func cs(current:String, expect:String, des:String)
}

// compare string 对比两个字符串值
extension Test {
    static func cs(current:String, expect: String, des: String) {
        if current == expect {
            print(“✅ \(des) ok，符合预期值：\(expect)”)
        } else {
            let msg = “❌ \(des) fail，不符合预期值：\(expect)”
            print(msg)
            assertionFailure(msg)
        }
    }
}
```

写个 TestJSON 遵循 Test 协议进行单测。测试各个解析后的值，比如测试 item第一级 key value 配对数量可以这样写：
```swift
let arr = item.array[0].kvs
cs(current: “\(arr.count)”, expect: “3”, des: “all dic count”)
```

打印的结果就是：
```bash
✅ all dic count ok，符合预期值：3
```

完整单测代码在这里：[MethodTraceAnalyze/TestJSON.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/JSON/TestJSON.swift)

### 解析 Launch Trace 的 json
前面说的 JSONItem 是通用的多层级 json 结构体。对于启动的 json，实际要表现的方法调用链和 json 的层级并不是对应的。方法调用链是通过 ph 字段表示，B 表示方法开始，E 表示方法结束，中间会有其它方法调用的闭合，这些方法在调用链里可以被称为调用方法的子方法。

为了能够表现出这样的调用链关系，我设计了下面的 LaunchItem 结构：

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/10.png)

结构体代码如下：

```swift
public struct LaunchItem {
    public let name: String  // 调用方法
    public var ph: String    // B 代表开始、E 代表结束、BE 代表合并后的 Item、其它代表描述
    public var ts: String    // 时间戳，开始时间
    public var cost: Int     // 耗时 ms
    public var times: Int    // 执行次数
    public var subItem: [LaunchItem]   // 子 item
    public var parentItem:[LaunchItem] // 父 item
}
```

通过 ParseJSONTokens 类来获取 JSONToken 的集合。
```swift
tks = ParseJSONTokens(input: input).parse()
```

找出 name、ph、ts 字段数据转到 LaunchItem 结构体中。这部分代码实现在这里 [MethodTraceAnalyze/ParseLaunchJSON.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Launch/ParseLaunchJSON.swift)。

遍历 LaunchItem 集合，完善 LaunchItem 的信息，先完善 LaunchItem 的 cost 和 subItem 的信息。在方法调用链同一级时依据 ph 字段将相同方法 B 和 E 之间的 LaunchItem 都放到一个数组里，通过栈顶和栈底的 ts 字段值相减就能够得到 cost 的值，也就是方法的耗时，代码如下：
```swift
let b = itemArr[0]
let e = itemArr[itemArr.count - 1]
let cost = Int(e.ts)! - Int(b.ts)!
```

当这个数组数量大于2，代表方法里还会调用其它的方法，通过递归将调用链中的子方法都取出来，并放到 subItem 里。
```swift
pItem.subItem.append(recusiveMethodTree(parentItem: rPItem, items: newItemArr))
```

代码见[MethodTraceAnalyze/LaunchJSON.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Launch/LaunchJSON.swift)里的 launchJSON 函数。

### 展示启动方法链
前面通过 launchJSON 函数取到了方法调用链的根部 LaunchItem。使用 recusiveItemTree 函数递归这个根 LaunchItem ，可以输出方法调用关系图。很多工程在启动阶段会执行大量方法，很多方法耗时很少，可以过滤那些小于10毫秒的方法，让分析更加聚焦。

![](/uploads/how-to-analyze-startup-time-cost-in-ios/03.png)

展示效果如上图所示，完整代码在 [MethodTraceAnalyze/LaunchJSON.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Launch/LaunchJSON.swift) 里的 tree 函数里。图中的阶段切换，比如 T1到 T2的切换可以在 recusiveItemTree 函数中设置，对应的处理代码是：
```swift
// 获取 T1 到 T5 阶段信息，其中 updateLauncherState 函数名需要替换成自己阶段切换的函数名，最多5个阶段
if methodName == “updateLauncherState:” {
    currentT += 1
    if currentT > 5 {
        currentT = 5
    }
}
```

耗时的高低也做了颜色的区分。外部耗时指的是子方法以外系统或没源码的三方方法的耗时，规则是父方法调用的耗时减去其子方法总耗时。代码如下：
```swift
// 获取外部耗时
var sysCost = 0
if aItem.subItem.count > 0 {
    for aSubItem in aItem.subItem {
        sysCost += aSubItem.cost
    }
}
sysCost = (aItem.cost - sysCost) / 1000
```

bundle、owner、业务线这三项需要根据自己工程情况来，如果工程使用的是 excel 做的记录可以导出为 csv 格式文件，参考 LaunchJSON 类里的 loadSimpleKeyValueDicWithCsv 函数进行 csv 数据读取。如果数据是在服务端，输出为 json 的话就更好办了，使用前面写的 ParseJSONItem 类就能够进行数据解析了，可以参考 LaunchJSON 类里的 parseBundleOwner 函数。展示示例里我先置为默认的暂无了。

目前为止通过过滤耗时少的方法调用，可以更容易发现问题方法。但是，有些方法单次执行耗时不多，但是会执行很多次，累加耗时会大，这样的情况也需要体现在展示页面里。另外外部耗时高时或者碰到自己不了解的方法时，是需要到工程源码里去搜索对应的方法源码进行分析的，有的方法名很通用时还需要花大量时间去过滤无用信息。

因此接下来还需要做两件事情，首先累加方法调用次数和耗时，体现在展示页面中，另一个是从工程中获取方法源码能够在展示页面中进行点击显示。

对于方法调用次数和总耗时的统计我写在了 LaunchJSON 类的 allMethodAndSubMethods 函数里，思路就是遍历所有的 LaunchItem，碰到相同的 item name 就对次数和耗时进行累加。代码如下：
```swift
let allItems = LaunchJSON.leaf(fileName: fileName, isGetAllItem: true)

var mergeDic = [String:LaunchItem]()
for item in allItems {
    let mergeKey = item.name // 方法名为标识
    if mergeDic[mergeKey] != nil {
        var newItem = mergeDic[mergeKey]
        newItem?.cost += item.cost // 累加耗时
        newItem?.times += 1 // 累加次数
        mergeDic[mergeKey] = newItem
    } else {
        mergeDic[mergeKey] = item
    }
}
```

展示时判断次数大于1时，耗时大于0时展示出来。
```swift
var mergeStr = “”
if preMergeItemDic.keys.contains(“\(bundleName+className+methodName)”) {
    //
    let mItem = preMergeItemDic[“\(bundleName+className+methodName)”]
    if mItem?.times ?? 0 > 1 && (mItem?.cost ?? 0) / 1000 > 0 {
        mergeStr = “(总次数\(mItem?.times ?? 0)、总耗时\((mItem?.cost ?? 0) / 1000))”
    }
}
```

展示的效果如下：

![](/uploads/how-to-analyze-startup-time-cost-in-ios/04.png)

### 展示方法源码
在页面上展示源码需要先解析 .xcworkspace 文件，通过 .xcworkspace文件取到工程里所有的 .xcodeproj 文件。分析 .xcodeproj 文件取到所有 .m 和.mm 源码文件路径，解析源码，取到方法的源码内容进行展示。

#### 解析 .xcworkspace

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/11.png)

打开.xcworkspace，可以看到这个包内主要文件是 contents.xcworkspacedata。内容是一个 xml：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:GCDFetchFeed.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:Pods/Pods.xcodeproj">
   </FileRef>
</Workspace>
```

所以下面需要对 xml 进行分析。xml 的操作符有 <>=\”/?![]，通过这些操作符能够取到通用的 token 集合 tokens。
```swift
tokens = Lexer(input: input, type: .plain).allTkFast(operaters: “<>=\”/?![]”)
```

根据 xml 的规则，将解析状态分为 normal、startTag、cdata 三种。定义的枚举为：
```swift
private enum State {
    case normal
    case startTag
    case cdata
}
```

当遇到<符号时，更改解析状态为 startTag。如果<符号后面跟的是![CDATA[表示是 cdata 标签，状态需要改成 cdata。实现代码如下：
```swift
// <tagname …> 和 <![CDATA[
if currentState == .normal && currentToken == .id(“<“) {
    // <![CDATA[
    if peekTk() == .id(“!”) && peekTkStep(step: 2) == .id(“[“) && peekTkStep(step: 3) == .id(“CDATA”) && peekTkStep(step: 4) == .id(“[“) {
        currentState = .cdata
        advanceTk() // jump <
        advanceTk() // jump !
        advanceTk() // jump [
        advanceTk() // jump CDATA
        advanceTk() // jump [
        return
    }
    
    // <tagname …>
    if currentTokens.count > 0 {
        addTagTokens(type: .value) // 结束一组
    }
    currentState = .startTag
    advanceTk()
    return
}
```

在 startTag 和 cdata 状态时会将遇到的 token 装到 currentTokens 里，在结束状态时加入到 XMLTagTokens 这个结构里记录下来。XMLTagTokens 的定义如下：
```swift
public struct XMLTagTokens {
    public let type: XMLTagTokensType
    public let tokens: [Token]
}
```

currentTokens 会在状态结束时记录到 XMLTagTokens 的 tokens 里。startTag 会在>符号时结束。cdata 会在]]>时结束。这部分实现代码见 [MethodTraceAnalyze/ParseStandXMLTagTokens.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/XML/ParseStandXMLTagTokens.swift) 。

接下来对 XMLTagTokens 集合进行进一步分析，XML 的 tag 节点分为单标签比如<br/>、开标签比如<p>、闭合标签比如</p>、标签值、xml 标识说明，这五类。因此我定义了标签节点的类型枚举 XMLTagNodeType：
```swift
public enum XMLTagNodeType {
    case xml
    case single // 单个标签
    case start  // 开标签 <p>
    case value  // 标签的值 <p>value</p>
    case end    // 闭合的标签 </p>
}
```

标签节点除了类型信息，还需要有属性集合、标签名和标签值，结构体定义为：
```swift
public struct XMLTagNode {
    public let type: XMLTagNodeType
    public let value: String // 标签值
    public let name: String  // 标签名
    public let attributes: [XMLTagAttribute] // 标签属性
}
```

解析 XML 标签节点相比较于 HTML 来说会简化些，HTML的规则更加的复杂，以前使用状态机根据 W3C 标准[HTML Standard](https://html.spec.whatwg.org/multipage/parsing.html#html-parser)专门解析过，状态机比较适合于复杂的场景，具体代码在这里 [HTN/HTMLTokenizer.swift](https://github.com/ming1016/HTN/blob/master/Sources/Core/HTML/HTMLTokenizer.swift) 。可以看到按照 W3C 的标准，设计了一个 HTNStateType 状态枚举，状态特别多。对于 XML 来说状态会少些：
```swift
enum pTagState {
    case start
    case questionMark
    case xml
    case tagName
    case attributeName
    case equal
    case attributeValue
    case startForwardSlash
    case endForwardSlash
    case startDoubleQuotationMarks
    case backSlash
    case endDoubleQuotationMarks
}
```

XML  标签节点的解析我没有用状态机，将解析结果记录到了 XMLTagNode 结构体中。标签节点解析过程代码在这里 [MethodTraceAnalyze/ParseStandXMLTags.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/XML/ParseStandXMLTags.swift) 。标签节点解析完后还需要解决 XML 的层级问题，也就是标签包含标签的问题。

先定义一个结构体 XMLNode，用来记录 XML 的节点树：

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/12.png)

```swift
public struct XMLNode {
    public let name: String
    public let attributes: [XMLTagAttribute]
    public var value: String
    public var subNodes: [XMLNode]
}
```

其中 subNodes 是 XMLNode 的子节点集合，解析出 XMLNode 的思路是根据前面输出的 XMLTagNode 的类型来分析，当遇到类型是 start 到遇到相同 name 的 end 之间不断收集 XMLTagNode 到 currentTagNodeArr 数组里，end 时将这个数组添加到 tagNodeArrs 里，然后开始收集下一组 start 和 end。关键代码如下：
```swift
// 当遇到.end 类型时将一组 XMLTagNode 加到 tagNodeArrs 里。然后重置。
if node.type == .end && node.name == currentTagName {
    currentState = .end
    currentTagNodeArr.append(node)
    // 添加到一级
    tagNodeArrs.append(currentTagNodeArr)
    // 重置
    currentTagNodeArr = [XMLTagNode]()
    currentTagName = “”
    continue
}
```

对于 xml 类型标签和 single 类型的会直接保存到 tagNodeArrs 里。接下来对 tagNodeArrs 这些由 XMLTagNode 组成的数组集进行分析。如果 tagNodeArr 的数组数量是1时，表示这一层级的 tag 是 xml 或者单标签的情况比如<?xml version="1.0" encoding="UTF-8"?> 或 <link href=“/atom.xml” rel=“self”/> 这种。数量是2时表示开闭标签里没有其他的标签，类似<p></p>这种。当 tagNodeArr 的数量大于2时，可能有两种情况，一种是 tagNode 为 value 类型比如<p>section value</p>，其他情况就是标签里会嵌套标签，需要递归调用 recusiveParseTagNodes 函数进行下一级的解析。这部分逻辑在 recusiveParseTagNodes 函数里，相关代码如下：
```swift
for tagNodeArr in tagNodeArrs {
    if tagNodeArr.count == 1 {
        // 只有一个的情况，即 xml 和 single
        let aTagNode = tagNodeArr[0]
        pNode.subNodes.append(tagNodeToNode(tagNode: aTagNode))
    } else if tagNodeArr.count == 2 {
        // 2个的情况，就是比如 <p></p>
        let aTagNode = tagNodeArr[0] // 取 start 的信息
        pNode.subNodes.append(tagNodeToNode(tagNode: aTagNode))
    } else if tagNodeArr.count > 2 {
        // 大于2个的情况
        let startTagNode = tagNodeArr[0]
        var startNode = tagNodeToNode(tagNode: startTagNode)
        let secondTagNode = tagNodeArr[1]
        
        // 判断是否是 value 这种情况比如 <p>paragraph</p>
        if secondTagNode.type == .value {
            // 有 value 的处理
            startNode.value = secondTagNode.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            pNode.subNodes.append(startNode)
        } else {
            // 有子标签的情况
            // 递归得到结果
            var newTagNodeArr = tagNodeArr
            newTagNodeArr.remove(at: tagNodeArr.count - 1)
            newTagNodeArr.remove(at: 0)
            pNode.subNodes.append(recusiveParseTagNodes(parentNode: startNode, tagNodes: newTagNodeArr))
        } // end else
    } // end else if
} // end for
```

完成 xcworkspace 的 XML 解析，获取 XML 的节点树如下所示：

![](/uploads/how-to-analyze-startup-time-cost-in-ios/05.png)

写个单测，保证后面增加功能和更新优化解析后不会影响结果。单测代码在这里 [MethodTraceAnalyze/TestXML.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/XML/TestXML.swift)。

#### 解析 .xcodeproj

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/13.png)

通过 XML 的解析可以获取 FileRef 节点内容， xcodeproj 的文件路径就在 FileRef 节点的 location 属性里。每个 xcodeproj 文件里会有 project 工程的源码文件。为了能够获取方法的源码进行展示，那么就先要取出所有 project 工程里包含的源文件的路径。

取 xcodeproj 文件路径的方式如下：
```swift
if aFile.fileName == “contents.xcworkspacedata” {
    let root = ParseStandXML(input: aFile.content).parse()
    let workspace = root.subNodes[1]
    
    for fileRef in workspace.subNodes {
        var fileRefPath = fileRef.attributes[0].value
        fileRefPath.removeFirst(6)
        
        // 判断是相对路径还是绝对路径
        let arr = fileRefPath.split(separator: “/“)
        var projectPath = “”
        if arr.count > 2 {
            projectPath = “\(fileRefPath)/project.pbxproj”
        } else {
            projectPath = “/\(pathStr)/\(fileRefPath)/project.pbxproj”
        }
        // 读取 project 文件内容分析
        allSourceFile += ParseXcodeprojSource(input: projectPath).parseAllFiles()
        
    } // end for fileRef in workspace.subNodes
} // end for
```

如上面代码所示，ParseXcodeprojSource 是专门用来解析 xcodeproj 的，parseAllFiles 方法根据解析的结果，取出所有 xcodeproj 包含的源码文件。

xcodeproj 的文件内容看起来大概是下面的样子。

![](/uploads/how-to-analyze-startup-time-cost-in-ios/06.png)

其实内容还有很多，需要一个个解析出来。

分析后分词的分割符号有 /*={};\”,() 这些，根据这些分割符号设计分词的 token 类型 XcodeprojTokensType，XcodeprojTokensType 为枚举包含下面十个类型：
```swift
public enum XcodeprojTokensType {
    case codeComment // 注释
    case string
    case id
    case leftBrace // {
    case rightBrace // }
    case leftParenthesis // (
    case rightParenthesis // )
    case equal // =
    case semicolon // ;
    case comma // ,
}
```

codeComment、string、id 这些类型会由多个 token 组成，所以最好将 xcodeproj 的基础 token 设计为下面的样子：
```swift
public struct XcodeprojTokens {
    public let type: XcodeprojTokensType
    public let tokens: [Token]
}
```

由 tokens 字段记录多个 token。实现分词代码在这 [MethodTraceAnalyze/ParseXcodeprojTokens.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Xcodeproj/ParseXcodeprojTokens.swift)

xcodeproj 文件虽然不是 json，但是大小括号的规则和 json 还比较类似，大括号里的数据类似字典可以用 key、value 配对记录，小括号数据类似数组，记录 value 就可以。这样可以设计 xcodeproj 的节点类型为：
```swift
public enum XcodeprojNodeType {
    case normal
    case root // 根节点
    
    case dicStart // {
    case dicKey
    case dicValue
    case dicEnd   // }
    
    case arrStart // (
    case arrValue
    case arrEnd   // )
}
```

如上面定义 XcodeprojNodeType 枚举，其大括号内数据的 key 类型为 dicKey，value 类型为 dicValue。小括号的 value 类型为 arrValue。节点设计为：

```swift
public struct XcodeprojNode {
    public let type: XcodeprojNodeType
    public let value: String
    public let codeComment: String
    public var subNodes: [XcodeprojNode]
}
```

解析代码都在这里 [MethodTraceAnalyze/ParseXcodeprojNode.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Xcodeproj/ParseXcodeprojNode.swift) 。

xcodeproj 也有层级，所以也需要构建一个树结构。结构代码如下：
```swift
public struct XcodeprojTreeNode {
    public var type: XcodeprojTreeNodeType
    public var value: String
    public var comment: String
    public var kvs: [XcodeprojTreeNodeKv]
    public var arr: [XcodeprojTreeNodeArrayValue]
}

public enum XcodeprojTreeNodeType {
    case value
    case keyValue
    case array
}

public struct XcodeprojTreeNodeKey {
    public var name: String
    public var comment: String
}

public struct XcodeprojTreeNodeArrayValue {
    public var name: String
    public var comment: String
}

public struct XcodeprojTreeNodeKv {
    public var key: XcodeprojTreeNodeKey
    public var value: XcodeprojTreeNode
}
```

考虑到 xcodeproj 里的注释很多，也都很有用，因此会多设计些结构来保存值和注释。思路是根据 XcodeprojNode 的类型来判断下一级是 key value 结构还是 array 结构。如果 XcodeprojNode 的类型是 XcodeprojNode 的类型是 dicStart 表示下级是 key value 结构。如果类型是 arrStart 就是 array 结构。当碰到类型是 dicEnd 同时和最初 dicStart 是同级时，递归下一级树结构。而 arrEnd 不用递归，xcodeproj 里的 array 只有值类型的数据。生成节点树结构这部分代码实现在这里 [MethodTraceAnalyze/ParseXcodeprojTreeNode.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Xcodeproj/ParseXcodeprojTreeNode.swift)

断点看生成的结构如下图：

![](/uploads/how-to-analyze-startup-time-cost-in-ios/07.png)

其中 section 内容都在 objects 里

![](/uploads/how-to-analyze-startup-time-cost-in-ios/08.png)

有了基本节点树结构以后就可以设计 xcodeproj 里各个 section 的结构。主要有一下的 section：
* PBXBuildFile：文件，最终会关联到 PBXFileReference
* PBXContainerItemProxy：部署的元素
* PBXFileReference：各类文件，有源码、资源、库等文件
* PBXFrameworksBuildPhase：用于 framework 的构建
* PBXGroup：文件夹，可嵌套，里面包含了文件与文件夹的关系
* PBXNativeTarget：Target 的设置
* PBXProject：Project 的设置，有编译工程所需信息
* PBXResourcesBuildPhase：编译资源文件，有 xib、storyboard、plist以及图片等资源文件
* PBXSourcesBuildPhase：编译源文件（.m）
* PBXTargetDependency： Taget 的依赖
* PBXVariantGroup：.storyboard 文件
* XCBuildConfiguration：Xcode 编译配置，对应 Xcode 的 Build Setting 面板内容
* XCConfigurationList：构建配置相关，包含项目文件和 target 文件

根据 xcodeproj 的结构规则设计结构体：
```swift
// project.pbxproj 结构
public struct Xcodeproj {
    var archiveVersion = “”
    var classes = [XcodeprojTreeNodeArrayValue]()
    var objectVersion = “” // 区分 xcodeproj 不同协议版本
    var rootObject = PBXValueWithComment(name: “”, value: “”)
    
    var pbxBuildFile = [String:PBXBuildFile]()
    var pbxContainerItemProxy = [String:PBXContainerItemProxy]()
    var pbxFileReference = [String:PBXFileReference]()
    var pbxFrameworksBuildPhase = [String:PBXFrameworksBuildPhase]()
    var pbxGroup = [String:PBXGroup]()
    var pbxNativeTarget = [String:PBXNativeTarget]()
    var pbxProject = [String:PBXProject]()
    var pbxResourcesBuildPhase = [String:PBXResourcesBuildPhase]()
    var pbxSourcesBuildPhase = [String:PBXSourcesBuildPhase]()
    var pbxTargetDependency = [String:PBXTargetDependency]()
    var pbxVariantGroup = [String:PBXVariantGroup]()
    var xcBuildConfiguration = [String:XCBuildConfiguration]()
    var xcConfigurationList = [String:XCConfigurationList]()
    
    init() {
        
    }
}
```

具体每个字段集合元素的结构体比如 PBXBuildFile 和 PBXFileReference 对应的结构体和 xcodeproj 的 section 结构对应上。然后使用 ParseXcodeprojTreeNode 解析的节点树结构生成最终的 Xcodeproj section 的结构体。解析过程在这里 [MethodTraceAnalyze/ParseXcodeprojSection.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Xcodeproj/ParseXcodeprojSection.swift)。

调试看到 Xcodeproj 的结构如下：

![](/uploads/how-to-analyze-startup-time-cost-in-ios/09.png)

对 xcodeproj 的解析也写了单测来保证后期 [MethodTraceAnalyze/TestXcodeproj.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Xcodeproj/TestXcodeproj.swift)。

![](/uploads/how-to-analyze-startup-time-cost-in-ios/10.png)

得到 section 结构 Xcodeproj 后，就可以开始分析所有源文件的路径了。根据前面列出的 section 的说明，PBXGroup 包含了所有文件夹和文件的关系，Xcodeproj 的 pbxGroup 字段的 key 是文件夹，值是文件集合，因此可以设计一个结构体 XcodeprojSourceNode 用来存储文件夹和文件关系。XcodeprojSourceNode 结构如下：
```swift
public struct XcodeprojSourceNode {
    let fatherValue: String // 文件夹
    let value: String // 文件的值
    let name: String // 文件名
    let type: String
}
```

通过遍历 pbxGroup 可以将文件夹和文件对应上，文件名可以通过 pbxGroup 的 value 到 PBXFileReference 里去取。代码如下：
```swift
var nodes = [XcodeprojSourceNode]()

// 第一次找出所有文件和文件夹
for (k,v) in proj.pbxGroup {
    guard v.children.count > 0 else {
        continue
    }
    
    for child in v.children {
        // 如果满足条件表示是目录
        if proj.pbxGroup.keys.contains(child.value) {
            continue
        }
        // 满足条件是文件
        if proj.pbxFileReference.keys.contains(child.value) {
            guard let fileRefer = proj.pbxFileReference[child.value] else {
                continue
            }
        
            nodes.append(XcodeprojSourceNode(fatherValue: k, value: child.value, name: fileRefer.path, type: fileRefer.lastKnownFileType))
        }
    } // end for children
    
} // end for group
```

接下来需要取得完整的文件路径。通过 recusiveFatherPaths 函数获取文件夹路径。这里需要注意的是需要处理 ../ 这种文件夹路径符，获取完整路径的实现代码可以看这里 [MethodTraceAnalyze/ParseXcodeprojSource.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/Xcodeproj/ParseXcodeprojSource.swift)。

有了每个源文件的路径，接下来就可以对这些源文件进行解析了。

#### 解析 .m .mm 文件

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/14.png)

对 Objective-C 解析可以参考 LLVM，这里只需要找到每个方法对应的源码，所以自己也可以实现。分词前先看看 LLVM 是怎么定义 token 的。定义文件在这里 https://opensource.apple.com/source/lldb/lldb-69/llvm/tools/clang/include/clang/Basic/TokenKinds.def 。根据这个定义我设计了 token 的结构体，主体部分如下：
```swift
// 切割符号 [](){}.&=*+-<>~!/%^|?:;,#@
public enum OCTK {
    case unknown // 不是 token
    case eof // 文件结束
    case eod // 行结束
    case codeCompletion // Code completion marker
    case cxxDefaultargEnd // C++ default argument end marker
    case comment // 注释
    case identifier // 比如 abcde123
    case numericConstant(OCTkNumericConstant) // 整型、浮点 0x123，解释计算时用，分析代码时可不用
    case charConstant // ‘a’
    case stringLiteral // “foo”
    case wideStringLiteral // L”foo”
    case angleStringLiteral // <foo> 待处理需要考虑作为小于符号的问题
    
    // 标准定义部分
    // 标点符号
    case punctuators(OCTkPunctuators)
    
    //  关键字
    case keyword(OCTKKeyword)
    
    // @关键字
    case atKeyword(OCTKAtKeyword)
}
```

完整的定义在这里 [MethodTraceAnalyze/ParseOCTokensDefine.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/OC/ParseOCTokensDefine.swift)。分词过程可以参看 LLVM 的实现 [clang: lib/Lex/Lexer.cpp Source File](http://clang.llvm.org/doxygen/Lexer_8cpp_source.html)。我在处理分词时主要是按照分隔符一一对应处理，针对代码注释和字符串进行了特殊处理，一个注释一个 token，一个完整字符串一个 token。我分词实现代码 [MethodTraceAnalyze/ParseOCTokens.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/OC/ParseOCTokens.swift)。

由于只要取到类名和方法里的源码，所以语法分析时，只需要对类定义和方法定义做解析就可以，语法树中节点设计：
```swift
// OC 语法树节点
public struct OCNode {
    public var type: OCNodeType
    public var subNodes: [OCNode]
    public var identifier: String   // 标识
    public var lineRange: (Int,Int) // 行范围
    public var source: String       // 对应代码
}

// 节点类型
public enum OCNodeType {
    case `default`
    case root
    case `import`
    case `class`
    case method
}
```

其中 lineRange 记录了方法所在文件的行范围，这样就能够从文件中取出代码，并记录在 source 字段中。

解析语法树需要先定义好解析过程的不同状态：
```swift
private enum RState {
    case normal
    case eod                   // 换行
    case methodStart           // 方法开始
    case methodReturnEnd       // 方法返回类型结束
    case methodNameEnd         // 方法名结束
    case methodParamStart      // 方法参数开始
    case methodContentStart    // 方法内容开始
    case methodParamTypeStart  // 方法参数类型开始
    case methodParamTypeEnd    // 方法参数类型结束
    case methodParamEnd        // 方法参数结束
    case methodParamNameEnd    // 方法参数名结束
    
    case at                    // @
    case atImplementation      // @implementation
    
    case normalBlock           // oc方法外部的 block {}，用于 c 方法
}
```

完整解析出方法所属类、方法行范围的代码在这里 [MethodTraceAnalyze/ParseOCNodes.swift](https://github.com/ming1016/MethodTraceAnalyze/blob/master/MethodTraceAnalyze/OC/ParseOCNodes.swift)

解析 .m 和 .mm 文件，一个一个串行解的话，对于大工程，每次解的速度很难接受，所以采用并行方式去读取解析多个文件，经过测试，发现每组在60个以上时能够最大利用我机器（2.5 GHz 双核Intel Core i7）的 CPU，内存占用只有60M，一万多.m文件的工程大概2分半能解完。分组并行的代码实现如下：
```swift
let allPath = XcodeProjectParse.allSourceFileInWorkspace(path: workspacePath)
var allNodes = [OCNode]()
let groupCount = 60 // 一组容纳个数
let groupTotal = allPath.count/groupCount + 1

var groups = [[String]]()
for I in 0..<groupTotal {
    var group = [String]()
    for j in I*groupCount..<(I+1)*groupCount {
        if j < allPath.count {
            group.append(allPath[j])
        }
    }
    if group.count > 0 {
        groups.append(group)
    }
}

for group in groups {
    let dispatchGroup = DispatchGroup()
    for node in group {
        dispatchGroup.enter()
        let queue = DispatchQueue.global()
        queue.async {
            let ocContent = FileHandle.fileContent(path: node)
            let node = ParseOCNodes(input: ocContent).parse()
            for aNode in node.subNodes {
                allNodes.append(aNode)
            }
            dispatchGroup.leave()
        } // end queue async
    } // end for
    dispatchGroup.wait()
} // end for
```

使用的是 dispatch group 的 wait，保证并行的一组完成再进入下一组。

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/15.png)

现在有了每个方法对应的源码，接下来就可以和前面 trace 的方法对应上。页面展示只需要写段 js 就能够控制点击时展示对应方法的源码。

#### 页面展示

在进行 HTML 页面展示前，需要将代码里的换行和空格替换成 HTML 里的对应的</br>和 &nbsp; 。
```swift
let allNodes = ParseOC.ocNodes(workspacePath: “/Users/ming/Downloads/GCDFetchFeed/GCDFetchFeed/GCDFetchFeed.xcworkspace”)

var sourceDic = [String:String]()
for aNode in allNodes {
    sourceDic[aNode.identifier] = aNode.source.replacingOccurrences(of: “\n”, with: “</br>”).replacingOccurrences(of: “ “, with: “&nbsp;”)
}
```

用 p 标签作为源码展示的标签，方法执行顺序的编号加方法名作为 p 标签的 id，然后用 display: none; 将 p 标签隐藏。方法名用 a 标签，click 属性执行一段 js 代码，当 a 标签点击时能够显示方法对应的代码。这段 js 代码如下：
```javascript
function sourceShowHidden(sourceIdName) {
    var sourceCode = document.getElementById(sourceIdName);
    sourceCode.style.display = “block”;
}
```

最终效果如下图：

![](/uploads/how-to-analyze-startup-time-cost-in-ios/11.png)

将动态分析和静态分析进行了结合，后面可以通过不同版本进行对比，发现哪些方法的代码实现改变了，能展示在页面上。还可以进一步静态分析出哪些方法会调用到 I/O 函数、起新线程、新队列等，然后展示到页面上，方便分析。

读到最后，可以看到这个方法分析工具并没有用任何一个轮子，其实有些是可以使用现有轮子的，比如 json、xml、xcodeproj、Objective-C 语法分析等，之所有没有用是因为不同轮子使用的语言和技术区别较大，当格式更新时如果使用的单个轮子没有更新会影响整个工具。开发这个工具主要工作是在解析上，所以使用自有解析技术也能够让所做的功能更聚焦，不做没用的功能，减少代码维护量，所要解析格式更新后，也能够自主去更新解析方式。更重要的一点是可以亲手接触下这些格式的语法设计。

## 结语
今天说了下启动优化的技术手段，总的说，对启动进行优化的决心重要程度是远大于技术手段的，决定着是否能够优化的更多。技术手段有很多，我觉得手段的好坏区别只是在效率上，最差的情况全用手动一个个去查耗时也是能够解题的。

最近看了鲁迅的一段话，很有感触，分享一下：
```
我们好像都是爱生病的人
苦的很
我的一生
好像是在不断生病和骂人中就过去多半了
我三十岁不到，牙齿就掉光了
满口义齿
我戒酒
吃鱼肝油
以望延长我的生命
倒不尽是为了我的爱人
大半是为了我的敌人
我自己知道的，我并不大度
说到幸福
只得面向过去
或者面向除了坟墓以外毫无任何希望的将来
每个战士都是如此
我们活在这样的地方
我们活在这样的时代
```

![](/uploads/kuaishou-unused-class-swiftui-note-binary-tree-interview/16.png)

































