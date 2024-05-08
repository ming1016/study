---
title: 使用 SwiftUI 开发 RSS 阅读器
date: 2023-04-24 15:51:34
tags: [iOS, Apple, SwiftUI]
categories: Programming
banner_img: /uploads/swiftui-rss-reader/09.png
---

![](/uploads/swiftui-rss-reader/01.png)

在 Apple 加速器活动和字节内分享了使用 SwiftUI 做 RSS 阅读器的一点心得。可能你还不知道什么是 RSS 阅读器，简单来说 RSS 是一些博客和新闻网站，甚至是播客和视频平台发布他们的内容更新的一种 XML 格式，阅读器就是通过请求这个 XML 以获取他们内容更新的客户端。

这就有了接下来几个问题：
![](/uploads/swiftui-rss-reader/02.png)

![](/uploads/swiftui-rss-reader/03.png)

![](/uploads/swiftui-rss-reader/04.png)

目前已有 Reeder 和 NetNewsWire 等 RSS 阅读器，那么为什么还要再开发一个呢，早在14年我曾做过一个，陆续也更新过，后来还是以 Reeder 作为主力，feedly 作为服务，后来 feedly 有些不稳定，我又改成本地获取 feed 的方式，但是改成本地模式后设备同步又成了问题。正好最近几年苹果在界面、数据流和存储上都做了很大的功能加强。于是我打算将以前 objc、rac和 FMDB 替换成 SwiftUI 和 CoreData 技术，同时补上以前缺少的一些功能，比如添加管理feed，不同设备同步订阅 feed、文章已读状态和收藏信息等功能。

先说下怎么订阅 RSS。

![](/uploads/swiftui-rss-reader/05.png)

![](/uploads/swiftui-rss-reader/06.png)

![](/uploads/swiftui-rss-reader/07.png)


如上图所示先通过链接获取待解析的数据，以及 mimeType，通过 mimeType 看里面是否包含如下描述：
```swift
application/atom+xml
application/rss+xml
application/json
application/feed+json
text/xml
application/xml
```

包含的话就可以判断是 RSS。

![](/uploads/swiftui-rss-reader/08.png)

如果不是的话就需要手动从网页里获取 RSS 的链接，方法如下：
```swift
mime.contains("text/html")
SwiftSoup.parse(homepageHTML)
htmlDom.select("link[rel=alternate]")
```

其中 SwiftSoup 是一个专门用来将 HTML 解析成 DOM 对象的库。一般 RSS 的链接会在属性键值是 rel 和 alternate 的 Link 这个标签里。但是很多网站并没有遵循这个规范，那么就需要在链接后直接通过添加以下文件名来查找哪个是它的 RSS 链接：
```swift
["feed.xml","rss.xml","atom.xml","feed","feed.rss","rss","index.xml"]
```

找到了 RSS 的链接就可以获取到它的数据，接下来就是对数据的处理，根据 RSS 的规范，RSS 的数据主要是以下三种。

![](/uploads/swiftui-rss-reader/09.png)

对应的结构体如下：

![](/uploads/swiftui-rss-reader/10.png)

RSS 的图标的获取方式有两种

![](/uploads/swiftui-rss-reader/11.png)

对处理好的数据需要进行本地的存储，目前不管是 Apple 还是三方库主要都是基于 SQLite 的封装。估计是因为 SQLite 开销小，支持大多数 SQL 92 标准语法，采用标准的 ANSI-C 代码，很容易在多个平台运行，同时 SQLite 还支持所有 SQL 用来保障数据安全和完整性的事务属性，比如原子性、一致性、隔离性和持久性。以下是 iOS 上一些主要基于 SQLite 封装库：

![](/uploads/swiftui-rss-reader/12.png)

![](/uploads/swiftui-rss-reader/13.png)

我选择的是 Core Data，首先是 Core Data 的 API 很强，将复杂数据建模和操作的 SQL 语句都做成了可视化和对象模式操作。多个数据对象之间的关联关系也做了很多自动处理。Core Data 还使用了惰性加载的方式，只有在需要时才从存储区域获取数据，以节省内存，提高执行效率。

