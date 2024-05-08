---
title: 如何用 SwiftUI + Combine + Swift Concurrency Aysnc/Await Actor 欢畅开发
date: 2022-01-03 11:53:21
tags: [Apple, Swift, macOS, Combine, SwiftUI, Concurrency]
categories: Programming
banner_img: /uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/16.png
---

## 先说两句废话（Don't blame me about my calculation） 

为啥写这篇文章，简单说，这些日子以来，总觉着做事还是专注些好，于是也逐步减少了很多信息消费，缩减了些欲望吧。目前更加关注怎么能够让开发更快乐些，相信有了这个方向，其他事情就更容易见招拆招了，面对的挑战也不再是挑战，而是激发自己斗志的辅助工具，其实不用在乎那些看似权威的做法和打法，只要是没让你开心的，肯定是有改进空间的。思路和方向才是最重要的，比如[《大侦探波洛》](https://search.douban.com/movie/subject_search?search_text=%E5%A4%A7%E4%BE%A6%E6%8E%A2%E6%B3%A2%E7%BD%97&cat=1002)，每次破案之前波洛就已经通过利害关系找好了方向，他的推理都是基于认定的方向去寻找素材。 

开心不是因为没有挑战，没有困难，没有煎熬，而是因为找到了方向，这个方向就是，快乐的 Coding，开心的工作，为了达成这个目标那些艰难挑战也就不算什么了。对于 Coding，经过实操，我觉得声明式 UI 响应式编程范式就是很好的提升工作愉悦程度的方式。代码在 GitHub 上，[链接](https://github.com/ming1016/SwiftPamphletApp)。后面我会详细跟你说说这个应用如何开发的及相关知识点，希望你也能够感受下这种 Happy 的开发模式。 

这之前，我想先说下为什么我觉得快乐是很件重要的事情。这段时间，我接受了好几次采访，有关于工程师文化方面的，还有《时尚COSMOPOLITAN》杂志的采访，记者会问到一些以前的事情，在聊过往事情时我发现原来快乐才是每天自己存在着的最根本的原动力。为了能够让自己能够一直活着，就不要偏离快乐。摄影师是任欣羽，参与过《一代宗师》的拍摄，还是《时尚芭莎》的模特。以下是时尚 COSMOPOLITAN 的采访内容： 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/00.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/01.jpg)

完整内容见：https://mp.weixin.qq.com/s/b5fj2b65xRv4mhFpftwNcg 

视频可见这条微博地址：https://weibo.com/1351051897/KEdu5Fi1x?pagetype=profilefeed 

视频有六十多万播放量，两百多评论和一千多转发。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/02.png)

话题还上了微博热搜，有六百多万阅读和三千多讨论。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/03.png)

你肯定会觉得很奇怪，我怎么会接受时尚杂志采访，其实我早在2006年就跟时尚娱乐圈有染了，那年张纪中版《神雕侠侣》刚热播完，刘亦菲演的小龙女，我特别的喜欢。有幸在一次活动中我成为她的御用摄影师，由于过于激动手抖，拍糊了好多张，蛮可惜的。私存这批里还是有些清晰的，这些照片最近在找资料时不小心被我翻了出来。挑几张看看十六年前的刘亦菲和我是什么样的吧。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/04.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/05.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/06.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/07.jpg)

我还很用心的置办了新家。也是希望能够让自己能够开心些。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/08.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/09.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/10.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/11.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/12.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/30.jpg)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/13.jpg)

那么，怎样高效开发，带来愉悦的呢？ 

## 看看做出来的样子 

这是个 macOS 应用《[戴铭的小册子](https://github.com/ming1016/SwiftPamphletApp)》，能够方便的查看 Swift 语法，还有一些主要库的使用指南，内容还在完善中，选择的库主要就是开发小册子应用使用到的 SwitUI、Combine、Swift Concurrency。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/14.png)

除了这些速查和库的使用内容外，这个应用还有一些开发者的动态，当他们有新的动作，比如提交了代码、star 了什么项目，提交和留言了议题都会直接在程序坞中提醒你。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/15.png)

我对一些库做了分类，方便按需查找，库有新的提交也会在程序坞中提醒。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/16.png)

还能方便的查看库的议题。比如在阮一峰的《科技爱好者周刊》的议题中可以看到有很多人推荐和自荐了一些信息。保留议题有一千六百多个。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/17.png)

这个元旦假期，我又添加了博客动态的功能，可以跟进一些博客内容的更新。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/18.png)

由于 Swift 语言的简洁，这些库的先进，最近有同学做实验，5.5版本还有瘦体积的效果。这样的一个小册子应用程序累积开发的时间不多，就是很高效的嘛。特别是最后博客动态这个功能，七年前我用 Objective-C 做的一个RSS阅读器耗费了我两三周的时间。同样的功能用 Swift 这套来做元旦假期两天就完成了。声明式 UI 响应式范式配合上 Swift 简洁的语法真是蛮 Cool 的。 

## 基础网络能力 

小册子应用会大量使用网络，先看看怎么用 Swift Concurrency 来做吧。 

```swift
func RSSReq(_ urlStr: String) async throws -> String? {
  guard let url = URL(string: urlStr) else {
    fatalError("wrong url")
  }
  let req = URLRequest(url: url)
  let (data, res) = try await URLSession.shared.data(for: req)
  guard (res as? HTTPURLResponse)?.statusCode == 200 else {
    fatalError("wrong data")
  }
  let dataStr = String(data: data, encoding: .utf8)
  return dataStr
}
```

