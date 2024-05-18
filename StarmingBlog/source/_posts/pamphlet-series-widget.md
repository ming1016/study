---
title: 小册子之简说 Widget 小组件
date: 2024-05-18 08:07:31
tags: [SwiftUI]
categories: App
banner_img: /uploads/pamphlet-series-widget/01.png
---

以下内容已整理到小册子中，小册子代码在 [Github](https://github.com/ming1016/SwiftPamphletApp) 上，可以在 macOS 应用商店安装[“戴铭的开发小册子”](https://apps.apple.com/cn/app/%E6%88%B4%E9%93%AD%E7%9A%84%E5%BC%80%E5%8F%91%E5%B0%8F%E5%86%8C%E5%AD%90/id1609702529?mt=12)应用查看。

Widge 允许开发者在用户的主屏幕或通知中心展示应用的信息。Widget 可以提供快速的信息预览，或者提供快速访问应用的方式。

开发 Widget 的基本步骤如下：

1. **创建 Widget Extension**：在 Xcode 中，你需要创建一个新的 Widget Extension。这将会生成一个新的 target，包含了创建 Widget 所需的基本代码。

2. **定义 Timeline Entry**：Timeline Entry 是 Widget 数据的模型。你需要创建一个遵循 `TimelineEntry` 协议的结构体，定义你的 Widget 所需的数据。

3. **创建 Widget View**：Widget View 是 Widget 的用户界面。你需要创建一个 `View`，展示你的 Widget 的内容。

4. **实现 Timeline Provider**：Timeline Provider 是 Widget 数据的提供者。你需要创建一个遵循 `TimelineProvider` 协议的结构体，提供 Widget 的数据。

5. **配置 Widget**：在 Widget 的主结构体中，你需要配置你的 Widget，包括它的类型（静态或者动态）、数据提供者、视图等。

6. **测试 Widget**：在模拟器或者真机上测试你的 Widget，确保它的数据和视图都按预期工作。

接下来，我们将详细介绍 Widget 的开发流程。

## 小组件-StaticConfiguration 静态配置

在 Xcode 中，File -> New -> Target，选择 Widget Extension。这将会生成一个新的 target，包含了创建 Widget 所需的基本代码。

以下是一个简单的小组件代码示例：

```swift
import WidgetKit
import SwiftUI

// Timeline Entry
struct ArticleEntry: TimelineEntry {
    let date: Date
    let title: String
}

// Widget View
struct ArticleWidgetView : View {
    let entry: ArticleEntry

    var body: some View {
        Text(entry.title)
    }
}

// Timeline Provider
struct ArticleTimelineProvider: TimelineProvider {
    typealias Entry = ArticleEntry
    
    func placeholder(in context: Context) -> Entry {
        // 占位大小，内容不会显示
        return ArticleEntry(date: Date(), title: "Placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
        let entry = ArticleEntry(date: Date(), title: "Snapshot")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = ArticleEntry(date: Date(), title: "Timeline")
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// Widget Configuration
@main
struct ArticleWidget: Widget {
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.starming.articleWidget",
            provider: ArticleTimelineProvider()
        ) { entry in
            ArticleWidgetView(entry: entry)
        }
        .configurationDisplayName("Article Widget")
        .description("这是一个 Article Widget.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}
```

在上面的代码中，我们定义了一个 ArticleWidget 小组件，它包含了一个 ArticleEntry 数据模型、一个 ArticleWidgetView 视图、一个 ArticleTimelineProvider 数据提供者和一个 ArticleWidget 配置。

## 小组件-AppIntentConfiguration

iOS 17 开始可以使用 AppIntentConfiguration 来配置小组件，这样可以让小组件和 AppIntent 交互。这样可以让小组件和 App 之间的进行交互。

下面是一个简单的小组件代码示例，展示了如何使用 AppIntentConfiguration 来配置小组件和 AppIntent 交互

```swift
import SwiftUI
import WidgetKit
import AppIntents

struct ArticleWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "com.starming.articleWidget",
            intent: ArticleIntent.self,
            provider: ArticleIntentProvider()
        ) { entry in
            ArticleWidgetView(entry: entry)
        }
        .configurationDisplayName("Article Widget")
        .description("这是一个 Article Widget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ArticleWidgetView: View {
    var entry: IntentProvider.Entry
    var body: some View {
        Text(entry.author)
    }
}

struct ArticleIntentProvider: AppIntentTimelineProvider {

    func snapshot(for configuration: ArticleIntent, in context: Context) async -> ArticleEntry {
        return .init(
            date: Date(),
            author: "snapshot"
        )
    }

    func placeholder(in context: Context) -> ArticleEntry {
        return .init(
            date: Date(),
            author: "某人"
        )
    }

    func timeline(for configuration: ArticleIntent, in context: Context) async -> Timeline<ArticleEntry> {
        return Timeline(
            entries: [
                .init(date: Date(),
                      author: configuration.author,
                      rate: await ArticleStore().rate())],
            policy: .never)
    }
}

struct ArticleEntry: TimelineEntry {
    let date: Date
    let author: String
    var rate: Int = 0
    //...
}

// 放在主应用中和小组件交互
struct ArticleIntent: WidgetConfigurationIntent {
    
    static var title: LocalizedStringResource  = "文章"
    var author: String = "某某某"

    func perform() async throws -> some IntentResult {
        //...
        return .result()
    }
}

class ArticleStore {
    //... SwiftData 相关配置
    @MainActor
    func rate() async -> Int {
        //... 获取
        return 5
    }
}
```

如上代码所示，我们定义了一个 ArticleWidget 小组件，它包含了一个 ArticleIntent 数据模型、一个 ArticleWidgetView 视图、一个 ArticleIntentProvider 数据提供者和一个 ArticleWidget 配置。

## 小组件-配置选项

### 显示区域

iOS 17 新增显示区域配置，有下面四种

- homeScreen：主屏幕
- lockScreen：锁屏
- standBy：待机
- iPhoneWidgetsOnMac：iPhone 上的 Mac 小组件

设置小组件不在哪个区域显示某尺寸。

```swift
struct SomeWidget: Widget {
    ...
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            ... { entry in
            ...
        }
        // 在 StandBy 中取消显示 systemSmall 尺寸
        .disfavoredLocations([.standBy], for: [.systemSmall])
    }
}
```

### 取消内容边距

使用 `.contentMarginsDisabled()` 取消内容边距。

```swift
struct SomeWidget: Widget {
    ...
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            ... { entry in
            ...
        }
        // 使 Content margin 失效
        .contentMarginsDisabled()
    }
}
```

每个平台内容边距大小不同，环境变量 `\.widgetContentMargins` 可以读取内容边距的大小。

### 取消背景删除

在 StandBy 和 LockScreen 的某些情况，小组件的背景是会被自动删除的。

使用 `containerBackgroundRemovable()` 修饰符可以取消背景删除。

```swift
struct SomeWidget: Widget {
    ...
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            ... { entry in
            ...
        }
        // 取消背景删除
        .containerBackgroundRemovable(false)
        // 让自己的背景可以全覆盖
        .contentMarginsDisabled()
    }
}
```

### 后台网络处理

```swift
.onBackgroundURLSessionEvents { (identifier, completion) in
    //...
}
```
## AppIntentTimelineProvider

AppIntentConfiguration 需要 AppIntentTimelineProvider，AppIntentTimelineProvider 需要实现 `snapshot`、`placeholder` 和 `timeline` 三个方法来确定小组件在展示和实际运行时间线时的视图和数据。

```swift
struct ArticleIntentProvider: AppIntentTimelineProvider {

    func snapshot(for configuration: ArticleIntent, in context: Context) async -> ArticleEntry {
        return .init(
            date: Date(),
            author: "snapshot"
        )
    }

    func placeholder(in context: Context) -> ArticleEntry {
        return .init(
            date: Date(),
            author: "某人"
        )
    }

    func timeline(for configuration: ArticleIntent, in context: Context) async -> Timeline<ArticleEntry> {
        return Timeline(
            entries: [
                .init(date: Date(),
                      author: configuration.author,
                      rate: await ArticleStore().rate())],
            policy: .never)
    }
}

struct ArticleEntry: TimelineEntry {
    let date: Date
    let author: String
    var rate: Int = 0
    //...
}
````

## Widget View

### 不同的大小设置不同视图

```swift
struct ArticleWidgetView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family

  @ViewBuilder
  var body: some View {
    switch family {
    case .systemSmall:
        SomeViewSmall()
    default:
      SomeViewDefault()
    }
  }
}
```

### 锁屏小组件

让小组件支持锁屏

```swift
struct ArticleWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(
            ...
        ) { entry in
            ...
        }
        ...
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,

            // 添加支持到 Lock Screen widgets
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}
```

### 不同类型 widgetFamily 实现不同视图

```swift
struct ArticleWidgetView : View {
   
