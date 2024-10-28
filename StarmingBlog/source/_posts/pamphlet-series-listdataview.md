---
title: 小册子之 List、Lazy 容器、ScrollView、Grid 和 Table 数据集合 SwiftUI 视图
date: 2024-05-18 09:06:54
tags: [SwiftUI]
categories: App
banner_img: /uploads/pamphlet-series-listdataview/01.png
---

以下内容已整理到小册子中，本文会随着系统更新和我更多的实践而新增和更新，你可以下载[“戴铭的开发小册子”](https://apps.apple.com/cn/app/%E6%88%B4%E9%93%AD%E7%9A%84%E5%BC%80%E5%8F%91%E5%B0%8F%E5%86%8C%E5%AD%90/id1609702529?mt=12)应用，来跟踪查看本文内容新增和更新。小册子应用的代码可以在 [Github](https://github.com/ming1016/SwiftPamphletApp) 上查看。

本文属于小册子系列中的一篇，已发布系列文章有：

- [小册子之如何使用 SwiftData 开发 SwiftUI 应用](https://starming.com/2024/05/18/pamphlet-series-swiftdata/)
- [小册子之简说 Widget 小组件](https://starming.com/2024/05/18/pamphlet-series-widget/)
- 【本篇】[小册子之 List、Lazy 容器、ScrollView、Grid 和 Table 数据集合 SwiftUI 视图](https://starming.com/2024/05/18/pamphlet-series-listdataview/)
- [小册子之详说 Navigation、ViewThatFits、Layout 协议等布局 SwiftUI 组件](https://starming.com/2024/05/18/pamphlet-series-layout/)
- [小册子之 Form、Picker、Toggle、Slider 和 Stepper 表单相关 SwiftUI 视图](https://starming.com/2024/05/18/pamphlet-series-form/)
- [小册子之 SwiftUI 动画](https://starming.com/2024/05/25/pamphlet-series-animation/)

## ForEach

### 使用

在 SwiftUI 中，`ForEach` 是一个结构体，它可以创建一组视图，每个视图都有一个与数据集中的元素相对应的唯一标识符。这对于在列表或其他集合视图中显示数据非常有用。

以下视图集会用到 ForEach：

- List
- ScrollView
- LazyVStack / LazyHStack
- Picker
- Grids (LazyVGrid / LazyHGrid)

例如，如果你有一个 `BookmarkModel` 的数组，并且你想为每个书签创建一个文本视图，你可以这样做：

```swift
struct ContentView: View {
    var bookmarks: [BookmarkModel]

    var body: some View {
        List {
            ForEach(bookmarks) { bookmark in
                Text(bookmark.name)
            }
        }
    }
}
```

`ForEach` 遍历 `bookmarks` 数组，并为每个 `BookmarkModel` 对象创建一个 `Text` 视图。`bookmark` 参数是当前遍历的 `BookmarkModel` 对象。

`BookmarkModel` 必须遵循 `Identifiable` 协议，这样 SwiftUI 才能知道如何唯一地标识每个视图。在你的代码中，`BookmarkModel` 已经有一个 `id` 属性，所以你只需要让 `BookmarkModel` 遵循 `Identifiable` 协议即可：

```swift
final class BookmarkModel: Identifiable {
    // your code here
}
```

### 使用索引范围进行编号

你可以使用 `ForEach` 结构体的另一个版本，它接受一个范围作为其数据源。这个范围可以是一个索引范围，这样你就可以为每个项目编号。

例如，如果你有一个 `BookmarkModel` 的数组，并且你想为每个书签创建一个文本视图，并在前面添加一个编号，你可以这样做：

```swift
struct ContentView: View {
    var bookmarks: [BookmarkModel]

    var body: some View {
        List {
            ForEach(bookmarks.indices, id: \.self) { index in
                Text("\(index + 1). \(bookmarks[index].name)")
            }
        }
    }
}
```

在这个例子中，`ForEach` 遍历 `bookmarks` 数组的索引，并为每个 `BookmarkModel` 对象创建一个 `Text` 视图。`index` 参数是当前遍历的索引。我们使用 `\(index + 1). \(bookmarks[index].name)` 来创建一个带有编号的文本视图。请注意，我们使用 `index + 1` 而不是 `index`，因为数组的索引是从 0 开始的，但我们通常希望编号是从 1 开始的。

### 使用 enumerated 编号

 `enumerated()` 

以下是一个例子：

```swift
struct ContentView: View {
    var bookmarks: [BookmarkModel]

    var body: some View {
        List {
            ForEach(Array(bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                Text("\(index). \(bookmark.name)")
            }
        }
    }
}
```

我们使用 `Array(bookmarks.enumerated())` 来创建一个元组数组，每个元组包含一个索引和一个 `BookmarkModel` 对象。然后，我们使用 `ForEach` 遍历这个元组数组，并为每个元组创建一个 `Text` 视图。`index` 参数是当前遍历的索引，`bookmark` 参数是当前遍历的 `BookmarkModel` 对象。

### 使用 zip 编号

`zip(_:_:)` 函数可以将两个序列合并为一个元组序列。你可以使用这个函数和 `ForEach` 结构体来为数组中的每个元素添加一个编号。

例如，如果你有一个 `BookmarkModel` 的数组，并且你想为每个书签创建一个文本视图，并在前面添加一个编号，你可以这样做：

```swift
struct ContentView: View {
    var bookmarks: [BookmarkModel]

    var body: some View {
        List {
            ForEach(Array(zip(1..., bookmarks)), id: \.1.id) { index, bookmark in
                Text("\(index). \(bookmark.name)")
            }
        }
    }
}
```

写出扩展，方便调用

```swift
@dynamicMemberLookup
struct Numbered<Element> {
    var number: Int
    var element: Element
    
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Element, T>) -> T {
        get { element[keyPath: keyPath] }
        set { element[keyPath: keyPath] = newValue }
    }
}

extension Sequence {
    func numbered(startingAt start: Int = 1) -> [Numbered<Element>] {
        zip(start..., self)
            .map { Numbered(number: $0.0, element: $0.1) }
    }
}

extension Numbered: Identifiable where Element: Identifiable {
    var id: Element.ID { element.id }
}
```

使用：

```swift
ForEach(bookmark.numbered()) { numberedBookmark in
    Text("\(numberedBookmark.number). \(numberedBookmark.name)")
}
```
## Scroll视图
### ScrollView

#### 新增 modifier

```swift
ScrollView {
    ForEach(0..<300) { i in
        Text("\(i)")
            .id(i)
    }
}
.scrollDisabled(false) // 设置是否可滚动
.scrollDismissesKeyboard(.interactively) // 关闭键盘
.scrollIndicators(.visible) // 设置滚动指示器是否可见
```

#### ScrollViewReader

ScrollView 使用 scrollTo 可以直接滚动到指定的位置。ScrollView 还可以透出偏移量，利用偏移量可以定义自己的动态视图，比如向下向上滚动视图时有不同效果，到顶部显示标题视图等。

示例代码如下：

```swift
struct PlayScrollView: View {
    @State private var scrollOffset: CGFloat = .zero
    
    var infoView: some View {
        GeometryReader { g in
            Text("移动了 \(Double(scrollOffset).formatted(.number.precision(.fractionLength(1)).rounded()))")
                .padding()
        }
    }
    
    var body: some View {
        // 标准用法
        ScrollViewReader { s in
            ScrollView {
                ForEach(0..<300) { i in
                    Text("\(i)")
                        .id(i)
                }
            }
            Button("跳到150") {
                withAnimation {
                    s.scrollTo(150, anchor: .top)
                }
            } // end Button
        } // end ScrollViewReader
        
        // 自定义的 ScrollView 透出 offset 供使用
        ZStack {
            PCScrollView {
                ForEach(0..<100) { i in
                    Text("\(i)")
                }
            } whenMoved: { d in
                scrollOffset = d
            }
            infoView
            
        } // end ZStack
    } // end body
}

// MARK: - 自定义 ScrollView
struct PCScrollView<C: View>: View {
    let c: () -> C
    let whenMoved: (CGFloat) -> Void
    
    init(@ViewBuilder c: @escaping () -> C, whenMoved: @escaping (CGFloat) -> Void) {
        self.c = c
        self.whenMoved = whenMoved
    }
    
    var offsetReader: some View {
        GeometryReader { g in
            Color.clear
                .preference(key: OffsetPreferenceKey.self, value: g.frame(in: .named("frameLayer")).minY)
        }
        .frame(height:0)
    }
    
    var body: some View {
        ScrollView {
            offsetReader
            c()
                .padding(.top, -8)
        }
        .coordinateSpace(name: "frameLayer")
        .onPreferenceChange(OffsetPreferenceKey.self, perform: whenMoved)
    } // end body
}

private struct OffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
```


### 固定到滚动视图的顶部

LazyVStack 有个参数 pinnedViews 可以用于固定滚动视图的顶部。

```swift
ScrollView {
    LazyVStack(alignment: .leading, spacing: 10, pinnedViews: .sectionHeaders) {
        Section {
            ForEach(books) { book in
                BookRowView(book: book)
            }
        } header: {
            HeaderView(title: "小说")
        }
        ....
    }
}
```
### 滚动到特定的位置


#### scrollPostion 版本

`scrollPositon(id:)` 比 ScrollViewReader 简单，但是只适用于 ScrollView。数据源遵循 Identifiable，不用显式使用 `id` 修饰符

```swift
struct ContentView: View {
    @State private var id: Int?

    var body: some View {
        VStack {
            Button("Scroll to Bookmark 3") {
                withAnimation {
                    id = 3
                }
            }
            Button("Scroll to Bookmark 13") {
                withAnimation {
                    id = 13
                }
            }
            ScrollView {
                ScrollViewReader { scrollView in
                    LazyVStack {
                        ForEach(Bookmark.simpleData()) { bookmark in
                            Text("\(bookmark.index)")
                                .id(bookmark.index)
                        }
                        
                    }
                }
            }
            .scrollPosition(id: $id)
            .scrollTargetLayout()
        }
    }
    
    struct Bookmark: Identifiable,Hashable {
        let id = UUID()
        let index: Int
        
        static func simpleData() -> [Bookmark] {
            var re = [Bookmark]()
            for i in 0...100 {
                re.append(Bookmark(index: i))
            }
            return re
        }
    }
}
```

scrollTargetLayout 可以获得当前滚动位置。锚点不可配，默认是 center。


#### ScrollViewReader 版本

ScrollViewReader 这个版本可以适用于 List，也可以配置锚点

你可以使用 `ScrollViewReader` 和 `scrollTo(_:anchor:)` 方法来滚动到特定的元素。以下是一个例子：

```swift
struct ContentView: View {
    var bookmarks: [Int] = Array(1...100)
    @State private var selectedBookmarkId: Int?

    var body: some View {
        VStack {
            Button("Scroll to Bookmark 3") {
                selectedBookmarkId = 3
            }
            Button("Scroll to Bookmark 13") {
                selectedBookmarkId = 13
            }
            ScrollView {
                ScrollViewReader { scrollView in
                    LazyVStack {
                        ForEach(bookmarks.indices, id: \.self) { index in
                            Text("\(bookmarks[index])")
                                .id(index)
                        }
                        .onChange(of: selectedBookmarkId) { oldValue, newValue in
                            if let newValue = newValue {
                                withAnimation {
                                    scrollView.scrollTo(newValue, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

在这个例子中，我们首先创建了一个 `Button`，当点击这个按钮时，`selectedBookmarkId` 的值会被设置为 3。然后，我们创建了一个 `ScrollView`，并在 `ScrollView` 中添加了一个 `ScrollViewReader`。我们在 `ScrollViewReader` 中添加了一个 `LazyVStack`，并使用 `ForEach` 遍历 `bookmarks` 数组的索引，为每个索引创建一个 `Text` 视图。我们使用 `id(_:)` 方法为每个 `Text` 视图设置了一个唯一的 ID。

我们使用 `onChange(of:perform:)` 方法来监听 `selectedBookmarkId` 的变化。当 `selectedBookmarkId` 的值改变时，我们会调用 `scrollTo(_:anchor:)` 方法来滚动到特定的元素。`anchor: .top` 参数表示我们希望滚动到的元素位于滚动视图的顶部。

### scrollTargetBehavior分页滚动

#### 按可视尺寸分页

`.scrollTargetBehavior(.paging)` 可以让 ScrollView 滚动，滚动一页的范围是 ScrollView 的可视尺寸。
 
```swift
struct ContentView: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(0...20, id: \.self) { i in
                    colorView()
                        .frame(width: 300, height: 200)
                }
            }
        }
        .scrollTargetBehavior(.paging)
    }
    
    @ViewBuilder
    func colorView() -> some View {
        [Color.red, Color.yellow, Color.blue, Color.mint, Color.indigo, Color.green].randomElement()
    }
}
```

#### 按容器元素对齐分页

使用 `.scrollTargetBehavior(.viewAligned)` 配合 scrollTargetLayout。示例代码如下：

```swift
struct ContentView: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(0...20, id: \.self) { i in
                    colorView()
                        .frame(width: 300, height: 200)
                }
            }
            .scrollTargetLayout(isEnabled: true)
        }
        .scrollTargetBehavior(.viewAligned)
    }
    
    @ViewBuilder
    func colorView() -> some View {
        [Color.red, Color.yellow, Color.blue, Color.mint, Color.indigo, Color.green].randomElement()
    }
}
```




### scrollTransition视觉效果


iOS 17 新推出 `.scrollTransition`，用于处理滚动时的动画。

`.transition` 用于视图插入和移除视图树时的动画。

`.scrollTransition` 会和滚动联合起来进行平滑的过渡动画处理。`.scrollTransition` 可以修改很多属性，比如大小，可见性还有旋转等。

`.scrollTransition` 可以针对不同阶段进行处理，目前有三个阶段：

- `topLeading`: 视图进入 ScrollView 可见区域
- `identity`: 在可见区域中
- `bottomTrailing`: 视图离开 ScrollView 可见区域

```swift
struct ContentView: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(0...20, id: \.self) { i in
                    colorView()
                        .frame(width: 300, height: 200)
                        .scrollTransition { content, phase in 
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.4)
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    func colorView() -> some View {
        [Color.red, Color.yellow, Color.blue, Color.mint, Color.indigo, Color.green].randomElement()
    }
}
```

使用阶段的值

```swift
.scrollTransition(.animated(.bouncy)) { content, phase in
    content
        .scaleEffect(phase.isIdentity ? 1 : phase.value)
}
```

不同阶段的产生效果设置

```swift
.scrollTransition(
    topLeading: .animated,
    bottomTrailing: .interactive
) { content, phase in
    content.rotationEffect(.radians(phase.value))
}
```

`.rotation3DEffect` 也是支持的。

```swift
.scrollTransition(.interactive) { content, phase in
    content
        .rotation3DEffect(
            Angle.degrees(phase.isIdentity ? 0: 120),
            axis: (x: 0.9, y: 0.0, z: 0.1))
        .offset(x: phase.value * -300)
}
```


### ScrollView-参考资料

#### 文档

- [ScrollView | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/scrollview) 官方文档
- [Scroll views | 接口](https://developer.apple.com/documentation/swiftui/scroll-views) 官方接口文档

#### WWDC

23
- [Beyond scroll views - WWDC23 - Videos - Apple Developer](https://developer.apple.com/wwdc23/10159) 
## List列表
### List
![](https://ming1016.github.io/qdimg/240505/list-ap01.jpeg)

List 除了能够展示数据外，还有下拉刷新、过滤搜索和侧滑 Swipe 动作提供更多 Cell 操作的能力。

通过 List 的可选子项参数提供数据模型的关键路径来制定子项路劲，还可以实现大纲视图，使用 DisclosureGroup 和 OutlineGroup  可以进一步定制大纲视图。

使用 `.listRowSeparator(.hidden, edges: .all)` 可以隐藏分割线。

下面是 List 使用，包括了 DisclosureGroup 和 OutlineGroup 的演示代码：

```swift
struct PlayListView: View {
    @StateObject var l: PLVM = PLVM()
    @State private var s: String = ""
    