如上，通过 url 可以获取到 data 和 response，和其他网络请求的方式不同的是，使用 await 后就不用繁琐的代理或闭包来进行后续的处理，代码变得更好理解，即字面意思上的 await 后执行后面的行。举个例子，获取博客 RSS 时，如果希望处理完一个 RSS 后再处理后面一个 RSS，使用 await 语法看起来就非常简洁清爽易于理解了。 

```swift
Task {
    do {
        let rssFeed = SPC.rssFeed() // 获取所有 rss 源的模型
        for r in rssFeed {
            let str = try await RSSReq(r.feedLink)
            guard let str = str else {
                break
            }
            RSSVM.handleFetchFeed(str: str, rssModel: r)
            // 在 Main Actor 更新通知数
            await rssUpdateNotis()
        }
    } catch {}
}
```

如上，当出现数据获取错误就跳过后面逻辑直接去请求下个 RSS，获取成功会更新 Main Actor 处理通知逻辑，不同队列之间切换就是这么自然，短短几行代码就都讲清楚了。 

Combine 来处理网络的优势就是能够将网络请求到数据处理，最后到数据绑定都负责了。也就是发布者、操作符和订阅者的组合。下面我通过开发指南功能的过程说明下 Combine 的用法。 

## 怎么开发指南功能 

指南的列表结构使用的是 JSON，我把列表的数据保存在仓库的议题中，通过 GitHub 的 REST API 获取议题进行展示，这样对于指南列表的内容修改丰富可以通过直接在议题中进行编辑即可，无需升级应用。 

Combine 网络请求我写在 APIRequest.swift 文件里，主要代码如下： 

```swift
final class APISev: APISevType {
    private let rootUrl: URL
    
    init(rootUrl: URL = URL(string: "https://api.github.com")!) {
        self.rootUrl = rootUrl
    }
    
    func response<Request>(from req: Request) -> AnyPublisher<Request.Res, APISevError> where Request : APIReqType {
        let path = URL(string: req.path, relativeTo: rootUrl)!
        var comp = URLComponents(url: path, resolvingAgainstBaseURL: true)!
        comp.queryItems = req.qItems
        var req = URLRequest(url: comp.url!)
        req.addValue("token \(SPC.gitHubAccessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("SwiftPamphletApp", forHTTPHeaderField: "User-Agent")
        let de = JSONDecoder()
        de.keyDecodingStrategy = .convertFromSnakeCase
        let sch = DispatchQueue(label: "GitHub API Queue", qos: .default, attributes: .concurrent)
        return URLSession.shared.dataTaskPublisher(for: req)
            .retry(3)
            .subscribe(on: sch)
            .receive(on: sch)
            .map { data, res in
                return data
            }
            .mapError { _ in
                APISevError.resError
            }
            .decode(type: Request.Res.self, decoder: de)
            .mapError { _ in
                APISevError.parseError
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
```

如上，Combine 有 decode 的操作符，能够直接指定 JSON 模型数据类型和 JSONDecoder 对象。还有重试、队列指定以及抛错误的操作符。 

一个应用的生命周期内，相同的请求会发布很多次，需要定义一个发起请求的 Subject，还有请求完成响应的 Subject。定义如下： 

```swift
private let apCustomIssuesSj = PassthroughSubject<Void, Never>()
private let resCustomIssuesSj = PassthroughSubject<IssueModel, Never>()
```

apCustomIssuesSj 会发起网络请求，代码如下： 

```swift
let resCustomIssuesSm = apCustomIssuesSj
    .flatMap { [apiSev] in
        apiSev.response(from: reqCustomIssues)
            .catch { [weak self] error -> Empty<IssueModel, Never> in
                self?.errSj.send(error)
                return .init()
            }
    }
    .share()
    .subscribe(resCustomIssuesSj)
```
上面 .catch 里errSj 发布者就是嵌套发布者，.flatMap 会让每次返回都是新发布者。apiSev.response 返回的是被类型擦除到 AnyPublisher 上，这样不同类型的发布者能够被 .flatMap 处理。闭包内的 .catch 处理能区分发布者，仅对当前发布者有效，不会影响后面发布者，导致整个管道被取消。发布者失败类型是 Never，失败本身会被连贯的处理。 

.flatMap 除了从它 map 函数里生产发布者，还有个可选参数 maxPublishers，通过这个参数可以限制一次生产的最大发布者数量，也就是你可以通过 .flatMap 对管道上游的发布者进行反压（Backpressure），maxPublishers 能有效的节流管道，按照管道内部实际上的发布速度进行反压，这个也是 Combine 相较于 RxSwift 来说的一个优势。比如当网络请求多时，你可以通过设置 .max(1) 来减轻请求对服务的压力，同时还能够保证结果到达的顺序和请求顺序的一致。 

resCustomIssuesSj 会去处理网络请求成功的数据，最后通过 .assign 将处理的数据分配给遵循 ObservableObject 协议类的 @Published 属性包装的属性 customIssues，用于响应式的更新 SwiftUI 布局数据。实现代码如下： 

```swift
let repCustomIssuesSm = resCustomIssuesSj
    .map({ issueModel in
        let str = issueModel.body?.base64Decoded() ?? ""
        let data: Data
        data = str.data(using: String.Encoding.utf8)!
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([CustomIssuesModel].self, from: data)
        } catch {
            return [CustomIssuesModel]()
        }
    })
    .assign(to: \.customIssues, on: self)
```