Core Data 的使用需要对数据库进行设置。

![](/uploads/swiftui-rss-reader/14.png)

在读取实体存储时可以设置 Core Spotlight 以及进行一些调试测试工作。

![](/uploads/swiftui-rss-reader/16.png)


Core Data 对数据的增删改和检索操作都是在 NSManagerObjectContext 中完成的。

![](/uploads/swiftui-rss-reader/17.png)

如果要支持 CloudKit，NSManagerObjectContext 初始化时需要在合并策略做一些设置。context 的数据操作都是基于对象操作的方式，比如增加一个 feed 就是在 context 中创建一个 feed 的对象，然后对其字段对应的属性进行设置即可。

![](/uploads/swiftui-rss-reader/18.png)

删除就是用 context 的 delete 方法将对要删除数据对应的对象进行删除即可。

![](/uploads/swiftui-rss-reader/19.png)

修改就是对读取的对象进行设置。

![](/uploads/swiftui-rss-reader/20.png)

检索有两种方式，一种是创建一个 Controller，使用 lazy 来修饰检索检索结果，惰性加载以节省内存。数据变化会在 NSFetchedResultsController 代理里进行回调，在回调里可以更新 @Published 属性包装的属性以及时同步展示更新的数据。

![](/uploads/swiftui-rss-reader/21.png)

另一种检索方式是使用 @FetchRequest 属性包装，写法更加简洁。

![](/uploads/swiftui-rss-reader/22.png)

下面是 RSS 数据操作对应的代码。

![](/uploads/swiftui-rss-reader/23.png)

添加 Feed 的代码

```swift
let newFeed = WebFeedMO(context: stack.context)
newFeed.id = UUID()
newFeed.createAt = Date.now
newFeed.homePageURL = inputURL
stack.save()
await handleAFeed(webFeed: newFeed) // 文章
```

删除 Feed

```swift
for a in webFeed.allElements {
    stack.context.delete(a)
}
stack.deleteWebFeed(webFeed)
```

检索 Feed 列表

```swift
let fetch = WebFeedMO.fetchRequest()
let sortDescriptorUnreadCount = NSSortDescriptor(key: "unreadCount", ascending: false)
let sortDescriptorCreateAt = NSSortDescriptor(key: "createAt", ascending: false)
fetch.sortDescriptors = [sortDescriptorUnreadCount, sortDescriptorCreateAt]

let controller = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: "webFeeds")
controller.delegate = self

try? controller.performFetch()
```

![](/uploads/swiftui-rss-reader/24.png)

Feed 里文章的列表检索

```swift
let fetch = ArticleMO.fetchRequest()
let sortDescriptor = NSSortDescriptor(key: "datePublished", ascending: false)
fetch.sortDescriptors = [sortDescriptor]

let controller = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: "newArticles")
controller.delegate = self
try? controller.performFetch()
```

标记已读

```swift
@Published var selectedArticle: ArticleMO? {
    willSet(newValue) {
        newValue?.read = true
        selectedWebFeed?.countUnreadArticles()
    }
}
```

全部标记已读

```swift
let countElement = selectedWebFeed?.allElements.count ?? 0
var index = 0
for a in selectedWebFeed?.allElements ?? [] {
    index += 1
    if a.read == false {
        a.read = true
    }
    if countElement > 1000 && index > 1000 && a.favourite == false {
        stack.context.delete(a)
    }
}
// 最后重置未读总数
selectedWebFeed?.countUnreadArticles()
```

![](/uploads/swiftui-rss-reader/25.png)

收藏状态的切换直接对布尔属性 favourite 执行 toggle 方法。

```swift
selectedArticle?.favourite.toggle()
selectedArticle?.dateModified = Date.now
```

工具栏中的分享功能可以直接使用 SwiftUI 内置的 ShareLink 视图。Item 的 placement 对于不同平台的位置会有不同。