    var outlineModel = [
        POutlineModel(title: "文件夹一", iconName: "folder.fill", children: [
            POutlineModel(title: "个人", iconName: "person.crop.circle.fill"),
            POutlineModel(title: "群组", iconName: "person.2.circle.fill"),
            POutlineModel(title: "加好友", iconName: "person.badge.plus")
        ]),
        POutlineModel(title: "文件夹二", iconName: "folder.fill", children: [
            POutlineModel(title: "晴天", iconName: "sun.max.fill"),
            POutlineModel(title: "夜间", iconName: "moon.fill"),
            POutlineModel(title: "雨天", iconName: "cloud.rain.fill", children: [
                POutlineModel(title: "雷加雨", iconName: "cloud.bolt.rain.fill"),
                POutlineModel(title: "太阳雨", iconName: "cloud.sun.rain.fill")
            ])
        ]),
        POutlineModel(title: "文件夹三", iconName: "folder.fill", children: [
            POutlineModel(title: "电话", iconName: "phone"),
            POutlineModel(title: "拍照", iconName: "camera.circle.fill"),
            POutlineModel(title: "提醒", iconName: "bell")
        ])
    ]
    
    var body: some View {
        HStack {
            // List 通过$语法可以将集合的元素转换成可绑定的值
            List {
                ForEach($l.ls) { $d in
                    PRowView(s: d.s, i: d.i)
                        .listRowInsets(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
                        .listRowBackground(Color.black.opacity(0.2))
                }
            }
            .refreshable {
                // 下拉刷新
            }
            .searchable(text: $s) // 搜索
            .onChange(of: s) { newValue in
                print("搜索关键字：\(s)")
            }
            
            Divider()
            
            // 自定义 List
            VStack {
                PCustomListView($l.ls) { $d in
                    PRowView(s: d.s, i: d.i)
                }
                // 添加数据
                Button {
                    l.ls.append(PLModel(s: "More", i: 0))
                } label: {
                    Text("添加")
                }
            }
            .padding()
            
            Divider()
            
            // 使用大纲
            List(outlineModel, children: \.children) { i in
                Label(i.title, systemImage: i.iconName)
            }
            
            Divider()
            
            // 自定义大纲视图
            VStack {
                Text("可点击标题展开")
                    .font(.headline)
                PCOutlineListView(d: outlineModel, c: \.children) { i in
                    Label(i.title, systemImage: i.iconName)
                }
            }
            .padding()
            
            Divider()
            
            // 使用 OutlineGroup 实现大纲视图
            VStack {
                Text("OutlineGroup 实现大纲")
                
                OutlineGroup(outlineModel, children: \.children) { i in
                    Label(i.title, systemImage: i.iconName)
                }
                
                // OutlineGroup 和 List 结合
                Text("OutlineGroup 和 List 结合")
                List {
                    ForEach(outlineModel) { s in
                        Section {
                            OutlineGroup(s.children ?? [], children: \.children) { i in
                                Label(i.title, systemImage: i.iconName)
                            }
                        } header: {
                            Label(s.title, systemImage: s.iconName)
                        }

                    } // end ForEach
                } // end List
            } // end VStack
        } // end HStack
    } // end body
}

// MARK: - 自定义大纲视图
struct PCOutlineListView<D, Content>: View where D: RandomAccessCollection, D.Element: Identifiable, Content: View {
    private let v: PCOutlineView<D, Content>
    