如上，你会发现在 .map 中还会对数据进行 base64 decode，这是因为我在仓库议题中保存的是 base64 encode 的数据，decode 成 JSON 数据再用 JSONDecoder 转为 [CustomIssuesModel] 模型 数据分配给 customIssues。 

使用 SwiftUI 写的指南列表视图，代码如下： 

```swift
struct IssuesListFromCustomView: View {
    @StateObject var vm: IssueVM
    var body: some View {
        List {
            ForEach(vm.customIssues) { ci in
                Section {
                    ForEach(ci.issues) { i in
                        NavigationLink {
                            IssueView(vm: IssueVM(repoName: SPC.pamphletIssueRepoName, issueNumber: i.number))
                        } label: {
                            Text(i.title)
                                .bold()
                        }
                    }
                } header: {
                    Text(ci.name).font(.title)
                }

            }
        }
        .alert(vm.errMsg, isPresented: $vm.errHint, actions: {})
        .onAppear {
            vm.doing(.customIssues)
        }
    }
}
```

代码中的属性包装 @StateObject 会在当前视图生命周期中保持 vm 这个属性的数据，vm 需要遵循 ObservableObject 协议，其 @Published 发布属性的值会被 SwiftUI 自动进行管理，属性 vm 的发布属性数据变化时会自动触发布局依据新数据的更新。 

上面代码中的 SwiftUI 写的布局界面效果如下： 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/19.png)

界面主体是 List 视图，根据 List 的定义，要求的输入是一个数组，数组内元素需要遵循 Identifiable，每行的返回是被 @ViewBuilder 标记的 View。ForEach 根据数组中的元素会创建能够重复使用的视图，性能接近大家熟悉的 UITableView，但是写法上简洁的不要太多，真实完美解痛点案例，😄❤️。 

指南的内容也会以 markdown 格式存在议题中，通过调用 GitHub API 的接口进行指南内容的读取。一个接口是议题接口，请求结构体定义如下： 

```swift
struct IssueRequest: APIReqType {
    typealias Res = IssueModel
    var repoName: String
    var issueNumber: Int
    var path: String {
        return "/repos/\(repoName)/issues/\(issueNumber)"
    }
    var qItems: [URLQueryItem]? {
        return nil
    }
}
```

另一个是议题留言的接口，定义如下： 

```swift
struct IssueRequest: APIReqType {
    typealias Res = IssueModel
    var repoName: String
    var issueNumber: Int
    var path: String {
        return "/repos/\(repoName)/issues/\(issueNumber)"
    }
    var qItems: [URLQueryItem]? {
        return nil
    }
}
```

实现效果如下图： 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/20.png)

指南内容放在议题中，也是希望能够通过议题留言功能，让反馈和大家经验的补充被更多人看到。 

除了语法速查的内容，关于 Swift 的一些特性，专题，还有 Combine、Concurrency、SwiftUI 这些库的使用指南内容都是采用的 GitHub API 接口读取议题方式获取的。 

读取议题接口获取指南列表的模式，也用在了开发者和仓库动态列表中。接下来我跟你说下开发者和仓库动态怎么开发的吧。 

## 开发者和仓库动态 

显示开发者信息的页面代码在 UserView.swift 里，开发者介绍信息页面如下： 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/21.png)

界面中的数据都来自 /users/(userName) 接口，获取数据逻辑在 UserVM.swift 里。数据多，但情况不复杂，布局上只要注意进行数据是否有的区分即可，布局代码如下： 

```swift
HStack {
    VStack(alignment: .leading, spacing: 10) {
        HStack() {
            AsyncImageWithPlaceholder(size: .normalSize, url: vm.user.avatarUrl)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(vm.user.name ?? vm.user.login).font(.system(.title))
                    Text("(\(vm.user.login))")
                    Text("订阅者 \(vm.user.followers) 人，仓库 \(vm.user.publicRepos) 个")
                }
                HStack {
                    ButtonGoGitHubWeb(url: vm.user.htmlUrl, text: "在 GitHub 上访问")
                    if vm.user.location != nil {
                        Text("居住：\(vm.user.location ?? "")").font(.system(.subheadline))
                    }
                }
            } // end VStack
        } // end HStack
        
        if vm.user.bio != nil {
            Text("简介：\(vm.user.bio ?? "")")
        }
        HStack {
            if vm.user.blog != nil {
                if !vm.user.blog!.isEmpty {
                    Text("博客：\(vm.user.blog ?? "")")
                    ButtonGoGitHubWeb(url: vm.user.blog ?? "", text: "访问")
                }
            }
            if vm.user.twitterUsername != nil {
                Text("Twitter：")
                ButtonGoGitHubWeb(url: "https://twitter.com/\(vm.user.twitterUsername ?? "")", text: "@\(vm.user.twitterUsername ?? "")")
            }
        } // end HStack
    } // end VStack
    Spacer()
}
```

上面代码可以看到，对于数据是否存在，SwiftUI 是可以使用 if 来进行判断是否展示视图的，这个条件判断也会存在于整个视图结构类型中被编译生成，因此更好的方式是将数据判断放到 ViewModifier 中，因为 ViewModifier 处理时机是在运行时，可以减少布局初始创建逻辑运算。 