    let entry: ViewSizeEntry
    // 获取 widget family 值
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularWidgetView()
        case .accessoryCircular:
            CircularWidgetView()
        case .accessoryInline:
            InlineWidgetView()
        default:
            ArticleWidgetView(entry: entry)
        }
    }
}
```

### 不同渲染模式实现不同视图

小组件有三种不同的渲染模式：

- Full-color：主屏用
- Vibrant：用于待机模式和锁屏
- The accented：用于手表

```swift
struct ArticleWidgetView: View {
    let entry: Entry
    
    @Environment(\.widgetRenderingMode) private var renderingMode
    
    var body: some View {
        switch renderingMode {
        case .accented:
            AccentedWidgetView(entry: entry)
        case .fullColor:
            FullColorWidgetView(entry: entry)
        case .vibrant:
            VibrantWidgetView(entry: entry)
        default:
            DefaultView()
        }
    }
}
```

### 视图交互

使用 AppIntent

```swift
struct ArticleWidgetView : View {
    var entry: IntentProvider.Entry

    var body: some View {
        VStack(spacing: 20) {
            ...

            Button(intent: RunIntent(rate: entry.rate), label: {
                ...
            })
        }
    }
}
```
## 刷新小组件

### 通过 Text 视图更新

倒计时

```swift