    init(d: D, c: KeyPath<D.Element, D?>, content: @escaping (D.Element) -> Content) {
        self.v = PCOutlineView(d: d, c: c, content: content)
    }
    
    var body: some View {
        List {
            v
        }
    }
}

struct PCOutlineView<D, Content>: View where D: RandomAccessCollection, D.Element: Identifiable, Content: View {
    let d: D
    let c: KeyPath<D.Element, D?>
    let content: (D.Element) -> Content
    @State var isExpanded = true // 控制初始是否展开的状态
    
    var body: some View {
        ForEach(d) { i in
            if let sub = i[keyPath: c] {
                PCDisclosureGroup(content: PCOutlineView(d: sub, c: c, content: content), label: content(i))
            } else {
                content(i)
            } // end if
        } // end ForEach
    } // end body
}

struct PCDisclosureGroup<C, L>: View where C: View, L: View {
    @State var isExpanded = false
    var content: C
    var label: L
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
        } label: {
            Button {
                isExpanded.toggle()
            } label: {
                label
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 大纲模式数据模型
struct POutlineModel: Hashable, Identifiable {
    var id = UUID()
    var title: String
    var iconName: String
    var children: [POutlineModel]?
}

// MARK: - List 的抽象，数据兼容任何集合类型
struct PCustomListView<D: RandomAccessCollection & MutableCollection & RangeReplaceableCollection, Content: View>: View where D.Element: Identifiable {
    @Binding var data: D
    var content: (Binding<D.Element>) -> Content
    
    init(_ data: Binding<D>, content: @escaping (Binding<D.Element>) -> Content) {
        self._data = data
        self.content = content
    }
    
    var body: some View {
        List {
            Section {
                ForEach($data, content: content)
                    .onMove { indexSet, offset in
                        data.move(fromOffsets: indexSet, toOffset: offset)
                    }
                    .onDelete { indexSet in
                        data.remove(atOffsets: indexSet) // macOS 暂不支持
                    }
            } header: {
                Text("第一栏，共 \(data.count) 项")
            } footer: {
                Text("The End")
            }
        }
        .listStyle(.plain) // 有.automatic、.inset、.plain、sidebar，macOS 暂不支持的有.grouped 和 .insetGrouped
    }
}

// MARK: - Cell 视图
struct PRowView: View {
    var s: String
    var i: Int
    var body: some View {
        HStack {
            Text("\(i)：")
            Text(s)
        }
    }
}

// MARK: - 数据模型设计
struct PLModel: Hashable, Identifiable {
    let id = UUID()
    var s: String
    var i: Int
}

final class PLVM: ObservableObject {
    @Published var ls: [PLModel]
    init() {
        ls = [PLModel]()
        for i in 0...20 {
            ls.append(PLModel(s: "\(i)", i: i))
        }
    }
}
```

list 支持 Section footer。

list 分隔符可以自定义，使用  `HorizontalEdge.leading` 和 `HorizontalEdge.trailing` 。

list 不使用 UITableView 了。

今年 list 还新增了一个 [EditOperation](https://developer.apple.com/documentation/swiftui/editoperations) 可以自动生成移动和删除，新增了 edits 参数，传入 `[.delete, .move]` 数组即可。这也是一个演示如何更好扩展和配置功能的方式。

`.searchable` 支持 token 和 scope，示例如下：
```swift
struct PSearchTokensAndScopes: View {
    enum AttendanceScope {
        case inPerson, online
    }
    @State private var queryText: String
    @State private var queryTokens: [InvitationToken]
    @State private var scope: AttendanceScope
    
    var body: some View {
        invitationCountView()
            .searchable(text: $queryText, tokens: $queryTokens, scope: $scope) { token in
                Label(token.diplayName, systemImage: token.systemImage)
            } scopes: {
                Text("In Person").tag(AttendanceScope.inPerson)
                Text("Online").tag(AttendanceScope.online)
            }
    }
}
```
### List-设置样式


#### 内置样式

通过 `.listStyle` 修饰符可以用系统内置样式更改 List 外观。

```swift
List {
   ...
}
.listStyle(.sidebar)
```

不同平台有不同的选项


| ListStyle    | iOS     | macOS        | watchOS    | tvOS     |
| ------------ | ------- | ------------ | ---------- | -------- |
| plain        | iOS 13+ | macOS 10.15+ | watchOS 6+ | tvOS 13+ |
| sidebar      | iOS 14+ | macOS 10.15+ | -          | -        |
| inset        | iOS 13+ | macOS 11.15+ | -          | -        |
| grouped      | iOS 13+ | -            | -          | tvOS 13+ |
| insetGrouped | iOS 14+ | -            | -          | -        |
| bordered     | -       | macOS 12+    | -          | -        |
| carousel     | -       | -            | watchOS 6+ | -        |
| elliptical   | -       | -            | watchOS 7+ | -        |


#### 行高

```swift
List {
  ...
}
.environment(\.defaultMinListRowHeight, 100)
.environment(\.defaultMinListHeaderHeight, 50)
```

#### 分隔符

listSectionSeparator 和 listRowSeparator 隐藏行和 Section 分隔符。

listRowSeparatorTint 和 listSectionSeparatorTint 更改分隔符颜色

例如：

```swift
.listRowSeparatorTint(.cyan, edges: .bottom)
```

#### 背景

`.alternatingRowBackgrounds()` 可以让 List 的行底色有区分。

listRowBackground 调整行的背景颜色

更改背景颜色前需要隐藏内容背景

```swift
List {
  ...
}
.scrollContentBackground(.hidden)
.background(Color.cyan)
```

这个方法同样可用于 ScrollView 和 TextEditor。

你可以使用 `.listRowBackground()` 修饰符来更改列表行的背景。以下是一个例子：

```swift
struct ContentView: View {
    var body: some View {
        List {
            ForEach(0..<5) { index in
                Text("Row \(index)")
                    .listRowBackground(index % 2 == 0 ? Color.blue : Color.green)
            }
        }
    }
}
```

在这个例子中，我们创建了一个包含五个元素的 List。我们使用 `.listRowBackground()` 修饰符来更改每个元素的背景颜色。如果元素的索引是偶数，我们将背景颜色设置为蓝色，否则我们将背景颜色设置为绿色。

#### Section

你可以使用 `Section` 视图的 `header` 和 `footer` 参数来添加头部和尾部。以下是一个例子：

```swift
struct ContentView: View {
    var body: some View {
        List {
            Section {
                ForEach(0..<5) { index in
                    Text("Row \(index)")
                }
            } header: {
                Text("Header").font(.title)
            } footer: {
                Text("Footer").font(.caption)
            }
        }
    }
}
```

headerProminence（.increase） 可以增加 Section Header 的大小。

#### safeAreaInset

你可以使用 `.safeAreaInset()` 修饰符来调整视图的安全区域插入。以下是一个例子：

```swift
struct ContentView: View {
    var body: some View {
        List {
            ForEach(0..<5) { index in
                Text("Row \(index)")
            }
        }
        .safeAreaInset(edge: .top, spacing: 20) {
            Text("Header")
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color.blue)
                .foregroundColor(.white)
        }
    }
}
```

在这个例子中，我们创建了一个包含五个元素的 List。然后我们使用 `.safeAreaInset()` 修饰符来在 List 的顶部添加一个 Header。我们将 `edge` 参数设置为 `.top`，将 `spacing` 参数设置为 20，然后提供一个视图作为 Header。这个 Header 是一个文本视图，它的背景颜色是蓝色，前景颜色是白色，它被居中对齐，并且它的宽度和 List 的宽度相同。
### List-移动元素

你可以使用 `.onMove(perform:)` 修饰符来允许用户移动 List 中的元素。以下是一个例子：

```swift
struct ContentView: View {
    @State private var items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]

    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                }
                .onMove(perform: move)
            }
            .toolbar {
                EditButton()
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}
```

在这个例子中，我们创建了一个包含五个元素的 List。我们使用 `.onMove(perform:)` 修饰符来允许用户移动这些元素，并提供了一个 `move(from:to:)` 方法来处理移动操作。我们还添加了一个 `EditButton`，用户可以点击它来进入编辑模式，然后就可以移动元素了。

### List-搜索

#### 搜索和搜索建议

你可以使用 `.searchable()` 修饰符的 `suggestions` 参数来提供搜索建议。以下是一个例子：

```swift
struct ContentView: View {
    @State private var searchText = ""
    @State private var items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]

    var body: some View {
        NavigationView {
            List {
                ForEach(items.filter({ searchText.isEmpty ? true : $0.contains(searchText) }), id: \.self) { item in
                    Text(item)
                }
            }
            .searchable(text: $searchText, suggestions: { 
                Button(action: {
                    searchText = "Item 1"
                }) {
                    Text("Item 1")
                }
                Button(action: {
                    searchText = "Item 2"
                }) {
                    Text("Item 2")
                }
            })
            .navigationBarTitle("Items")
        }
    }
}
```

在这个例子中，我们创建了一个包含五个元素的 List，并添加了一个搜索框。当用户在搜索框中输入文本时，List 会自动更新以显示匹配的元素。同时，我们提供了两个搜索建议 "Item 1" 和 "Item 2"，用户可以点击这些建议来快速填充搜索框。


#### 在列表中显示搜索建议

```swift
struct ContentView: View {
    @Environment(\.searchSuggestionsPlacement) var placement
    @State private var searchText = ""
    @State private var items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    
    var body: some View {
        NavigationView {
            List {
                SearchSuggestionView()
                ForEach(items.filter({ searchText.isEmpty ? true : $0.contains(searchText) }), id: \.self) { item in
                    Text(item)
                }
            }
            .searchable(text: $searchText, suggestions: {
                VStack {
                    Button(action: {
                        searchText = "Item 1"
                    }) {
                        Text("Item 1")
                    }
                    Button(action: {
                        searchText = "Item 2"
                    }) {
                        Text("Item 2")
                    }
                }
                .searchSuggestions(.hidden, for: .content)
            })
            .navigationBarTitle("Items")
        }
    }
    
