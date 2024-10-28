---
title: 小册子之如何使用 SwiftData 开发 SwiftUI 应用
date: 2024-05-18 00:17:12
tags: [SwiftUI]
categories: App
banner_img: /uploads/pamphlet-series-swiftdata/01.png
---

以下内容已整理到小册子中，本文会随着系统更新和我更多的实践而新增和更新，你可以下载[“戴铭的开发小册子”](https://apps.apple.com/cn/app/%E6%88%B4%E9%93%AD%E7%9A%84%E5%BC%80%E5%8F%91%E5%B0%8F%E5%86%8C%E5%AD%90/id1609702529?mt=12)应用，来跟踪查看本文内容新增和更新。小册子应用的代码可以在 [Github](https://github.com/ming1016/SwiftPamphletApp) 上查看。

本文属于小册子系列中的一篇，已发布系列文章有：

- 【本篇】[小册子之如何使用 SwiftData 开发 SwiftUI 应用](https://starming.com/2024/05/18/pamphlet-series-swiftdata/)
- [小册子之简说 Widget 小组件](https://starming.com/2024/05/18/pamphlet-series-widget/)
- [小册子之 List、Lazy 容器、ScrollView、Grid 和 Table 数据集合 SwiftUI 视图](https://starming.com/2024/05/18/pamphlet-series-listdataview/)
- [小册子之详说 Navigation、ViewThatFits、Layout 协议等布局 SwiftUI 组件](https://starming.com/2024/05/18/pamphlet-series-layout/)
- [小册子之 Form、Picker、Toggle、Slider 和 Stepper 表单相关 SwiftUI 视图](https://starming.com/2024/05/18/pamphlet-series-form/)
- [小册子之 SwiftUI 动画](https://starming.com/2024/05/25/pamphlet-series-animation/)

小册子代码里有大量 SwiftData 实际使用实践的代码。

在 Swift 中，有许多库可以用于处理数据，包括但不限于 SwiftData、CoreData、Realm、SQLite.swift 等。这些库各有优势。

但，如果使用 SwiftData，你可以在 Swift 中更加方便地处理数据。SwiftData 是 Apple 在 WWDC23 上推出的一个新的数据持久化框架，它是 CoreData 的替代品，提供了更简单、更易用的 API。

## 创建@Model模型

先说说如何创建 SwiftData 模型。

### 创建

用 `@Model` 宏装饰类

```swift
@Model
final class Article {
    let title: String
    let author: String
    let content: String
    let publishedDate: Date
    
    init(title: String, author: String, content: String, publishedDate: Date) {
        self.title = title
        self.author = author
        self.content = content
        self.publishedDate = publishedDate
    }
}
```

以上代码创建了一个 Article 模型，包含了标题、作者、内容和发布日期。

以下数据类型默认支持：
- 基础类型：Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64, Float, Double, Bool, String, Date, Data 等
- 复杂的类型：Array, Dictionary, Set, Optional, Enum, Struct, Codable 等
- 模型关系：一对一、一对多、多对多

默认数据库路径： `Data/Library/Application Support/default.store`

### `@Attribute`

接下来说说如何使用 `@Attribute` 宏。

一些常用的：

- spotlight：使其能出现在 Spotlight 搜索结果里
- unique：值是唯一的
- externalStorage：值存储为二进制数据
- transient：值不存储
- encrypt：加密存储

使用方法
```swift
@Attribute(.externalStorage) var imgData: Data? = nil
```

二进制会将其存储为单独的文件，然后在数据库中引用文件名。文件会存到  `Data/Library/Application Support/.default_SUPPORT/_EXTERNAL_DATA` 目录下。

### `@Transient` 不存

如果有的属性不希望进行存储，可以使用 `@Transient`

```swift
@Model
final class Article {
    let title: String
    let author: String
    @Transient var content: String
    ...
}
```

### transformable

SwiftData 除了能够存储字符串和整数这样基本类型，还可以存储更复杂的自定义类型。要存储自定义类型，可用 transformable。

```swift
@Model
final class Article {
    let title: String
    let author: String
    let content: String
    let publishedDate: Date
    @Attribute(.transformable(by: UIColorValueTransformer.self)) var bgColor: UIColor
    ...
}
```

UIColorValueTransformer 类的实现

```swift
class UIColorValueTransformer: ValueTransformer {
    
    // return data
    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            return data
        } catch {
            return nil
        }
    }
    
    // return UIColor
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        
        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            return color
        } catch {
            return nil 
        }
    }
}
```

注册

```swift
struct SwiftPamphletAppApp: App {
    init() {
        ValueTransformer.setValueTransformer(UIColorValueTransformer(), forName: NSValueTransformerName("UIColorValueTransformer"))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Article.self])
        }
    }
}
```
## SwiftData-模型关系


使用 ``@Relationship` 添加关系，但是不加这个宏也可以，SwiftData 会自动添加模型之间的关系。

```swift
@Model
final class Author {
    var name: String

    @Relationship(deleteRule: .cascade, inverse: \Brew.brewer)
    var articles: [Article] = []
}

@Model
final class Article {
    ...
    var author: Author
}
```

默认情况 deleteRule 是 `.nullify`，这个删除后只会删除引用关系。`.cascade` 会在删除用户后删除其所有文章。

SwiftData 可以添加一对一，一对多，多对多的关系。

限制关系表数量
```swift
@Relationship(maximumModelCount: 5)
    var articles: [Article] = []
```


## 容器配置modelContainer

### 多模型

配置方法

```swift
@main
struct SomeApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Article.self, Author.self])
    }
}
```

有关系的两个模型，只需要加父模型，SwiftData 会推断出子模型。

### 数据存内存

```swift
let configuration = ModelConfiguration(inMemory: true)
let container = try ModelContainer(for: schema, configurations: [configuration])
```

### 数据只读

```swift
let config = ModelConfiguration(allowsSave: false)
```

### 自定义存储文件和位置

如果要指定数据库存储的位置，可以按下面写法：

```swift
@main
struct SomeApp: App {
    var container: ModelContainer

    init() {
        do {
            let storeURL = URL.documentsDirectory.appending(path: "database.sqlite")
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: Article.self, configurations: config)
        } catch {
            fatalError("Failed")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### iCloud 支持

如果要添加 iCloud 支持，需要先确定模型满足以下条件：
- 没有唯一约束
- 关系是可选的
- 有所值有默认值

iCloud 支持操作步骤：
- 进入 Signing & Capabilities 中，在 Capability 里选择 iCloud
- 选中 CloudKit 旁边的框
- 设置 bundle identifier
- 再按 Capability，选择 Background Modes
- 选择 Remote Notifications

### 指定部分表同步到 iCloud

使用多个 ModelConfiguration 对象来配置，这样可以指定哪个配置成同步到 iCloud，哪些不同步。

### 添加多个配置

```swift
@main
struct SomeApp: App {
    var container: ModelContainer
    init() {
        do {
            let c1 = ModelConfiguration(for: Article.self)
            let c2 = ModelConfiguration(for: Author.self, isStoredInMemoryOnly: true)
            container = try ModelContainer(for: Article.self, Author.self, configurations: c1, c2)
        } catch {
            fatalError("Failed")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### 撤销和重做

创建容器时进行指定
```swift
.modelContainer(for: Article.self, isUndoEnabled: true)
```

这样 modelContext 就可以调用撤销和重做函数。
```swift
struct SomeView: View {
    @Environment(\.modelContext) private var context
    var body: some View {
        Button(action: {
            context.undoManager?.undo()
        }, label: {
            Text("撤销")
        })
    }
}
```

### context

View 之外的地方，可以通过 ModelContainer 的 context 属性来获取 modelContext。

```swift
let context = container.mainContext
let context = ModelContext(container)
```

### 预先导入数据

方法如下：

```swift
.modelContainer(for: Article.self) { result in
    do {
        let container = try result.get()

        // 先检查有没数据
        let descriptor = FetchDescriptor<Article>()
        let existingArticles = try container.mainContext.fetchCount(descriptor)
        guard existingArticles == 0 else { return }

        // 读取 bundle 里的文件
        guard let url = Bundle.main.url(forResource: "articles", withExtension: "json") else {
            fatalError("Failed")
        }

        let data = try Data(contentsOf: url)
        let articles = try JSONDecoder().decode([Article].self, from: data)

        for article in articles {
            container.mainContext.insert(article)
        }
    } catch {
        print("Failed")
    }
}
```
## 增删modelContext

### 添加保存数据

```swift
struct SomeView: View {
   @Environment(\.modelContext) var context
   ...

   var body: some View {
         ...
         Button(action: {
             self.add()
         }, label: {
             Text("添加")
         })
   }

   func add() {
      ...
      context.insert(article)
   }
}
```

默认不用使用 `context.save()`，SwiftData 会自动进行保存，如果不想自动保存，可以在容器中设置

```swift
var body: some Scene {
   WindowGroup {
      ContentView()
   }
   .modelContainer(for: Article.self, isAutosaveEnabled: false)       
}
```

### 编辑和删除数据

编辑数据使用 `@Bindable`。

```swift
struct SomeView: View {
    @Bindable var article: Article
    @Environment(\.modelContext) private var modelContext
    ...
    
    var body: some View {
        Form {
            TextField("文章标题", text: $article.title)
            ...
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("删除") {
                    modelContext.delete(article)
                }
            }
        }
        ...
    }
}
```
## SwiftData-检索

### `@Query`
使用 `@Query` 会从数据库中获取数据。

```swift
@Query private var articles: [Article]
```

`@Query` 还支持 filter、sort、order 和 animation 等参数。

```swift
@Query(sort: \Article.title, order: .forward) private var articles: [Article]
```

sort 可支持多个 SortDescriptor，SwiftData 会按顺序处理。

```swift
@Query(sort: [SortDescriptor(\Article.isArchived, order: .forward),SortDescriptor(\Article.updateDate, order: .reverse)]) var articles: [Article]
```

### Predicate

filter 使用的是 `#Predicate` 

```swift
static var now: Date { Date.now }

@Query(filter: #Predicate<Article> { article in
    article.releaseDate > now
}) var draftArticles: [Article]
```

Predicate 支持的内置方法主要有 `contains`、`allSatisfy`、`flatMap`、`filter`、`subscript`、`starts`、`min`、`max`、`localizedStandardContains`、`localizedCompare`、`caseInsensitiveCompare` 等。

```swift
@Query(filter: #Predicate<Article> { article in
    article.title.starts(with: "苹果发布会")
}) var articles: [Article]
```

需要注意的是 `.isEmpty`  不能使用  `article.title.isEmpty == false` ，否则会崩溃。

### FetchDescriptor

FetchDescriptor 可以在模型中查找数据，而不必在视图层做。

```swift
@Model
final class Article {
    var title: String
    ...
    static var all: FetchDescriptor<Article> {
        FetchDescriptor(sortBy: [SortDescriptor(\Article.updateDate, order: .reverse)])
    }
}

struct SomeView: View {   
    @Query(Article.all) private var articles: [Article]
    ...
}
```

### 获取数量而不加载

使用 `fetchCount()` 方法，可完成整个计数，且很快，内存占用少。

```swift
let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.words > 50 })
let count = (try? modelContext.fetchCount(descriptor)) ?? 0
```

### fetchLimit 限制获取数量

```swift
var descriptor = FetchDescriptor<Article>(
  predicate: #Predicate { $0.read },
  sortBy: [SortDescriptor(\Article.updateDate,
           order: .reverse)])
descriptor.fetchLimit = 30
let articles = try context.fetch(descriptor)

// 翻页
let pSize = 30
let pNumber = 1
var fetchDescriptor = FetchDescriptor<Article>(sortBy: [SortDescriptor(\Article.updateDate, order: .reverse)])
fetchDescriptor.fetchOffset = pNumber * pSize
fetchDescriptor.fetchLimit = pSize
```

### 限制获取的属性

只请求要用的属性

```swift
var fetchDescriptor = FetchDescriptor<Article>(sortBy: [SortDescriptor(\.updateDate, order: .reverse)])
fetchDescriptor.propertiesToFetch = [\.title, \.updateDate]
```
## SwiftData-处理大量数据

SwiftData 模型上下文有个方法叫 `enumerate()`，可以高效遍历大量数据。

```swift
let descriptor = FetchDescriptor<Article>()
...

do {
    try modelContext.enumerate(descriptor, batchSize: 1000) { article in
        ...
    }
} catch {
    print("Failed.")
}
```

其中 batchSize 参数是调整批量处理的数量，也就是一次加载多少对象。因此可以通过这个值来权衡内存和IO数量。这个值默认是 5000。
## SwiftData多线程

创建一个 Actor，然后 SwiftData 上下文在其中执行操作。

```swift
@ModelActor
actor DataHandler {}

extension DataHandler {
    func addInfo() throws -> IOInfo {
        let info = IOInfo()
        modelContext.insert(info)
        try modelContext.save()
        return info
    }
    ...
}
```

使用

```swift
Task.detached {
    let handler = DataHandler()
    let item = try await handler.addInfo()   
    ...
}
```
## SwiftData-版本迁移

以下的小改动 SwiftData 会自动执行轻量迁移：

- 增加模型
- 增加有默认值的新属性
- 重命名属性
- 删除属性
- 增加或删除 `.externalStorage` 或 `.allowsCloudEncryption` 属性。
- 增加所有值都是唯一属性为 `.unique`
- 调整关系的删除规则

其他情况需要用到版本迁移，版本迁移步骤如下：

- 用 VersionedSchema 创建 SwiftData 模型的版本
- 用 SchemaMigrationPlan 对创建的版本进行排序
- 为每个迁移定义一个迁移阶段

设置版本

```swift
enum ArticleV1Schema: VersionedSchema {
    static var versionIdentifier: String? = "v1"
    static var models: [any PersistentModel.Type] { [Article.self] }

    @Model
    final class Article {
        ...
    }
}
```

SchemaMigrationPlan 轻量迁移

```swift
enum ArticleMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ArticleV1Schema.self, ArticleV2Schema.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: ArticleV1Schema.self,
        toVersion: ArticleV2Schema.self
    )
}
```

自定义迁移

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: ArticleV1Schema.self,
    toVersion: ArticleV2Schema.self,
    willMigrate: { context in
        // 合并前的处理
    },
    didMigrate: { context in
        // 合并后的处理
    }
)
```
## SwiftData-调试

CoreData 的调试方式依然适用于 SwiftData。

你可以设置启动参数来让 CoreData 打印出执行的 SQL 语句。在你的项目中，选择 "Product" -> "Scheme" -> "Edit Scheme"，然后在 "Arguments" 标签下的 "Arguments Passed On Launch" 中添加 -com.apple.CoreData.SQLDebug 1。这样，每当 CoreData 执行 SQL 语句时，都会在控制台中打印出来。

使用 `-com.apple.CoreData.SQLDebug 3` 获取后台更多信息。


## SwiftData-资料

### WWDC

23
- [Dive deeper into SwiftData - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10196)
- [Migrate to SwiftData - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10189)
- [Meet SwiftData - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10187)
- [Model your schema with SwiftData - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10195)
- [Build an app with SwiftData - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10154)