let futureDate = Calendar.current.date(byAdding: components, to: Date())!

// 日期会在 Text 视图中动态变化

```

```swift
struct CountdownWidgetView: View {
    
    var body: some View {
        Text(futureDate(), style: .timer)
    }
    
    private func futureDate() -> Date {
        let components = DateComponents(second: 10)
        let futureDate = Calendar.current.date(byAdding: components, to: Date())!
        return futureDate
    }
}
```

### Timeline Provider 更新

在 timeline 方法中实现，entries 包含了不同更新的数据。

```swift
func timeline(for configuration: ArticleIntent, in context: Context) async -> Timeline<ArticleEntry> {
    return Timeline(
        entries: [
            .init(date: Date(),
                  author: configuration.author,
                  rate: await ArticleStore().rate())],
        policy: .never)
}
```

### 更新策略

3 种类型的刷新策略：
- `atEnd`：上个刷新完成直接进入下个刷新，但是进入下一个刷新的时间由系统决定。
- `after(Date)`：指定进入下个刷新的时间，但是具体时间还是由系统说了算，因此可以理解为是指定的是最早进入下个刷新的时间。
- `never`：不会进入下个刷新，除非显式调用 `reloadTimelines(ofKind:)`

举例，指定下个刷新周期至少是上个周期结束10秒后：

```swift
let lastUpdateDate = entries.last!.date
let nextUpdateDate = Calendar.current.date(byAdding: DateComponents(second: 10), to: lastUpdate)!