开发者的事件和接受事件部分的数据就比介绍部分复杂些，使得界面变化也多些，事件接口是 /users/(userName)/events，接受事件接口是 /users/(userName)/received_events 。数据的复杂体现在类型上，类型种类较多，我采用的是直接处理 payload 里的字段，如果其 issue.number 字段不为空，那么就表示这个开发者事件是和议题相关，会显示 issue.title 标题，有内容的话，也就是 issue.body 不为空，继续显示议题的内容。如果字段是 comment，就表示事件是议题的留言。如果字段是 commits，表示需要列出这个事件中所有的 commit 提交及标题和描述。pullRequest 字段不为空就显示这个 PR 的标题和内容描述。字段处理逻辑代码实现如下： 

```swift
if event.payload.issue?.number != nil {
    if event.payload.issue?.title != nil {
        Text(event.payload.issue?.title ?? "").bold()
    }
    if event.payload.issue?.body != nil && event.type != "IssueCommentEvent" {
        Markdown(Document(event.payload.issue?.body ?? ""))
    }
    if event.type == "IssueCommentEvent" && event.payload.comment?.body != nil {
        Markdown(Document(event.payload.comment?.body ?? ""))
    }
}

if event.payload.commits != nil {
    ListCommits(event: event)
}

if event.payload.pullRequest != nil {
    if event.payload.pullRequest?.title != nil {
        Text(event.payload.pullRequest?.title ?? "").bold()
    }
    if event.payload.pullRequest?.body != nil {
        Markdown(Document(event.payload.pullRequest?.body ?? ""))
    }
}

if event.payload.description != nil {
    Markdown(Document(event.payload.description ?? ""))
}
```

上面代码中，对于不定数量的 commit 视图写在了一个单独的 ListCommits 视图中。只要是遵循了 View 协议，就可以作为自定义视图在其他视图中直接使用。ListCommits 代码如下： 

```swift
struct ListCommits: View {
    var event: EventModel
    var body: some View {
        ForEach(event.payload.commits ?? [PayloadCommitModel](), id: \.self) { c in
            ButtonGoGitHubWeb(url: "https://github.com/\(event.repo.name)/commit/\(c.sha ?? "")", text: "提交")
            Text(c.message ?? "")
        }
    }
}
```

上面代码你会发现一个 ButtonGoGitHubWeb的视图，进入看会发现用到了一个自定义的 ButtonStyle： 

```swift
.buttonStyle(FixAwfulPerformanceStyle())
```

FixAwfulPerformanceStyle() 的实现如下： 

```swift
/// 列表加按钮性能问题，需观察官方后面是否解决
/// https://twitter.com/fcbunn/status/1259078251340800000
struct FixAwfulPerformanceStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(EdgeInsets.init(top: 2, leading: 6, bottom: 2, trailing: 6))
            .foregroundColor(configuration.isPressed ? Color(nsColor: NSColor.selectedControlTextColor) : Color(nsColor: NSColor.controlTextColor))
            .background(configuration.isPressed ? Color(nsColor: NSColor.selectedControlColor) : Color(nsColor: NSColor.controlBackgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 6.0).stroke(Color(nsColor: NSColor.lightGray), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6.0))
            .shadow(color: Color.gray, radius: 0.5, x: 0, y: 0.5)
    }
}
```

这是社区 [@Kam-To](https://github.com/Kam-To) 提的一个 PR，是解的 macOS 上的一个性能问题，也就是在 List 中直接使用 Button，在列表快速滚动时，流畅度会有损伤，加上上面的 ButtonStyle 代码就好了。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/22.png)

原推见 [https://twitter.com/fcbunn/status/1259078251340800000](https://twitter.com/fcbunn/status/1259078251340800000)。 

开发者接受事件和事件类似，只是会多显示事件的 actor 字段内容，表明开发者接受的是谁发出的事件。事件界面如下所示： 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/23.png)

仓库整体处理和开发者类似，只是多了议题和 README 内容，数据复杂度比开发者要低。接下来我要跟你说的是如果开发者或仓库有新的提交，怎么能够获取到，并提示有更新。 

## 动态有更新，怎么提醒的 

我的思路是通过本地定时器，定期获取数据，本地记录上次浏览的位置，通过对比，看有多少新的动态没有查看，并通过 .badge 这个 ViewModifier 和 NSApp.dockTile.badgeLabel 来进行端内端外的提醒。 

### 定时器 

在 SwiftUI 中，可以使用 Combine 的 Timer.publish 发布器来设置一个定时属性，Timer.publish 指定好时间周期和队列模式等参数。比如设置一个开发者动态定时器属性，代码如下： 

```swift
let timerForRepos = Timer.publish(every: SPC.timerForReposSec, on: .main, in: .common).autoconnect()
```

然后再在 .onReceive 中执行网络数据获取操作，就可以定时获取数据了。 

```swift
.onReceive(timerForRepos, perform: { time in
    if let repoName = appVM.timeForReposEvent() {
        let vm = RepoVM(repoName: repoName)
        vm.doing(.notiRepo)
    }
})
```

获取到的数据会跟本地已经存储的数据进行对比。 

### 本地存储 

本地数据存储，我用的是 SQLite.swift，这个库是使用 Swift 对 SQLite 做了一层封装，使用很简便，在 DBHandler.swift 里有数据库初始化和表的创建相关代码，DBDevNoti.swift 中的 DevsNotiDataHelper 有对数据操作的代码，DBDevNoti 定义了数据表的结构。如何使用可以参考 SQLite.swift 官方的[指南](https://github.com/stephencelis/SQLite.swift/blob/master/Documentation/Index.md)，里面讲得非常详细清楚。 

用 DB Browser for SQLite 应用可以查看本地的数据库。下面是用它查看记录的 RSS 的数据，如图：

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/29.png)

更新未读数的判断逻辑，我封到了一个函数里，代码如下： 

```swift
func updateDBDevsInfo(ems: [EventModel]) {
    do {
        if let f = try DevsNotiDataHelper.find(sLogin: userName) {
            var i = 0
            var lrid = f.lastReadId
            for em in ems {
                if i == 0 {
                    lrid = em.id
                }
                if em.id == f.lastReadId {
                    break
                }
                i += 1
            }
            i = f.unRead + i
            do {
                let _ = try DevsNotiDataHelper.update(i: DBDevNoti(login: userName, lastReadId: lrid, unRead: i))
            } catch {}
        } // end if let f
    } catch {}
} // end func updateDBDevsInfo
```

如上面代码所示，入参 ems 是获取到的最新数据，先从本地数据库中取到上次最新的阅读编号 lastReadId，迭代 ems，如果第一个 ems 的编号就和本地数据库 lastReadId 一样，那表示无新动态，如果没有就开始计数，直到找到相等的 lastReadId 位置，记了多少数就表示有多少新动态。 

### 提醒 

列表、Sidebar 还有 macOS 系统的 Dock 上都可以显示新状态数的提醒。列表和 Sidebar 直接使用 .badge ViewModifier 就可以展示未读数了，效果如下： 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/24.png)