    @ViewBuilder
    func SearchSuggestionView() -> some View {
        if placement == .content {
            Button(action: {
                searchText = "Item 1"
            }) {
                Text("Item 1")
            }
            Button(action: {
                searchText = "Item 2"
            }) {
                Text("Item 2")
            }
        }
    }
}
```

#### 搜索状态

搜索中

```swift
@Environment(\.isSearching) var isSearching
```

关闭搜索

```swift
@Environment(\.dismissSearch) var dismissSearch
```

提交搜索

```swift
List {
    ...
}
.searchable(text: $vm.searchTerm)
.onSubmit(of: .search) {
    //...
}
```

#### 搜索栏外观

占位文字说明

```swift
.searchable(text: $wwdcVM.searchText, prompt: "搜索 WWDC Session 内容")
```

一直显示搜索栏

```swift
.searchable(text: $wwdcVM.searchText, 
            placement: .navigationBarDrawer(displayMode:.always))
```

更改搜索栏的位置

```swift
.searchable(text: $wwdcVM.searchText, placement: .sidebar)
```

#### 搜索去抖动

你可以使用 Combine 框架来实现搜索的去抖动功能。以下是一个例子：

```swift
import SwiftUI
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] in self?.search($0) }
            .store(in: &cancellables)
    }

    private func search(_ text: String) {
        // 这里是你的搜索逻辑
        // 例如，你可以从一个数组中过滤出匹配的元素
        let items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
        searchResults = items.filter { $0.contains(text) }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack {
            TextField("Search", text: $viewModel.searchText)
                .padding()
            List(viewModel.searchResults, id: \.self) { result in
                Text(result)
            }
        }
    }
}
```

在这个例子中，我们创建了一个 `SearchViewModel` 类，它有一个 `searchText` 属性和一个 `searchResults` 属性。当 `searchText` 属性的值发生变化时，我们使用 Combine 的 `debounce(for:scheduler:)` 方法来延迟执行搜索操作，从而实现去抖动功能。然后我们在 `ContentView` 中使用这个 `SearchViewModel` 来显示搜索框和搜索结果。

### List-下拉刷新

你可以使用 `.refreshable()` 修饰符来添加下拉刷新功能。以下是一个例子：

```swift
struct ContentView: View {
    @State private var items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]

    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }
        .refreshable {
            await refresh()
        }
    }

    func refresh() async {
        // 这里是你的刷新逻辑
        // 例如，你可以从网络获取新的数据，然后更新 items 数组
        // 这里我们只是简单地将 items 数组反转
        items.reverse()
    }
}
```

在这个例子中，我们创建了一个包含五个元素的 List，并添加了下拉刷新功能。当用户下拉 List 时，`refresh()` 方法会被调用，然后我们将 items 数组反转，从而模拟刷新操作。注意，`refresh()` 方法需要是一个异步方法，因为刷新操作通常需要一些时间来完成。
### List-轻扫操作

你可以使用 `.swipeActions()` 修饰符来添加轻扫操作。以下是一个例子：

```swift
struct ContentView: View {
    @State private var items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]

    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                Text(item)
                .swipeActions {
                    Button(action: {
                        // 这里是你的删除操作
                        if let index = items.firstIndex(of: item) {
                            items.remove(at: index)
                        }
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
    }
}
```

在这个例子中，我们创建了一个包含五个元素的 List，并为每个元素添加了一个滑动操作。当用户向左轻扫一个元素时，会显示一个 "Delete" 按钮，用户可以点击这个按钮来删除该元素。
### List-大纲视图

#### List 树状结构

通过 children 参数指定子树路径。

```swift
List(outlineModel, children: \.children) { i in
    Label(i.title, systemImage: i.iconName)
}
```

#### DisclosureGroup 实现展开和折叠

`DisclosureGroup` 视图可以用来创建一个可以展开和折叠的内容区域。以下是一个例子：

```swift
struct ContentView: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("Options", isExpanded: $isExpanded) {
            Text("Option 1")
            Text("Option 2")
            Text("Option 3")
        }
    }
}
```

在这个例子中，我们创建了一个 `DisclosureGroup` 视图，它的标题是 "Options"，并且它包含三个选项。我们使用一个 `@State` 属性 `isExpanded` 来控制 `DisclosureGroup` 视图是否展开。当用户点击标题时，`DisclosureGroup` 视图会自动展开或折叠，同时 `isExpanded` 属性的值也会相应地改变。

#### OutlineGroup 创建大纲视图

可以使用 `OutlineGroup` 视图来创建一个大纲视图。以下是一个例子：

```swift
struct ContentView: View {
    var body: some View {
        List {
            OutlineGroup(sampleData, id: \.self) { item in
                Text(item.name)
            }
        }
    }
}