```swift
.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
        Menu {
            Button { ... } label: {
                Label("拷贝链接", systemImage: "doc.on.doc")
            }
            Divider()
            ShareLink("分享", item: link)
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
    ToolbarItemGroup(placement: .automatic) {
        Button { ... } label: {
            Label("收藏", systemImage: "star")
        }
        Button { ... } label: {
            Label("浏览器", systemImage: "safari")
        }
    }
} // end toolbar
```

由于网站提供的 RSS 是静态的，因此每次获取数据时需要进行和本地存储的数据进行比对去重。

![](/uploads/swiftui-rss-reader/26.png)

Core Data 提供了一种通过简单配置约束就可以去重的方法。具体方法如上图所示。

但是如果要支持 iCloud 就没法使用唯一约束这个功能。因此只能回到老办法，手动比对。

![](/uploads/swiftui-rss-reader/27.png)

为了提升大量数据添加的效率，可以使用 NSBatchInsertRequest。正常情况下，在使用 Core Data 进行大量数据插入时，应用程序需要为每个插入操作都创建上下文和执行请求。这样会导致上下文过度膨胀和查询操作的重复，并且会对内存和 CPU 带来负担。而 NSBatchInsertRequest 则能够通过批量插入的方式一次性将多条数据插入到 Core Data 中，并且执行速度要比逐条插入要快得多。NSBatchInsertRequest 实际上是在底层利用 SQLite 数据库的 INSERT INTO 语法来执行批量插入操作。这种方式通过一次性将数据提交给 SQLite，可以减少插入操作所需的检查、协调和锁定操作，从而提高插入操作的效率和性能。当使用 NSBatchInsertRequest 执行批量插入时，Core Data 会首先创建一个临时表，然后将待插入的数据全部插入到该临时表中。接着，Core Data 会使用关联操作将临时表中的数据一次性插入到实际的数据库表中，从而进一步提高了数据插入的效率。NSBatchInsertRequest 还提供了一些可用的参数设置选项，开发者可以根据具体的需求进行灵活配置。例如，通过设置 batchSize 参数，可以控制批量插入时每个批次所包含的最大行数，以避免内存的过度消耗；通过设置 propertiesToUpdate 参数，可以在批量插入后更新指定的属性值，从而避免对整个对象进行额外的查询和更新操作。

![](/uploads/swiftui-rss-reader/28.png)

![](/uploads/swiftui-rss-reader/29.png)

Core Data 里的数据可以通过 iCloud 实现多设备的同步，比如我在 macOS 上订阅、阅读和收藏的信息能够无缝切换到手机和 iPad 上。未来支持 iCloud 可以进行如下的设置：

![](/uploads/swiftui-rss-reader/30.png)

支持 iCloud 也会有一些限制，对于我目前来说最大限制就是不支持唯一约束，另外数据表结构更改后老版本的兼容也是需要注意的，这是由于 iCloud 是云端数据统一传输，并不会兼容多版本。

![](/uploads/swiftui-rss-reader/31.png)

通过以下方法可以让兼容合并更安全。

![](/uploads/swiftui-rss-reader/32.png)

应用支持 iCloud 后会有 cloudd 这个后台进程对 iCloud 服务的同步和管理，定期检查 iCloud 上数据是否需要同步到本地设备，或者本地数据是否需要传到 iCloud。 apsd 进程会将数据的更新以通知的方式推送到其他设备，dasd 进程会对 iCloud 的数据进行处理然后交给应用进程。对这个流程的调试就是基于上面提到的这四个进程进行日志记录。

![](/uploads/swiftui-rss-reader/33.png)

![](/uploads/swiftui-rss-reader/34.png)

另外 Core Data 还支持一些调试参数，除了 iCloud 还可以支持多线程、SQL、合并等信息的日志打印。

![](/uploads/swiftui-rss-reader/35.png)

为了节省 iCloud 空间大小，对于文章内容这样数据量大的数据就不用支持 iCloud 了，方法是如下：

![](/uploads/swiftui-rss-reader/36.png)

另外，Core Data 里的数据还能够很容易的支持 spotlight 索引，方便在应用外能够被检索。

![](/uploads/swiftui-rss-reader/37.png)

![](/uploads/swiftui-rss-reader/38.png)