Dock 栏提示设置需要用到系统的 NSApp，代码如下： 

```swift
NSApp.dockTile.showsApplicationBadge = true
NSApp.dockTile.badgeLabel = "\(count)"
```

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/28.png)

小册子里还可以查看 Swift 社区里博主们博客更新动态。我接着跟你说说我怎么做的。 

## 博客 RSS 更新动态 

博客 RSS 的数据获取我在前面基础网络能力中已经说了。所有解析逻辑我都写在了工程 RSSReader/Parser/ 目录下的 ParseStandXMLTagTokens.swift、ParseStandXMLTags.swift、ParseStandXML.swift 三个文件中，实现思路我在先前[《如何对 iOS 启动阶段耗时进行分析》](https://ming1016.github.io/2019/12/07/how-to-analyze-startup-time-cost-in-ios/)文章的“优化后如何保持？”章节有详细说明。 

根据 RSS 的 XML 结构，定义 Model 结构如下： 

```swift
struct RSSModel: Identifiable {
    var id = UUID()
    var title = ""
    var description = ""
    var feedLink = ""
    var siteLink = ""
    var language = ""
    var lastBuildDate = ""
    var pubDate = ""
    var items = [RSSItemModel]()
    var unReadCount = 0
}

struct RSSItemModel: Identifiable {
    var id = UUID()
    var guid = ""
    var title = ""
    var description = ""
    var link = ""
    var pubDate = ""
    var content = ""
    var isRead = false
}
```

根据这个结构，也会在本地数据库设计对应的两个表，两个表的增删改代码分别在 DBRSSFeed.swift 和 DBRSSItems.swift 里。表的结构和 Model 的结构基本一致，方便内存和磁盘进行切换。更新提醒逻辑和前面说的开发者动态更新逻辑区别在于，RSS 使用 isRead 标记有没有阅读过，直接在本地数据里 count 出 isRead 字段值为 false 的数量就是需要提醒的数。 

新 RSS 的添加会先在本地数据库中查找是否有存在，依据的是文章的 url，如果不存在就会添加到数据库中设置为未读作为提醒。 

RSS 里文章的内容是 HTML，显示内容使用的是 WebKit 库，要在 SwiftUI 中使用，需要封装下，代码如下： 

```swift
import SwiftUI
import WebKit

struct WebUIView : NSViewRepresentable {

    let html: String

    func makeNSView(context: Context) -> some WKWebView {
        return WKWebView()
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.loadHTMLString(html, baseURL: nil)
    }
}
```

效果如下图： 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/25.png)

## 云打包 

工程如果是本地编译，在 SwiftPamphletAppConfig.swift 的 gitHubAccessToken 中添上 token 就可以了，如果想快速打包使用小册子，使用 Github Action Workflow 编译，无需在本地操作、也无需开启 Xcode 设置个人开发帐号，只需设置 personal access token(PAT) 在 repository 设定中 action secrets，并命名为 PAT。Frok 此 repository，设置 PAT，手动启用 action，等候约3分钟即可下载档案，往后专案更新时，只需 fetch and merge，action 会自动进行。非常感谢社区 [@powenn](https://github.com/powenn) 开发的这个 Github Action。 

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/26.png)

![](/uploads/develop-macos-with-swiftui-combine-concurrency-aysnc-await-actor/27.png)

## 推荐可以学习的开源仓库 

为了避免闭门造车，可以多关注些开源项目，以下这些仓库是我放在小册子里可以关注到更新动态的项目，这里作为附录列下，也可以直接在小册子里查看。除了 Swift 也有些非常有趣的项目，希望可以丰富到你的开发生活。 

### 好库 

#### 官方 