struct Item: Identifiable {
    var id = UUID()
    var name: String
    var children: [Item]?
}

let sampleData: [Item] = [
    Item(name: "Parent 1", children: [
        Item(name: "Child 1"),
        Item(name: "Child 2")
    ]),
    Item(name: "Parent 2", children: [
        Item(name: "Child 3"),
        Item(name: "Child 4")
    ])
]
```

在这个例子中，我们创建了一个 `Item` 结构体，它有一个 `name` 属性和一个 `children` 属性。然后我们创建了一个 `sampleData` 数组，它包含两个父项，每个父项都有两个子项。最后我们在 `ContentView` 中使用 `OutlineGroup` 视图来显示这个数组，每个父项和子项都显示为一个文本视图。


#### 结合 OutlineGroup 和 DisclosureGroup 实现自定义可折叠大纲视图

代码如下：
```swift
struct SPOutlineListView<D, Content>: View where D: RandomAccessCollection, D.Element: Identifiable, Content: View {
    private let v: SPOutlineView<D, Content>
    
    init(d: D, c: KeyPath<D.Element, D?>, content: @escaping (D.Element) -> Content) {
        self.v = SPOutlineView(d: d, c: c, content: content)
    }
    
    var body: some View {
        List {
            v
        }
    }
}

struct SPOutlineView<D, Content>: View where D: RandomAccessCollection, D.Element: Identifiable, Content: View {
    let d: D
    let c: KeyPath<D.Element, D?>
    let content: (D.Element) -> Content
    @State var isExpanded = true // 控制初始是否展开的状态
    
