---
title: 小册子之 Form、Picker、Toggle、Slider 和 Stepper 表单相关 SwiftUI 视图
date: 2024-05-18 10:24:12
tags: [SwiftUI]
categories: App
banner_img: /uploads/pamphlet-series-form/01.png
---

以下内容已整理到小册子中，本文会随着系统更新和我更多的实践而新增和更新，你可以下载[“戴铭的开发小册子”](https://apps.apple.com/cn/app/%E6%88%B4%E9%93%AD%E7%9A%84%E5%BC%80%E5%8F%91%E5%B0%8F%E5%86%8C%E5%AD%90/id1609702529?mt=12)应用，来跟踪查看本文内容新增和更新。小册子应用的代码可以在 [Github](https://github.com/ming1016/SwiftPamphletApp) 上查看。

本文属于小册子系列中的一篇，已发布系列文章有：

- [小册子之如何使用 SwiftData 开发 SwiftUI 应用](https://starming.com/2024/05/18/pamphlet-series-swiftdata/)
- [小册子之简说 Widget 小组件](https://starming.com/2024/05/18/pamphlet-series-widget/)
- [小册子之 List、Lazy 容器、ScrollView、Grid 和 Table 数据集合 SwiftUI 视图](https://starming.com/2024/05/18/pamphlet-series-listdataview/)
- [小册子之详说 Navigation、ViewThatFits、Layout 协议等布局 SwiftUI 组件](https://starming.com/2024/05/18/pamphlet-series-layout/)
- 【本篇】[小册子之 Form、Picker、Toggle、Slider 和 Stepper 表单相关 SwiftUI 视图](https://starming.com/2024/05/18/pamphlet-series-form/)
- [小册子之 SwiftUI 动画](https://starming.com/2024/05/25/pamphlet-series-animation/)


## Form


| 控件视图 | 说明 | Style |
| --- | --- | --- |
| Button | 触发操作的按钮 | .bordered, .borderless, .borderedProminent, .plain |
| Picker | 提供多选项供选择 | .wheel, .inline, .segmented, .menu, .radioGroup |
| DatePicker and MultiDatePicker | 选择日期的工具 | .compact, .wheel, .graphical |
| Toggle | 切换两种状态的开关 | .switch, .botton, .checkbox |
| Stepper | 调整数值的步进器 | 无样式选项 |
| Menu | 显示选项列表的菜单 | .borderlessButton, .button |

Form 有 ColumnFormStyle 还有 GroupedFormStyle。使用 buttonStyle 修饰符：
```swift
Form {
   ...
}.formStyle(.grouped)
```

Form 新版也得到了增强，示例如下：

```swift
struct SimpleFormView: View {
    @State private var date = Date()
    @State private var eventDescription = ""
    @State private var accent = Color.red
    @State private var scheme = ColorScheme.light

    var body: some View {
        Form {
            Section {
                DatePicker("Date", selection: $date)
                TextField("Description", text: $eventDescription)
                    .lineLimit(3)
            }
            
            Section("Vibe") {
                Picker("Accent color", selection: $accent) {
                    ForEach(Color.accentColors, id: \.self) { color in
                        Text(color.description.capitalized).tag(color)
                    }
                }
                Picker("Color scheme", selection: $scheme) {
                    Text("Light").tag(ColorScheme.light)
                    Text("Dark").tag(ColorScheme.dark)
                }
            }
        }
        .formStyle(.grouped)
    }
}

extension Color {
    static let accentColors: [Color] = [.red, .green, .blue, .orange, .pink, .purple, .yellow]
}
```

Form 的样式除了 `.formStyle(.grouped)` 还有 `.formStyle(..columns)`。

关于 Form 字体、单元、背景颜色设置，参看下面代码：

```swift
struct ContentView: View {
    @State private var movieTitle = ""
    @State private var isWatched = false
    @State private var rating = 1
    @State private var watchDate = Date()

    var body: some View {
        Form {
            Section {
                TextField("电影标题", text: $movieTitle)
                LabeledContent("导演", value: "克里斯托弗·诺兰")
            } header: {
                Text("关于电影")
            }
            .listRowBackground(Color.gray.opacity(0.1))

            Section {
                Toggle("已观看", isOn: $isWatched)
                Picker("评分", selection: $rating) {
                    ForEach(1...5, id: \.self) { number in
                        Text("\(number) 星")
                    }
                }

            } header: {
                Text("电影详情")
            }
            .listRowBackground(Color.gray.opacity(0.1))
            
            Section {
                DatePicker("观看日期", selection: $watchDate)
            }
            .listRowBackground(Color.gray.opacity(0.1))
            
            Section {
                Button("重置所有电影数据") {
                    resetAllData()
                }
            }
            .listRowBackground(Color.white)
        }
        .foregroundColor(.black)
        .tint(.indigo)
        .background(Color.yellow)
        .scrollContentBackground(.hidden)
        .navigationBarTitle("电影追踪器")
    }
    
    private func resetAllData() {
        movieTitle = ""
        isWatched = false
        rating = 1
        watchDate = Date()
    }
}

struct LabeledContent: View {
    let label: String
    let value: String

    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
    }
}
```


## Picker选择器

### Picker
![](https://ming1016.github.io/qdimg/240505/picker-ap01.jpeg)

SwiftUI 中的 `Picker` 视图是一个用于选择列表中的一个选项的用户界面元素。你可以使用 `Picker` 视图来创建各种类型的选择器，包括滚动选择器、弹出菜单和分段控制。

示例代码如下：

```swift
struct PlayPickerView: View {
    @State private var select = 1
    @State private var color = Color.red.opacity(0.3)
    
    var dateFt: DateFormatter {
        let ft = DateFormatter()
        ft.dateStyle = .long
        return ft
    }
    @State private var date = Date()
    
    var body: some View {
        
        // 默认是下拉的风格
        Form {
            Section("选区") {
                Picker("选一个", selection: $select) {
                    Text("1")
                        .tag(1)
                    Text("2")
                        .tag(2)
                }
            }
        }
        .padding()
        
        // Segment 风格，
        Picker("选一个", selection: $select) {
            Text("one")
                .tag(1)
            Text("two")
                .tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        
        // 颜色选择器
        ColorPicker("选一个颜色", selection: $color, supportsOpacity: false)
            .padding()
        
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 50, height: 50)
        
        // 时间选择器
        VStack {
            DatePicker(selection: $date, in: ...Date(), displayedComponents: .date) {
                Text("选时间")
            }
            
            DatePicker("选时间", selection: $date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .frame(maxHeight: 400)
            
            Text("时间：\(date, formatter: dateFt)")
        }
        .padding()
    }
}
```

上面的代码中，有三种类型的 `Picker` 视图：

1. 默认的下拉风格 `Picker` 视图。这种类型的 `Picker` 视图在 `Form` 中使用，用户可以点击选择器来打开一个下拉菜单，然后从菜单中选择一个选项。

```swift
Form {
    Section("选区") {
        Picker("选一个", selection: $select) {
            Text("1")
                .tag(1)
            Text("2")
                .tag(2)
        }
    }
}
```

2. 分段控制风格 `Picker` 视图。这种类型的 `Picker` 视图使用 `SegmentedPickerStyle()` 修饰符，它将选择器显示为一组水平排列的按钮，用户可以点击按钮来选择一个选项。

```swift
Picker("选一个", selection: $select) {
    Text("one")
        .tag(1)
    Text("two")
        .tag(2)
}
.pickerStyle(SegmentedPickerStyle())
```

3. `ColorPicker` 和 `DatePicker` 视图。这两种类型的视图是 `Picker` 视图的特殊形式，它们分别用于选择颜色和日期。

```swift
ColorPicker("选一个颜色", selection: $color, supportsOpacity: false)

DatePicker("选时间", selection: $date)
    .datePickerStyle(GraphicalDatePickerStyle())
```

在所有这些 `Picker` 视图中，你都需要提供一个绑定的选择状态，这个状态会在用户选择一个新的选项时更新。你还需要为每个选项提供一个视图和一个唯一的标签。



### 文字Picker

#### 基本使用

文字 Picker 示例：

```swift
struct StaticDataPickerView: View {
    @State private var selectedCategory = "动作"

    var body: some View {
        VStack {
            Text("选择的类别: \(selectedCategory)")

            Picker("电影类别",
                 selection: $selectedCategory) {
                Text("动作")
                    .tag("动作")
                Text("喜剧")
                    .tag("喜剧")
                Text("剧情")
                    .tag("剧情")
                Text("恐怖")
                    .tag("恐怖")
            }
        }
    }
}
```

#### 使用枚举

使用枚举来创建选取器的示例：

```swift
enum MovieCategory: String, CaseIterable, Identifiable {
    case action = "动作"
    case comedy = "喜剧"
    case drama = "剧情"
    case horror = "恐怖"
    var id: MovieCategory { self }
}

struct MoviePicker: View {
   @State private var selectedCategory: MovieCategory = .action

  var body: some View {
     Picker("电影类别", selection: $selectedCategory) {
        ForEach(MovieCategory.allCases) { category in
             Text(category.rawValue).tag(category)
       }
     }
   }
}
```


#### 样式

SwiftUI 提供了多种内置的 `Picker` 样式，以改变 `Picker` 的外观和行为。以下是一些主要的 `Picker` 样式及其使用示例：

- `DefaultPickerStyle`：根据平台和环境自动调整样式。这是默认的 `Picker` 样式。

```swift
Picker("Label", selection: $selection) {
    ForEach(0..<options.count) {
        Text(self.options[$0])
    }
}
```

- `WheelPickerStyle`：以旋转轮的形式展示选项。在 iOS 上，这种样式会显示一个滚动的选择器。

```swift
Picker("Label", selection: $selection) {
    ForEach(0..<options.count) {
        Text(self.options[$0])
    }
}
.pickerStyle(WheelPickerStyle())
```

- `SegmentedPickerStyle`：将选项以分段控件的形式展示。这种样式会显示一个分段控制，用户可以在其中选择一个选项。

```swift
Picker("Label", selection: $selection) {
    ForEach(0..<options.count) {
        Text(self.options[$0])
    }
}
.pickerStyle(SegmentedPickerStyle())
```

- `InlinePickerStyle`：在列表或表格中内联展示选项。这种样式会在 `Form` 或 `List` 中显示一个内联的选择器。

```swift
Form {
    Picker("Label", selection: $selection) {
        ForEach(0..<options.count) {
            Text(self.options[$0])
        }
    }
    .pickerStyle(InlinePickerStyle())
}
```

- `MenuPickerStyle`：点击时以菜单的形式展示选项。这种样式会显示一个菜单，用户可以在其中选择一个选项。

```swift
Picker("Label", selection: $selection) {
    ForEach(0..<options.count) {
        Text(self.options[$0])
    }
}
.pickerStyle(MenuPickerStyle())
```

- `.navigationLink`：在 iOS 16+ 中，点击后进入下一个页面。这种样式会显示一个导航链接，用户可以点击它来打开一个新的视图。
- `.radioGrouped`：仅在 macOS 中可用，以单选按钮组的形式展示选项。这种样式会显示一个单选按钮组，用户可以在其中选择一个选项。


### ColorPicker


`ColorPicker` 是一个允许用户选择颜色的视图。以下是一个 `ColorPicker` 的使用示例：

```swift
import SwiftUI

struct ContentView: View {
    @State private var selectedColor = Color.white

    var body: some View {
        VStack {
            ColorPicker("选择一个颜色", selection: $selectedColor)
            Text("你选择的颜色")
                .foregroundColor(selectedColor)
        }
    }
}
```

在这个示例中，我们创建了一个 `ColorPicker` 视图，用户可以通过这个视图选择一个颜色。我们使用 `@State` 属性包装器来创建一个可以绑定到 `ColorPicker` 的 `selectedColor` 状态。当用户选择一个新的颜色时，`selectedColor` 状态会自动更新，`Text` 视图的前景色也会相应地更新。


### DatePicker


#### 基本使用

```swift
struct ContentView: View {
    @State private var releaseDate: Date = Date()

    var body: some View {
        VStack(spacing: 30) {
            DatePicker("选择电影发布日期", selection: $releaseDate, displayedComponents: .date)
            Text("选择的发布日期: \(releaseDate, formatter: DateFormatter.dateMedium)")
        }
        .padding()
    }
}
```


#### 选择多个日期

在 iOS 16 中，您现在可以允许用户选择多个日期，MultiDatePicker 视图会显示一个日历，用户可以选择多个日期，可以设置选择范围。示例如下：
```swift
struct PMultiDatePicker: View {
    @Environment(\.calendar) var cal
    @State var dates: Set<DateComponents> = []
    var body: some View {
        MultiDatePicker("选择个日子", selection: $dates, in: Date.now...)
        Text(s)
    }
    var s: String {
        dates.compactMap { c in
            cal.date(from:c)?.formatted(date: .long, time: .omitted)
        }
        .formatted()
    }
}
```

#### 指定日期范围

指定日期的范围，例如只能选择当前日期之后的日期，示例如下：

```swift
DatePicker(
    "选择日期",
    selection: $selectedDate,
    in: Date()...,
    displayedComponents: [.date]
)
.datePickerStyle(WheelDatePickerStyle())
.labelsHidden()
```

在这个示例中：

- `selection: $selectedDate` 表示选定的日期和时间。
- `in: Date()...` 表示可选日期的范围。在这个例子中，用户只能选择当前日期之后的日期。你也可以使用 `...Date()` 来限制用户只能选择当前日期之前的日期，或者使用 `Date().addingTimeInterval(86400*7)` 来限制用户只能选择从当前日期开始的接下来一周内的日期。
- `displayedComponents: [.date]` 表示 `DatePicker` 应该显示哪些组件。在这个例子中，我们只显示日期组件。你也可以使用 `.hourAndMinute` 来显示小时和分钟组件，或者同时显示日期和时间组件。
- `.datePickerStyle(WheelDatePickerStyle())` 表示 `DatePicker` 的样式。在这个例子中，我们使用滚轮样式。你也可以使用 `GraphicalDatePickerStyle()` 来应用图形样式。
- `.labelsHidden()` 表示隐藏 `DatePicker` 的标签。


### PhotoPicker

#### PhotoPicker 使用示例

```swift
import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    var body: some View {
        NavigationView {
            VStack {
                if let item = selectedItem, let data = selectedPhotoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("选择电影海报")
                }
            }
            .navigationTitle("电影海报")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("选择照片", systemImage: "photo")
                    }
                    .tint(.indigo)
                    .controlSize(.extraLarge)
                    .buttonStyle(.borderedProminent)
                }
            }
            .onChange(of: selectedItem, { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    }
                }
            })
        }
    }
}
```

#### 限制选择媒体类型

我们可以使用 `matching` 参数来过滤 `PhotosPicker` 中显示的媒体类型。这个参数接受一个 `PHAssetMediaType` 枚举值，可以是 `.images`、`.videos`、`.audio`、`.any` 等。

例如，如果我们只想显示图片，可以这样设置：

```swift
PhotosPicker(selection: $selectedItem, matching: .images) {
    Label("选择照片", systemImage: "photo")
}
```

如果我们想同时显示图片和视频，可以使用 `.any(of:)` 方法：

```swift
PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
    Label("选择照片", systemImage: "photo")
}
```

此外，我们还可以使用 `.not(_:)` 方法来排除某种类型的媒体。例如，如果我们想显示所有的图片，但是不包括 Live Photo，可以这样设置：

```swift
PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .not(.livePhotos)])) {
    Label("选择照片", systemImage: "photo")
}
```

这些设置可以让我们更精确地控制 `PhotosPicker` 中显示的媒体类型。


#### 选择多张图片

以下示例演示了如何使用 `PhotosPicker` 选择多张图片，并将它们显示在一个 `LazyVGrid` 中：

```swift
import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItems: [PhotosPickerItem] = [PhotosPickerItem]()
    @State private var selectedPhotosData: [Data] = [Data]()

    var body: some View {
        NavigationStack {

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(selectedPhotosData, id: \.self) { photoData in
                        if let image = UIImage(data: photoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(10.0)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("书籍")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                        Image(systemName: "book.fill")
                            .foregroundColor(.brown)
                    }
                    .onChange(of: selectedItems, { oldValue, newValue in
                        for newItem in newValue {
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    selectedPhotosData.append(data)
                                }
                            }
                        }
                    })
                }
            }
        }
    }
}
```

以上示例中，我们使用了 `PhotosPicker` 的 `maxSelectionCount` 参数来限制用户最多只能选择 5 张图片。当用户选择图片后，我们将图片数据保存在 `selectedPhotosData` 数组中，并在 `LazyVGrid` 中显示这些图片。




### 字体Picker

这段代码实现了一个字体选择器的功能，用户可以在其中选择和查看自己喜欢的字体。

```swift
struct ContentView: View {
    @State private var fontFamily: String = ""

    var body: some View {
        VStack {
            Text("选择字体:")
            FontPicker(fontFamily: $fontFamily)
                .equatable()
        }
    }
}

struct FontPicker: View, Equatable {
    @Binding var fontFamily: String

    var body: some View {
        VStack {
            Text("\(fontFamily)")
                .font(.custom(fontFamily, size: 20))
            Picker("", selection: $fontFamily) {
                ForEach(NSFontManager.shared.availableFontFamilies, id: \.self) { family in
                    Text(family)
                        .tag(family)
                }
            }
            Spacer()
        }
        .padding()
    }

    static func == (l: FontPicker, r: FontPicker) -> Bool {
        l.fontFamily == r.fontFamily
    }
}
```

### WheelPicker

本示例是一个可折叠的滚轮选择器 `CollapsibleWheelPicker`。这个选择器允许用户从一组书籍中选择一本。

```swift
struct ContentView: View {
  @State private var selection = 0
  let items = ["Book 1", "Book 2", "Book 3", "Book 4", "Book 5"]

  var body: some View {
    NavigationStack {
      Form {
        CollapsibleWheelPicker(selection: $selection) {
          ForEach(items, id: \.self) { item in
            Text("\(item)")
          }
        } label: {
          Text("Books")
          Spacer()
          Text("\(items[selection])")
        }
      }
    }
  }
}

struct CollapsibleWheelPicker<SelectionValue, Content, Label>: View where SelectionValue: Hashable, Content: View, Label: View {
    @Binding var selection: SelectionValue
    @ViewBuilder let content: () -> Content
    @ViewBuilder let label: () -> Label

    var body: some View {
        CollapsibleView(label: label) {
            Picker(selection: $selection, content: content) {
                EmptyView()
            }
            .pickerStyle(.wheel)
        }
    }
}

struct CollapsibleView<Label, Content>: View where Label: View, Content: View {
  @State private var isSecondaryViewVisible = false

  @ViewBuilder let label: () -> Label
  @ViewBuilder let content: () -> Content

  var body: some View {
    Group {
      Button(action: { isSecondaryViewVisible.toggle() }, label: label)
        .buttonStyle(.plain)
      if isSecondaryViewVisible {
        content()
      }
    }
  }
}

```

在 `ContentView` 中，我们创建了一个 `CollapsibleWheelPicker` 视图。这个视图包含一个滚轮样式的选择器，用户可以从中选择一本书。选择的书籍会绑定到 `selection` 变量。

`CollapsibleWheelPicker` 视图是一个可折叠的滚轮选择器，它接受一个绑定的选择变量、一个内容视图和一个标签视图。内容视图是一个 `Picker` 视图，用于显示可供选择的书籍。标签视图是一个 `Text` 视图，显示当前选择的书籍。

## Toggle
![](https://ming1016.github.io/qdimg/240505/toggle-ap01.png)



### 示例

使用示例如下

```swift
struct PlayToggleView: View {
    @State private var isEnable = false
    var body: some View {
        // 普通样式
        Toggle(isOn: $isEnable) {
            Text("\(isEnable ? "开了" : "关了")")
        }
        .padding()
        
        // 按钮样式
        Toggle(isOn: $isEnable) {
            Label("\(isEnable ? "打开了" : "关闭了")", systemImage: "cloud.moon")
        }
        .padding()
        .tint(.pink)
        .controlSize(.large)
        .toggleStyle(.button)
        
        // Switch 样式
        Toggle(isOn: $isEnable) {
            Text("\(isEnable ? "开了" : "关了")")
        }
        .toggleStyle(SwitchToggleStyle(tint: .orange))
        .padding()
        
        // 自定义样式
        Toggle(isOn: $isEnable) {
            Text(isEnable ? "录音中" : "已静音")
        }
        .toggleStyle(PCToggleStyle())
        
    }
}

// MARK: - 自定义样式
struct PCToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return HStack {
            configuration.label
            Image(systemName: configuration.isOn ? "mic.square.fill" : "mic.slash.circle.fill")
                .renderingMode(.original)
                .resizable()
                .frame(width: 30, height: 30)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
```

### 样式

Toggle 可以设置 toggleStyle，可以自定义样式。

下表是不同平台支持的样式

- DefaultToggleStyle：iOS 表现的是 Switch，macOS 是 Checkbox
- SwitchToggleStyle：iOS 和 macOS 都支持
- CheckboxToggleStyle：只支持 macOS

### 纯图像的 Toggle

```swift
struct ContentView: View {
    @State private var isMuted = false

    var body: some View {
        Toggle(isOn: $isMuted) {
            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.fill")
                .font(.system(size: 50))
        }
        .tint(.red)
        .toggleStyle(.button)
        .clipShape(Circle())
    }
}
```

### 自定义 ToggleStyle

做一个自定义的切换按钮 OfflineModeToggleStyle。这个切换按钮允许用户控制是否开启离线模式。代码如下：

```swift
struct ContentView: View {
    @State private var isOfflineMode = false

    var body: some View {
        Toggle(isOn: $isOfflineMode) {
            Text("Offline Mode")
        }
        .toggleStyle(OfflineModeToggleStyle(systemImage: isOfflineMode ? "wifi.slash" : "wifi", activeColor: .blue))
    }
}

struct OfflineModeToggleStyle: ToggleStyle {
    var systemImage: String
    var activeColor: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? activeColor : Color(.systemGray5))
                .overlay {
                    Circle()
                        .fill(.white)
                        .padding(2)
                        .overlay {
                            Image(systemName: systemImage)
                                .foregroundColor(configuration.isOn ? activeColor : Color(.systemGray5))
                        }
                        .offset(x: configuration.isOn ? 8 : -8)
                }
                .frame(width: 50, height: 32)
                .onTapGesture {
                    withAnimation(.spring()) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
```

以上代码中，我们定义了一个 OfflineModeToggleStyle，它接受两个参数：systemImage 和 activeColor。systemImage 是一个字符串，表示图像的系统名称。activeColor 是一个颜色，表示激活状态的颜色。

### 动画化的 Toggle

以下是一个自定义的切换按钮 MuteToggleStyle。这个切换按钮允许用户控制是否开启静音模式。

```swift
struct ContentView: View {
    @State private var isMuted = false

    var body: some View {
        VStack {
            Toggle(isOn: $isMuted) {
                Text("Mute Mode")
                    .foregroundColor(isMuted ? .white : .black)
            }
            .toggleStyle(MuteToggleStyle())
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MuteToggleStyle: ToggleStyle {
    var onImage = "speaker.slash.fill"
    var offImage = "speaker.2.fill"

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            RoundedRectangle(cornerRadius: 30)
                .fill(configuration.isOn ? Color(.systemGray6) : .yellow)
                .overlay {
                    Image(systemName: configuration.isOn ? onImage : offImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .padding(5)
                        .rotationEffect(.degrees(configuration.isOn ? 0 : 180))
                        .offset(x: configuration.isOn ? 10 : -10)
                }
                .frame(width: 50, height: 32)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

extension ToggleStyle where Self == MuteToggleStyle {
    static var mute: MuteToggleStyle { .init() }
}
```

以上代码中，我们定义了一个 MuteToggleStyle，它接受两个参数：onImage 和 offImage。onImage 是一个字符串，表示激活状态的图像的系统名称。offImage 是一个字符串，表示非激活状态的图像的系统名称。

### 两个标签的 Toggle

以下是一个自定义的切换按钮，它有两个标签。这个切换按钮允许用户控制是否开启静音模式。

```swift
Toggle(isOn: $mute) {
  Text("静音")
  Text("这将关闭所有声音")
}
```


## Slider

简单示例

```swift
struct PlaySliderView: View {
    @State var count: Double = 0
    var body: some View {
        Slider(value: $count, in: 0...100)
            .padding()
        Text("\(Int(count))")
    }
}
```

以下代码演示了如何创建一个自定义的 `Slider` 控件，用于调整亮度。

```swift
struct ContentView: View {
    @State private var brightness: Double = 50
    @State private var isEditing: Bool = false

    var body: some View {
        VStack {
            Text("Brightness Control")
                .font(.title)
                .padding()

            BrightnessSlider(value: $brightness, range: 0...100, step: 5, isEditing: $isEditing)

            Text("Brightness: \(Int(brightness)), is changing: \(isEditing)")
                .font(.footnote)
                .padding()
        }
    }
}

struct BrightnessSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    @Binding var isEditing: Bool

    var body: some View {
        Slider(value: $value, in: range, step: step) {
            Label("亮度", systemImage: "light.max")
        } minimumValueLabel: {
            Text("\(Int(range.lowerBound))")
        } maximumValueLabel: {
            Text("\(Int(range.upperBound))")
        } onEditingChanged: {
            print($0)
        }

    }
}
```

以上代码中，我们创建了一个 `BrightnessSlider` 控件，它是一个自定义的 `Slider` 控件，用于调整亮度。`BrightnessSlider` 接受一个 `value` 绑定，一个 `range` 范围，一个 `step` 步长，以及一个 `isEditing` 绑定。在 `BrightnessSlider` 中，我们使用 `Slider` 控件来显示亮度调整器。我们还使用 `Label` 来显示亮度调整器的标题，并使用 `minimumValueLabel` 和 `maximumValueLabel` 来显示亮度调整器的最小值和最大值。最后，我们使用 `onEditingChanged` 修饰符来监听亮度调整器的编辑状态。
## Stepper


`Stepper` 控件允许用户通过点击按钮来增加或减少数值。

```swift
struct ContentView: View {
    @State private var count: Int = 2
    var body: some View {
        Stepper(value: $count, in: 2...20, step: 2) {
            Text("共\(count)")
        } onEditingChanged: { b in
            print(b)
        } // end Stepper
    }
}
```

在 `ContentView` 中，我们定义了一个状态变量 `count`，并将其初始化为 2。然后，我们创建了一个 `Stepper` 视图，并将其绑定到 `count` 状态变量。

`Stepper` 视图的值范围为 2 到 20，步进值为 2，这意味着每次点击按钮，`count` 的值会增加或减少 2。我们还添加了一个标签，显示当前的 `count` 值。

我们还添加了 `onEditingChanged` 回调，当 `Stepper` 的值改变时，会打印出一个布尔值，表示 `Stepper` 是否正在被编辑。