- [swift](https://github.com/apple/swift)
- [swift-evolution](https://github.com/apple/swift-evolution) 提案 
- [llvm-project](https://github.com/llvm/llvm-project) 编译器 

#### 新鲜事 

- [iOS-Weekly](https://github.com/SwiftOldDriver/iOS-Weekly) 老司机 iOS 周报 
- [awesome-swift](https://github.com/matteocrippa/awesome-swift)
- [Brochure](https://github.com/ming1016/Brochure) 戴铭的小册子 

#### 封装易用功能 

- [SwifterSwift](https://github.com/SwifterSwift/SwifterSwift) Handy Swift extensions 

#### 网络 

- [Alamofire](https://github.com/Alamofire/Alamofire)
- [socket.io-client-swift](https://github.com/socketio/socket.io-client-swift)

#### 图片 

- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [Nuke](https://github.com/kean/Nuke)

#### 文字处理 

- [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI)

#### 动画 

- [kavsoft-swiftui-animations](https://github.com/recherst/kavsoft-swiftui-animations)

#### 持久化存储 

- [SQLite.swift](https://github.com/stephencelis/SQLite.swift)
- [GRDB.swift](https://github.com/groue/GRDB.swift)
- [realm-cocoa](https://github.com/realm/realm-cocoa)

#### 编程范式 

- [RxSwift](https://github.com/ReactiveX/RxSwift) 函数响应式编程 
- [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [awesome-ios-architecture](https://github.com/onmyway133/awesome-ios-architecture)

#### 路由 

- [swiftui-navigation](https://github.com/pointfreeco/swiftui-navigation)

#### 静态检查 

- [SwiftLint](https://github.com/realm/SwiftLint)
#### 系统能力 

- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)

#### 接口 

- [OAuthSwift](https://github.com/OAuthSwift/OAuthSwift)
- [OAuth2](https://github.com/p2/OAuth2)

#### macOS程序 

- [open-source-mac-os-apps](https://github.com/serhii-londar/open-source-mac-os-apps) 开源 macOS 程序合集 
- [NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire)
- [TelegramSwift](https://github.com/overtake/TelegramSwift)

#### 性能和工程构建 

- [tuist](https://github.com/tuist/tuist) 创建和维护 Xcode projects 文件 
- [vscode-swift](https://github.com/swift-server/vscode-swift) VSCode 的 Swift 扩展 

#### 音视频 

- [iina](https://github.com/iina/iina)
- [HaishinKit.swift](https://github.com/shogo4405/HaishinKit.swift) RTMP, HLS 
- [AudioKit](https://github.com/AudioKit/AudioKit)

#### 服务器 

- [vapor](https://github.com/vapor/vapor)

### 探索库 

#### SwiftUI扩展 

- [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX) 扩展 SwiftUI 
- [SDWebImageSwiftUI](https://github.com/SDWebImage/SDWebImageSwiftUI)
- [ASCollectionView](https://github.com/apptekstudios/ASCollectionView) SwiftUI collection 
- [SwiftUI-Introspect](https://github.com/siteline/SwiftUI-Introspect) SwiftUI 引入 UIKit 
- [SwiftUIKitView](https://github.com/AvdLee/SwiftUIKitView) 在 SwiftUI 中 使用 UIKit 

#### 接口应用 

- [Weather](https://github.com/bpisano/Weather) 天气应用 
- [MovieSwiftUI](https://github.com/Dimillian/MovieSwiftUI) 电影 MovieDB 应用 
- [NotionSwift](https://github.com/chojnac/NotionSwift)
- [RedditOS](https://github.com/Dimillian/RedditOS) SwiftUI 写的 Reddit客户端 
- [reddit-swiftui](https://github.com/carson-katri/reddit-swiftui) SwiftUI 写的 Reddit客户端 
- [SwiftHN](https://github.com/Dimillian/SwiftHN) Hacker News 阅读 
- [EhPanda](https://github.com/tatsuz0u/EhPanda)
- [MortyUI](https://github.com/Dimillian/MortyUI) GraphQL + SwiftUI 开发的瑞克和莫蒂应用 
- [V2ex-Swift](https://github.com/Finb/V2ex-Swift) V2EX 客户端 
- [iOS](https://github.com/v2er-app/iOS) V2EX 客户端 
- [weibo_ios_sdk](https://github.com/sinaweibosdk/weibo_ios_sdk)
- [MNWeibo](https://github.com/miniLV/MNWeibo) Swift5 + MVVM 微博客户端 
- [octokit.swift](https://github.com/nerdishbynature/octokit.swift) Swift API Client for GitHub 
- [GitHawk](https://github.com/GitHawkApp/GitHawk) iOS app for GitHub 
- [free-api](https://github.com/fangzesheng/free-api)
- [Graphaello](https://github.com/nerdsupremacist/Graphaello) SwiftUI 中使用 GraphQL 的工具 
- [tmdb](https://github.com/nerdsupremacist/tmdb) GraphQL 包装电影数据接口 

#### macOS 

- [FileWatcher](https://github.com/eonist/FileWatcher) macOS 上监听文件变化 
- [XcodeCleaner-SwiftUI](https://github.com/waylybaye/XcodeCleaner-SwiftUI) 清理 Xcode 
- [eul](https://github.com/gao-sun/eul) SwiftUI 写的 macOS 状态监控工具 
- [ACHNBrowserUI](https://github.com/Dimillian/ACHNBrowserUI) SwiftUI 写的动物之森小助手程序 
- [RegExPlus](https://github.com/lexrus/RegExPlus) 正则表达式 

#### 应用 

- [Clendar](https://github.com/vinhnx/Clendar) SwiftUI 写的日历应用 

#### 游戏 

- [isowords](https://github.com/pointfreeco/isowords) 单词搜索游戏 
- [awesome-games-of-coding](https://github.com/michelpereira/awesome-games-of-coding) 教你学编程的游戏收集 
- [OpenEmu](https://github.com/OpenEmu/OpenEmu) 视频游戏模拟器 
- [swiftui-2048](https://github.com/jVirus/swiftui-2048)
- [gb-studio](https://github.com/chrismaltby/gb-studio) 拖放式复古游戏创建器 

#### 新技术展示 

- [Moments-SwiftUI](https://github.com/JakeLin/Moments-SwiftUI) SwiftUI、Async、Actor 

#### 新鲜事 

- [weekly](https://github.com/ruanyf/weekly) 科技爱好者周刊 

#### 聚合 

- [chinese-independent-blogs](https://github.com/timqian/chinese-independent-blogs)
- [awesome-swiftui](https://github.com/vlondon/awesome-swiftui)
- [SwiftUI](https://github.com/ivanvorobei/SwiftUI)
- [GitHub-Chinese-Top-Charts](https://github.com/kon9chunkit/GitHub-Chinese-Top-Charts) GitHub中文排行榜 
- [awesome-swiftui](https://github.com/onmyway133/awesome-swiftui)
- [About-SwiftUI](https://github.com/Juanpe/About-SwiftUI) 汇总 SwiftUI 的资料 

#### 知识管理 

- [logseq](https://github.com/logseq/logseq) 更好的知识管理工具 

#### 性能和工程构建 

- [periphery](https://github.com/peripheryapp/periphery) 检测 Swift 无用代码 
- [ViewInspector](https://github.com/nalexn/ViewInspector) SwiftUI Runtime introspection 和 单元测试 

#### 网络 

- [Knot](https://github.com/Lojii/Knot) 使用 SwiftNIO 实现 HTTPS 抓包 
- [async-http-client](https://github.com/swift-server/async-http-client) 使用 SwiftNIO 开发的 HTTP 客户端 
- [Get](https://github.com/kean/Get)
- [awesome-selfhosted](https://github.com/awesome-selfhosted/awesome-selfhosted) 网络服务及上面的应用 
- [Starscream](https://github.com/daltoniam/Starscream) WebSocket 
- [ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG)
- [swift-request](https://github.com/carson-katri/swift-request) 声明式的网络请求 

#### 图形 

- [SwiftSunburstDiagram](https://github.com/lludo/SwiftSunburstDiagram) SwiftUI 图表 

#### 系统 

- [swift-project1](https://github.com/spevans/swift-project1) Swift编写内核，可在 Mac 和 PC 启动 

#### Apple 

- [swift-corelibs-foundation](https://github.com/apple/swift-corelibs-foundation)
- [swift-package-manager](https://github.com/apple/swift-package-manager)
- [swift-markdown](https://github.com/apple/swift-markdown)
- [sourcekit-lsp](https://github.com/apple/sourcekit-lsp)
- [swift-nio](https://github.com/apple/swift-nio)
- [swift-syntax](https://github.com/apple/swift-syntax) 解析、生成、转换 Swift 代码 
- [swift-crypto](https://github.com/apple/swift-crypto) CryptoKit 的开源实现 

#### 待分类 

- [public-apis](https://github.com/public-apis/public-apis)
- [WWDC](https://github.com/insidegui/WWDC)
- [Actions](https://github.com/sindresorhus/Actions)
- [the-book-of-secret-knowledge](https://github.com/trimstray/the-book-of-secret-knowledge)
- [awesome-math](https://github.com/rossant/awesome-math)
- [AltSwiftUI](https://github.com/rakutentech/AltSwiftUI) 类 SwiftUI 
- [ios-stack-kit](https://github.com/gymshark/ios-stack-kit) 类 SwiftUI 
- [OpenCombine](https://github.com/OpenCombine/OpenCombine) Combine 的开源实现 
- [CombineExt](https://github.com/CombineCommunity/CombineExt) 对 Combine 的补充 
- [ReSwift](https://github.com/ReSwift/ReSwift) 单页面状态和数据管理 
- [DeviceKit](https://github.com/devicekit/DeviceKit) UIDevice 易用封装 
- [SwiftCharts](https://github.com/ivanschuetz/SwiftCharts)
- [FileKit](https://github.com/nvzqz/FileKit) 文件操作 
- [Files](https://github.com/JohnSundell/Files) 文件操作 
- [PathKit](https://github.com/kylef/PathKit) 文件操作 
- [Publish](https://github.com/JohnSundell/Publish) 静态站点生成器 
- [IceCream](https://github.com/caiyue1993/IceCream) CloudKit 同步 Realm 数据库 
- [RichTextView](https://github.com/tophat/RichTextView)
- [edhita](https://github.com/tnantoka/edhita)
- [MarkdownView](https://github.com/keitaoouchi/MarkdownView)
- [Down](https://github.com/johnxnguyen/Down) fast Markdown 
- [SwiftDown](https://github.com/qeude/SwiftDown) Swift 写的可换主题的 Markdown 编辑器组件 
- [Komondor](https://github.com/shibapm/Komondor) Git Hooks for Swift projects 
- [SwiftGen](https://github.com/SwiftGen/SwiftGen) 代码生成 
- [netfox](https://github.com/kasketis/netfox) 获取所有网络请求 
- [iOS-Developer-Roadmap](https://github.com/BohdanOrlov/iOS-Developer-Roadmap)
- [ios-oss](https://github.com/kickstarter/ios-oss)
- [WordPress-iOS](https://github.com/wordpress-mobile/WordPress-iOS)
- [VersaPlayer](https://github.com/josejuanqm/VersaPlayer)
- [firefox-ios](https://github.com/mozilla-mobile/firefox-ios)
- [PostgresApp](https://github.com/PostgresApp/PostgresApp)
- [Moya](https://github.com/Moya/Moya)
- [BlueSocket](https://github.com/Kitura/BlueSocket)
- [BluetoothKit](https://github.com/rhummelmose/BluetoothKit)
- [BiometricAuthentication](https://github.com/rushisangani/BiometricAuthentication) FaceID or TouchID authentication 
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
- [Advance](https://github.com/timdonnelly/Advance) Physics-based animations 
- [Spring](https://github.com/MengTo/Spring) 动画 
- [UIImageColors](https://github.com/jathu/UIImageColors) 获取图片主次颜色 
- [GPUImage3](https://github.com/BradLarson/GPUImage3) Metal 实现 
- [Macaw](https://github.com/exyte/Macaw) SVG 
- [Magnetic](https://github.com/efremidze/Magnetic) SpriteKit气泡支持SwiftUI 
- [Swift-Radio-Pro](https://github.com/analogcode/Swift-Radio-Pro) 电台应用 
- [SKPhotoBrowser](https://github.com/suzuki-0000/SKPhotoBrowser) 图片浏览 
- [swift-algorithm-club](https://github.com/raywenderlich/swift-algorithm-club)
- [Cache](https://github.com/hyperoslo/Cache)
- [SwiftyUserDefaults](https://github.com/sunshinejr/SwiftyUserDefaults)
- [MonitorControl](https://github.com/MonitorControl/MonitorControl) 亮度和声音控制 
- [Commander](https://github.com/kylef/Commander) 命令行 
- [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)
- [Carthage](https://github.com/Carthage/Carthage)
- [Charts](https://github.com/danielgindi/Charts)
- [Quick](https://github.com/Quick/Quick) 测试框架 
- [ijkplayer](https://github.com/bilibili/ijkplayer) 播放器 
- [dosbox-pure](https://github.com/schellingb/dosbox-pure) DOS 游戏模拟器 
- [HackingWithSwift](https://github.com/twostraws/HackingWithSwift) 示例代码 
- [fsnotes](https://github.com/glushchenko/fsnotes)
- [CotEditor](https://github.com/coteditor/CotEditor)
- [JKSwiftExtension](https://github.com/JoanKing/JKSwiftExtension) Swift常用扩展、组件、协议 
- [iOS-Nuts-And-Bolts](https://github.com/infinum/iOS-Nuts-And-Bolts)
- [ExtensionKit](https://github.com/gtokman/ExtensionKit)
- [publish](https://github.com/johnsundell/publish) 用 swift 来写网站 
- [awesome-software-architecture](https://github.com/mehdihadeli/awesome-software-architecture) 软件架构 
- [hacker-scripts](https://github.com/NARKOZ/hacker-scripts) 程序员的活都让机器干的脚本（真实故事） 
- [clean-architecture-swiftui](https://github.com/nalexn/clean-architecture-swiftui) 干净完整的SwiftUI+Combine例子，包含网络和单元测试等 
- [CareKit](https://github.com/carekit-apple/CareKit) 使用 SwiftUI 开发健康相关的库 
- [awesome-result-builders](https://github.com/carson-katri/awesome-result-builders) Result Builders 
- [SwiftSpeech](https://github.com/Cay-Zhang/SwiftSpeech) 苹果语言识别封装库，已适配 SwiftUI 
- [NextLevel](https://github.com/NextLevel/NextLevel) 相机 
- [MaLiang](https://github.com/Harley-xk/MaLiang) 基于 Metal 的涂鸦绘图库 
- [awesome-blockchain-cn](https://github.com/chaozh/awesome-blockchain-cn) 区块链 awesome 
- [XcodesApp](https://github.com/RobotsAndPencils/XcodesApp) Xcode 多版本安装 
- [Mocker](https://github.com/WeTransfer/Mocker) Mock Alamofire and URLSession 
- [ReduxUI](https://github.com/gre4ixin/ReduxUI) SwiftUI Redux 架构 
- [5GUIs](https://github.com/ZeeZide/5GUIs) 可以分析程序用了哪些库，用了LLVM objdump 
- [episode-code-samples](https://github.com/pointfreeco/episode-code-samples)
- [PackageList](https://github.com/SwiftPackageIndex/PackageList)
- [awesome](https://github.com/sindresorhus/awesome) 内容广 
- [open-source-ios-apps](https://github.com/dkhamsing/open-source-ios-apps) 开源的完整 App 例子 
- [Model3DView](https://github.com/frzi/Model3DView) 毫不费力的使用 SwiftUI 渲染 3d models 
- [ios-crash-dump-analysis-book](https://github.com/faisalmemon/ios-crash-dump-analysis-book) iOS Crash Dump Analysis Book 
- [SVGView](https://github.com/exyte/SVGView) 支持 SwiftUI 的 SVG 解析渲染视图 
- [Sourcery](https://github.com/krzysztofzablocki/Sourcery) Swift 元编程 
- [TIL](https://github.com/jessesquires/TIL) 学习笔记 
- [ipatool](https://github.com/majd/ipatool) 下载 ipa 
- [Ink](https://github.com/JohnSundell/Ink) Markdown 解析器 




