    var body: some View {
        ForEach(d) { i in
            if let sub = i[keyPath: c] {
                SPDisclosureGroup(content: SPOutlineView(d: sub, c: c, content: content), label: content(i))
            } else {
                content(i)
            } // end if
        } // end ForEach
    } // end body
}

struct SPDisclosureGroup<C, L>: View where C: View, L: View {
    @State var isExpanded = false
    var content: C
    var label: L
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
        } label: {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                label
            }
            .buttonStyle(.plain)
        }
        
    }
}
```
### List-完全可点击的行

使用 `.contentShape(Rectangle())` 可以使整个区域都可点击 

```swift
struct ContentView: View {
    var body: some View {
        List {
            ForEach(1..<50) { num in
                HStack {
                    Text("\(num)")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    print("Clicked \(num)")
                }
            }
        } // end list
    }
}
```
### List-索引标题

这个代码是在创建一个带有索引标题的列表，用户可以通过拖动索引标题来快速滚动列表。

```swift
import SwiftUI

...

struct ContentView: View {
  ...
  var body: some View {
    ScrollViewReader { proxy in
      List {
        ArticleListView
      }
      .listStyle(InsetGroupedListStyle())
      .overlay(IndexView(proxy: proxy))
    }
  }
  ...
}

struct IndexView: View {
  let proxy: ScrollViewProxy
  let titles: [String]
  @GestureState private var dragLocation: CGPoint = .zero

  var body: some View {
    VStack {
      ForEach(titles, id: \.self) { title in
        TitleView()
          .background(drag(title: title))
      }
    }
    .gesture(
      DragGesture(minimumDistance: 0, coordinateSpace: .global)
        .updating($dragLocation) { value, state, _ in
          state = value.location
        }
    )
  }

  func drag(title: String) -> some View {
    GeometryReader { geometry in
      drag(geometry: geometry, title: title)
    }
  }