界面使用的是 NavigationSplitView。代码如下：
```swift
struct HomeThreeColumnView: View {
    @EnvironmentObject var webFeedController: WebFeedController

    var body: some View {
        NavigationSplitView {
            SidebarView() // 左侧频道列表
        } content: {
            AWebFeedArticlesView() // 文章列表
        } detail: {
            ArticleWebView() // 文章内容
        }
    } // end body
}
```

NavigationSplitView 可以同时显示主视图和辅助视图。实现了 iOS 系统中常见的 iPad 多窗口布局模式，允许用户同时操作两个视图，提高了应用程序的多任务处理能力和用户体验。NavigationSplitView 提供了一组简洁易用的 API，开发者可以通过少量的代码实现大部分常见的多窗口布局需求。例如，只需要设置主视图和辅助视图的内容即可快速创建一个 NavigationSplitView，而无需手动管理视图控制器的层次结构。NavigationSplitView 还支持自定义视图拆分行为、边缘滑动手势等功能。

数据处理，包括 Core Data 的初始化配置和增删改和检索等我都放在了 Controller 里，Controller 的关键代码如下：

```swift
final class WebFeedController: NSObject ,ObservableObject {
    @Published var selectedWebFeed: WebFeedMO?
    @Published var selectedArticle: ArticleMO?
    
    @Published private(set) var webFeeds: [WebFeedMO] = []
    @Published private(set) var newArticles: [ArticleMO] = [] // 最新文章
    @Published private(set) var favoriteArticles: [ArticleMO] = [] // 收藏的文章

    var stack: NRCDStack
    
    init(stack: NRCDStack) {
        ...
        webFeeds = fetchedResults.fetchedObjects ?? []
        newArticles = fetchedNewArticlesResults.fetchedObjects ?? []
        favoriteArticles = fetchFavoriteArticlesResults.fetchedObjects ?? []
    }
    
    // 获取所有 feed 源
    lazy var fetchedResults: NSFetchedResultsController<WebFeedMO> = { ... }()
    // 获取最新 article
    lazy var fetchedNewArticlesResults: NSFetchedResultsController<ArticleMO> = { ... }()
    // 获取收集 article
    lazy var fetchFavoriteArticlesResults: NSFetchedResultsController<ArticleMO> = { ... }()
}

// MARK: - NSFetchedResultsControllerDelegate
// 跟踪变化，在回调中处理。
extension WebFeedController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        webFeeds = fetchedResults.fetchedObjects ?? []
        newArticles = fetchedNewArticlesResults.fetchedObjects ?? []
        favoriteArticles = fetchFavoriteArticlesResults.fetchedObjects ?? []
    }
}

// MARK: - 数据 CRUD 操作
extension WebFeedController {
    // 更新全部 Feed
    func updateAllFeeds() async { ... }
    
    // MARK: - Feed 的操作
    // 添加 Feed
    @discardableResult
    func createFeed(inputURL: String, nameForDisplay: String = "") -> WebFeedMO { ... }

    // 删除操作，删掉一个 Feed
    func deleteWebFeed(_ webFeed: WebFeedMO) {
        stack.deleteWebFeed(webFeed)
    }
    
    // 更新
    func updateFeedByModel(for webFeed: WebFeedMO, model: FeedModel) { ... }
    
    // MARK: - 文章的操作
    // 收藏的文章
    func fetchFavoriteArticles() {
        favoriteArticles = fetchFavoriteArticlesResults.fetchedObjects ?? []
    }
    
    // 最新文章
    func fetchNewArticles() {
        newArticles = fetchedNewArticlesResults.fetchedObjects ?? []
    }
    
    // 收藏
    func favoriteArticle() {
        selectedArticle?.favourite.toggle()
        selectedArticle?.dateModified = Date.now
    }
    
    // 清空所选 feed 下所有文章
    func deleteAll() { ... }
    
    // 标记全部已读
    func markAllAsRead() { ... }
    
    // 新增文章
    func createArticleByModel(for webFeed: WebFeedMO, model: ArticleModel) async { ... }
 }
```

应用最终效果如下图：

![](/uploads/swiftui-rss-reader/42.png)