let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
```

### Relevance 优先级

App 自定义刷新 Timeline 的优先级，使用 Relevance。先在 TimelineEntry 里定义：

```swift
struct ArticleEntry: TimelineEntry {
    let date: Date
    ...
    let relevance: TimelineEntryRelevance?
}
```

在 timeline 方法中根据必要刷新程序，定义不同 relevance 的值。

### App 主动刷新

```swift
// 刷新单个小组件
WidgetCenter.shared.reloadTimelines(ofKind: "CountryWidget")

// 刷新所有小组件
WidgetCenter.shared.reloadAllTimelines()
```

### 刷新小组件的最佳实践

调试时刷新率不会有限制，生产环境每天最多40到70次，相当于每15到60分钟刷新一次。

## 小组件动画

### Text 视图动态时间

利用 Text 的动态时间能力

### timeline 动画

timeline 是由一组时间和数据组成的，每次刷新时，小组件通过和上次数据不一致加入动画效果。

默认情况小组件使用的是弹簧动画。我们也可以添加转场（Transition）、动画（Animation）和内容过渡（Content Transition）动画效果。

### 文本内容过渡动画效果

```swift
.contentTransition(.numericText(value: rate))
```

### 从底部翻上来的专场

```swift
.transition(.push(from: .bottom))
```
## 小组件-远程定时获取数据

在 TimelineProvider 中的 timeline 方法中加入请求逻辑

```swift
func timeline(for configuration: RunIntent, in context: Context) -> Void) async -> Timeline<ArticleEntry> {
    guard let article = try? await ArticleFetch.fetchNewestArticle() else {
        return
    }
    let entry = ArticleEntry(date: Date(), article: article)
    
    // 下次在 30 分钟后再请求
    let afterDate = Calendar.current.date(byAdding: DateComponents(minute: 30), to: Date())!
    return Timeline(entries: [entry], policy: .after(afterDate))
}
```

以上代码中，我们在 timeline 方法中请求了最新的文章数据，并且设置了下次请求的时间是当前时间的 30 分钟后。


## 小组件-获取位置权限更新内容

小组件获取位置权限和主应用 target 里获取方式很类似，步骤：

- 在 info 里添加 `NSWidgetUseLocation = ture`。
- 使用 CLLocationManager 来获取位置信息，设置较低的精度。
- 用 `isAuthorizedForWidgetUpdates` 请求位置权限。

## 支持多个小组件

widget bundle 可以支持多个小组件。

```swift
@main
struct FirstWidgetBundle: WidgetBundle {
    
    @WidgetBundleBuilder
    var body: some Widget {
        FirstWidget()
        SecondWidget()
        ...
        SecondWidgetBundle().body
    }
}

struct SecondWidgetBundle: WidgetBundle {