  func drag(geometry: GeometryProxy, title: String) -> some View {
    if geometry.frame(in: .global).contains(dragLocation) {
      DispatchQueue.main.async {
        proxy.scrollTo(title, anchor: .center)
      }
    }
    return Rectangle().fill(Color.clear)
  }
  ...
}
...
```

上面代码中 `ContentView` 是主视图，它包含一个 `List` 和一个 `IndexView`。`List` 中的内容由 `ArticleListView` 提供。`IndexView` 是一个自定义视图，它显示了所有的索引标题。

`IndexView` 接受一个 `ScrollViewProxy` 和一个标题数组。它使用 `VStack` 和 `ForEach` 来创建一个垂直的索引标题列表。每个标题都是一个 `TitleView`，并且它有一个背景，这个背景是通过 `drag(title:)` 方法创建的。

`drag(title:)` 方法接受一个标题，并返回一个视图。这个视图是一个 `GeometryReader`，它可以获取其包含的视图的几何信息。然后，这个 `GeometryReader` 使用 `drag(geometry:title:)` 方法来创建一个新的视图。

`drag(geometry:title:)` 方法接受一个 `GeometryProxy` 和一个标题，并返回一个视图。如果 `GeometryProxy` 的全局帧包含当前的拖动位置，那么这个方法将返回一个特定的视图。

`IndexView` 还有一个手势，这个手势是一个 `DragGesture`。当用户拖动索引标题时，这个手势会更新 `dragLocation` 属性的值，这个属性是一个 `@GestureState` 属性，它表示当前的拖动位置。


### List-加载更多


你可以通过检测列表滚动到底部来实现加载更多的功能。以下是一个简单的例子：

```swift
struct ContentView: View {
    @State private var items = Array(0..<20)

    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                Text("Item \(item)")
                    .onAppear {
                        if item == items.last {
                            loadMore()
                        }
                    }
            }
        }
        .onAppear(perform: loadMore)
    }

    func loadMore() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let newItems = Array(self.items.count..<self.items.count + 20)
            self.items.append(contentsOf: newItems)
        }
    }
}
```

在这个例子中，我们创建了一个包含多个元素的 List。当 List 出现最后一项时，我们调用 `loadMore` 方法来加载更多的元素。在 `loadMore` 方法中，模拟在一秒后添加新的元素到 `items` 数组中。

请注意，这只是一个基本的使用示例，实际的使用方式可能会根据你的需求而变化。例如，你可能需要从网络获取新的元素，而不是像这个例子中那样直接创建新的元素。
## Lazy容器
### LazyVStack和LazyHStack
LazyVStack 和 LazyHStack 里的视图只有在滚到时才会被创建。

```swift
struct PlayLazyVStackAndLazyHStackView: View {
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(1...300, id: \.self) { i in
                    PLHSRowView(i: i)
                }
            }
        }
    }
}

struct PLHSRowView: View {
    let i: Int
    var body: some View {
        Text("第 \(i) 个")
    }
    init(i: Int) {
        print("第 \(i) 个初始化了") // 用来查看什么时候创建的。
        self.i = i
    }
}
```
### LazyVGrid和LazyHGrid
![](https://ming1016.github.io/qdimg/240505/lazyvgridandlazyhgrid-ap01.jpeg)

列的设置有三种，这三种也可以组合用。

* GridItem(.fixed(10)) 会固定设置有多少列。
* GridItem(.flexible()) 会充满没有使用的空间。
* GridItem(.adaptive(minimum: 10)) 表示会根据设置大小自动设置有多少列展示。

示例：

```swift
struct PlayLazyVGridAndLazyHGridView: View {
    @State private var colors: [String:Color] = [
        "red" : .red,
        "orange" : .orange,
        "yellow" : .yellow,
        "green" : .green,
        "mint" : .mint,
        "teal" : .teal,
        "cyan" : .cyan,
        "blue" : .blue,
        "indigo" : .indigo,
        "purple" : .purple,
        "pink" : .pink,
        "brown" : .brown,
        "gray" : .gray,
        "black" : .black
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 50), spacing: 10)
            ], pinnedViews: [.sectionHeaders]) {
                Section(header:
                            Text("🎨调色板")
                            .font(.title)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(RoundedRectangle(cornerRadius: 0)
                                                .fill(.black.opacity(0.1)))
                ) {
                    ForEach(Array(colors.keys), id: \.self) { k in
                        colors[k].frame(height:Double(Int.random(in: 50...150)))
                            .overlay(
                                Text(k)
                            )
                            .shadow(color: .black, radius: 2, x: 0, y: 2)
                    }
                }
            }
            .padding()
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 20), spacing: 10)
            ]) {
                Section(header: Text("图标集").font(.title)) {
                    ForEach(1...30, id: \.self) { i in
                        Image("p\(i)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .shadow(color: .black, radius: 2, x: 0, y: 2)
                    }
                }
            }
            .padding()
        }
    }
}
```
## Grid

Grid 会将最大的一个单元格大小应用于所有单元格

代码例子：

```swift
struct ContentView: View {
    var body: some View {
        Grid(alignment: .center,
             horizontalSpacing: 30,
             verticalSpacing: 8) {
            GridRow {
                Text("Tropical")
                Text("Mango")
                Text("Pineapple")
                    .gridCellColumns(2)
            }
            GridRow(alignment: .bottom) {
                Text("Leafy")
                Text("Spinach")
                Text("Kale")
                Text("Lettuce")
            }
        }
    }
}
```

`gridCellAnchor` 可以让 GridRow 给自己设置对齐方式。

`gridCellColumns()`  modifier 可以让一个单元格跨多列。

GridRow 的间距通过 Grid 的 `horizontalSpacing` 和 `verticalSpacing` 参数来控制。

```swift
struct ContentView: View {
    let numbers: [[Int]] = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
    ]

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(numbers.indices, id: \.self) { i in
                GridRow {
                    ForEach(numbers[i].indices, id: \.self) { j in
                        Text("\(numbers[i][j])")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .border(Color.gray, width: 0.5)
                    }
                }
            }
        }
    }
}
```

按照以上代码这样写，每个数字 GridRow 之间的间隔就是0了。

空白的单元格可以这样写：

```swift
Color.clear
    .gridCellUnsizedAxes([.horizontal, .vertical])
```




## Table表格
### Table



今年 iOS 和 iPadOS 也可以使用去年只能在 macOS 上使用的 Table了，据 digital lounges 里说，iOS table 的性能和 list 差不多，table 默认为 plian list。我想 iOS 上加上 table 只是为了兼容 macOS 代码吧。

table 使用示例如下：
```swift
struct ContentView: View {
    var body: some View {
        Table(Fruit.simpleData()) {
            TableColumn("名字", value: \.name)
            TableColumn("颜色", value: \.color)
            TableColumn("颜色") {
                Text("\($0.name)")
                    .font(.footnote)
                    .foregroundStyle(.cyan)
            }
        }
        .contextMenu(forSelectionType: Fruit.ID.self) { selection in
            if selection.isEmpty {
                Button("添加") {
                    // ...
                }
            } else if selection.count == 1 {
                Button("收藏") {
                    // ...
                }
            } else {
                Button("收藏多个") {
                    // ...
                }
            }
        }
    }
    
    struct Fruit:Identifiable {
        let id = UUID()
        let name: String
        let color: String
        
        static func simpleData() -> [Fruit] {
            var re = [Fruit]()
            re.append(Fruit(name: "Apple", color: "Red"))
            re.append(Fruit(name: "Banana", color: "Yellow"))
            re.append(Fruit(name: "Cherry", color: "Red"))
            re.append(Fruit(name: "Date", color: "Brown"))
            re.append(Fruit(name: "Elderberry", color: "Purple"))
            return re
        }
    }
}
```

### Table-样式

在 SwiftUI 中，`Table` 视图的 `.tableStyle` 修改器可以用来设置表格的样式。目前，SwiftUI 提供了以下几种表格样式：

- inset：默认
- `inset(alternatesRowBackgrounds: Bool)`：是否开启行交错背景
- bordered：加边框
- `bordered(alternatesRowBackgrounds: Bool)`： 是否开启行交错背景

你可以使用 `.tableStyle` 修改器来设置表格的样式，例如：

```swift
Table(data) {
    // ...
}
.tableStyle(InsetGroupedListStyle())
```

这段代码会将表格的样式设置为 `InsetGroupedListStyle`。
### Table-行的选择

你可以使用 Table 视图的 selection 参数来实现单选和多选。selection 参数接受一个绑定到一个可选的 Set 的变量，这个 Set 包含了被选中的元素的标识。

以下是一个使用 Table 视图实现单选和多选的例子：

```swift
struct ContentView: View {
    @State private var selectionOne: UUID? // 单选
    @State private var selection: Set<UUID> = [] // 多选

    let data = [
        Fruit(name: "Apple", color: "Red"),
        Fruit(name: "Banana", color: "Yellow"),
        Fruit(name: "Cherry", color: "Red"),
        Fruit(name: "Date", color: "Brown"),
        Fruit(name: "Elderberry", color: "Purple")
    ]

    var body: some View {
        Table(data, selection: $selectionOne) {
            TableColumn("Fruit") { item in
                Text(item.name)
            }
            TableColumn("Color") { item in
                Text(item.color)
            }
        }
    }
}

struct Fruit: Identifiable {
    let id = UUID()
    let name: String
    let color: String
}
```

在这个例子中，我们首先定义了一个 @State 变量 selection，它是一个 Set，包含了被选中的元素的标识。然后，我们将这个变量绑定到 Table 视图的 selection 参数。

现在，当用户选择或取消选择一个元素时，selection 变量就会被更新。你可以使用这个变量来判断哪些元素被选中，或者实现其他的交互功能。

### Table-多属性排序

你可以使用 `Table` 视图的 `sortOrder` 参数来实现多属性排序。`sortOrder` 参数接受一个绑定到一个 `SortDescriptor` 数组的变量，这个数组定义了排序的顺序和方式。

以下是一个使用 `Table` 视图实现多属性排序的例子：

```swift
struct ContentView: View {
    @State private var sortOrder: [KeyPathComparator<Fruit>] = [.init(\.name, order: .reverse)]

    @State var data = [
        Fruit(name: "Apple", color: "Red"),
        Fruit(name: "Banana", color: "Yellow"),
        Fruit(name: "Cherry", color: "Red"),
        Fruit(name: "Date", color: "Brown"),
        Fruit(name: "Elderberry", color: "Purple")
    ]

    var body: some View {
        sortKeyPathView() // 排序状态
        Table(data, sortOrder: $sortOrder) {
            TableColumn("Fruit", value: \.name)
            TableColumn("Color", value: \.color)
            // 不含 value 参数的不支持排序
            TableColumn("ColorNoOrder") {
                Text("\($0.color)")
                    .font(.footnote)
                    .foregroundStyle(.mint)
            }
        }
        .task {
            data.sort(using: sortOrder)
        }
        .onChange(of: sortOrder) { oldValue, newValue in
            data.sort(using: newValue)
        }
        .padding()
    }
    
    @ViewBuilder
    func sortKeyPathView() -> some View {
        HStack {
            ForEach(sortOrder, id: \.self) { order in
                Text(order.keyPath == \Fruit.name ? "名字" : "颜色")
                Image(systemName: order.order == .reverse ? "chevron.down" : "chevron.up")
            }
        }
        .padding(.top)
    }
}

struct Fruit: Identifiable {
    let id = UUID()
    let name: String
    let color: String
}
```

在这个例子中，我们首先定义了一个 `@State` 变量 `sortOrder`，它是一个 `SortDescriptor` 数组，定义了排序的顺序和方式。然后，我们将这个变量绑定到 `Table` 视图的 `sortOrder` 参数。

现在，当用户点击表头来排序一个列时，`sortOrder` 变量就会被更新。你可以使用这个变量来实现多属性排序，或者实现其他的交互功能。

### Table-contextMenu

```swift
struct ContentView: View {
    @State private var selection: Set<UUID> = []
    var body: some View {
        Table(Fruit.simpleData(), selection: $selection) {
            ...
        }
        .contextMenu(forSelectionType: Fruit.ID.self) { selection in
            if selection.isEmpty {
                Button("添加") {
                    // ...
                }
            } else if selection.count == 1 {
                Button("收藏") {
                    // ...
                }
            } else {
                Button("收藏多个") {
                    // ...
                }
            }
        } primaryAction: { items in
            // 双击某一行时
            debugPrint(items)
        }
    }
    ...
}
```