    @WidgetBundleBuilder
    var body: some Widget {
        SomeWidgetOne()
        SomeWidgetTwo()
        ...
    }
}
```
## 获取小组件形状

不同设备小组件大小和形状都不同，比如要加个边框，就很困难。这就需要使用 `ContainerRelativeShape` 来获取 Shape 视图容器。

```swift
var body: some View {
  ZStack {
    ContainerRelativeShape()
        .inset(by: 2)
        .fill(.pink)
    Text("Hello world")
    ...
  }
}
```

## 小组件-Deep link

medium 和 large 的小组件可以使用 Link，small 小组件使用 `.widgetURL` 修饰符。

## 小组件访问SwiftData

Wdiget target 访问主应用 target 的 SwiftData 数据步骤如下：

- 对主应用和 Widget 的 target 中的 Signing & Capabilities 都添加 App Groups，并创建一个新组，名字相同。
- SwiftData 的模型同时在主应用和 Widget 的 target 中。
- StaticConfiguration 或 AppIntentConfiguration 中添加 `modelContainer()` 修饰符，让 SwiftData 的容器可用。

## 小组件-参考资料

- [Complications and widgets: Reloaded - WWDC22 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2022/10050/)
- [WidgetKit 官方](https://developer.apple.com/documentation/WidgetKit)
- 官方指南 [Creating Lock Screen Widgets and Watch Complications](https://developer.apple.com/documentation/WidgetKit/Creating-lock-screen-widgets-and-watch-complications)
- [WidgetKit 主题](https://developer.apple.com/widgets/)
- [Debugging Widgets](https://developer.apple.com/documentation/widgetkit/debugging-widgets)
- [WidgetKit Session](https://developer.apple.com/videos/all-videos/?q=WidgetKit)
- [Complications and widgets: Reloaded - WWDC22 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2022/10050)

WWDC
- 介绍怎么将 widgets 添加到 lock screen 的 session [Complications and widgets: Reloaded](https://developer.apple.com/videos/play/wwdc2022-10050)。对应的实例代码 [Adding widgets to the Lock Screen and watch faces](https://developer.apple.com/documentation/widgetkit/adding_widgets_to_the_lock_screen_and_watch_faces)


23
- [Bring widgets to life - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10028)
- [Build widgets for the Smart Stack on Apple Watch - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10029)
- [Bring widgets to new places - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10027)

22
- [Go further with Complications in WidgetKit - WWDC22 - Videos - Apple Developer](https://developer.apple.com/wwdc22/10051) 进一步了解 WidgetKit 中的复杂功能
- [Challenge: WidgetKit workshop - Discover - Apple Developer](https://developer.apple.com/news/?id=2q8t97ob) 挑战：WidgetKit 研讨会
- [Complications and widgets: Reloaded - WWDC22 - Videos - Apple Developer](https://developer.apple.com/wwdc22/10050) 复杂功能和小组件：重新载入
- [Go further with Complications in WidgetKit - WWDC22 - Videos - Apple Developer](https://developer.apple.com/wwdc22/10051) 进一步了解 WidgetKit 中的复杂功能

21
- [Principles of great widgets - WWDC21 - Videos - Apple Developer](https://developer.apple.com/wwdc21/10048) 优秀小组件的原则
- [Add intelligence to your widgets - WWDC21 - Videos - Apple Developer](https://developer.apple.com/wwdc21/10049) 让您的小组件更加智能
- [Documentation Spotlight: Dynamically display timely data in your widgets - Discover - Apple Developer](https://developer.apple.com/news/?id=zawi5f1g) 聚焦文档：在小组件中适时动态显示数据


20
- [Build SwiftUI views for widgets - WWDC20 - Videos - Apple Developer](https://developer.apple.com/wwdc20/10033) 为小组件构建 SwiftUI 视图。中文：[WWDC20 - Build SwiftUI views for widgets － 小专栏](https://xiaozhuanlan.com/topic/3691507248)
- [Widgets code-along - Discover - Apple Developer](https://developer.apple.com/news/?id=yv6so7ie) 小组件编写临摹课程
- [Widgets Code-along, part 1: The adventure begins - WWDC20 - Videos - Apple Developer](https://developer.apple.com/wwdc20/10034) 小组件编程临摹课程1：开始学习
- [Widgets Code-along, part 2: Alternate timelines - WWDC20 - Videos - Apple Developer](https://developer.apple.com/wwdc20/10035) 小组件编程临摹课程2：变更时间线
- [Widgets Code-along, part 3: Advancing timelines - WWDC20 - Videos - Apple Developer](https://developer.apple.com/wwdc20/10036) 小组件编程临摹课程3：加速时间线
- [Meet WidgetKit - WWDC20 - Videos - Apple Developer](https://developer.apple.com/wwdc20/10028) 为你介绍 WidgetKit
- [Widgets code-along - Discover - Apple Developer](https://developer.apple.com/news/?id=yv6so7ie) 小组件编程临摹课程
- [Add configuration and intelligence to your widgets - WWDC20 - Videos - Apple Developer](https://developer.apple.com/wwdc20/10194) 为小组件添加配置和智能
- [Meet WidgetKit - WWDC20 - Videos - Apple Developer](https://developer.apple.com/wwdc20/10028) 为你介绍 WidgetKit

