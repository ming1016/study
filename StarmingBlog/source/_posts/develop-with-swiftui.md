---
title: 在苹果加速器活动做的 SwiftUI 开发分享
date: 2022-03-25 13:04:49
tags: [Apple, SwiftUI]
categories: Programming
banner_img: /uploads/develop-with-swiftui/21.PNG
---

受 Apple 加速器 SwiftUI 活动邀请，做了个分享，还和喵神、61、浙剑、思琪等社区大神参与了圆桌讨论。这次完善了 SwiftUI 做的幻灯片，比去年要好一点，增加了解释执行代码交互功能。

为这次幻灯画了几张图，在新西兰认识的画家，指导我了些画法，用其完成了幻灯里的图。

![](/uploads/develop-with-swiftui/20.PNG)
![](/uploads/develop-with-swiftui/21.PNG)
![](/uploads/develop-with-swiftui/22.png)
![](/uploads/develop-with-swiftui/24.PNG)
![](/uploads/develop-with-swiftui/25.PNG)

## macOS 多栏

![](/uploads/develop-with-swiftui/06.png)

内容有 macOS 多栏、Toolbar、文件夹嵌套、文本和代码编辑器、网格视图和斜45度视觉。

macOS 的多栏只需要使用 NavigationView 就可以了，闭包里的第一个视图就是 Sidebar，后面的视图可以作为占位视图，显示一些初始信息，通过 Sidebar 的 NavigationLink 来设置第二栏的视图就好了，第三栏通过第二栏来指定。

如果想要隐藏收起 Sidebar 需要先获取 SplitViewController，然后调用 toggleSidebar 方法就可以了。如果想要收起最右侧视图或任意一栏视图，可以在 SplitViewController 的 splitViewItems 里找到对应的 Item，比如最右一栏就是 splitViewItems.last。调用找到视图的 animator().isCollapsed.toggle() 就可以了。

如果只想让其中一栏全屏显示，先在 splitViewItems 找到那一栏，然后调用对应 ViewController 里 View 的 enterFullScreenMode 方法，要注意的是，设置的 Options 需要包含 .autoHideDock 和 .autoHideMenuBar，否则就没法退出全屏了。由于全屏后会将视图放到另一个 Window 中，因此退出全屏可以直接调用当前 key window 的 contentView 的 exitFullScreenMode() 方法。

## Toolbar

![](/uploads/develop-with-swiftui/18.png)

一般的 macOS 程序多栏顶部会有一些功能按钮，以方便用户了解到程序的主要高频功能，比如 Xcode 的调试和 Target 选择按钮，Keynote 的播放、添加幻灯片、缩放文本、形状、表格、图表等按钮。这些按钮都可以通过 Toolbar 来实现。Toolbar 根据摆放位置和语义设置了一组 Options，通过 Options 统一了多平台的表现形式，比如默认位置的 option 就是 .automatic，中间位置就是 .principal，macOS Touch Bar iOS 的虚拟键盘上的按钮用的就是 .keyboard。另外还有很多语义表示，用于放置到不同平台特定的位置，比如用于导航的按钮在 macOS 上会出现在最左侧，用的就是 .navigation 这种语义的 Options。

## 文件夹嵌套结构

得益于 keypaths 在 SwiftUI 中的应用，文件夹嵌套结构实现起来简单了太多。给 List 的 children 参数指定嵌套模型的嵌套键值路径即可，比如模型结构如下：

```swift
// MARK: - 目录结构数据模型
struct POM: Hashable, Identifiable {
  var id = UUID()
  var s: String // 文字
  var i: String // 图标
  var sub: [POM] ?
}
```

其中嵌套键值是 sub，那么 children 参数只需要添上 `\.sub` ，List 内部会处理嵌套逻辑并展示出来。如果 List 表现出来的效果并不能够满足你，你也可以自己定制视图和交互。比如点击文件夹名字也能够展开子内容，List 默认只有点击左侧箭头才能够展开。

自定义嵌套视图底层可以使用 DisclosureGroup，DisclosureGroup 能够展示自定义视图内容，还有一个 isExpanded 值绑定参数用来显示和隐藏内容。在遍历已展示视图时，通过 keypaths 发现嵌套值不为空时就读取子内容，同时默认 isExpanded 值为 false 就会显示不展开的箭头符号，将文件夹名字做成按钮，点击按钮触发 isExpanded.toggle()，如 isExpanded 为 false 就置为 true，即展开文件夹，反之就会收起文件夹。

![](/uploads/develop-with-swiftui/07.png)

## 文本和代码编辑器

文本和代码编辑器也是 macOS 上很常见的效率工具的核心功能，包含的技术点较多，比如调试和代码分析会用到编译器这里就不展开说了。感兴趣可以参看[深入剖析 iOS 编译 Clang / LLVM](https://ming1016.github.io/2017/03/01/deeply-analyse-llvm/)、[深入剖析 iOS 编译 Clang / LLVM 直播的 Slides](https://ming1016.github.io/2017/04/01/slides-of-deeply-analyse-llvm/)、[atSwift大会上分享《学习iOS编译原理能做哪些有意思的事情》的 Slides](https://ming1016.github.io/2017/05/27/slides-of-learn-what-interesting-things-you-can-do-with-iOS-compilation/)、[这次swift大会分享准备的幻灯片和 demo](https://ming1016.github.io/2018/09/17/produce-slides-of-third-at-swift-conference/)，这几篇。

文本或代码分析完后可以通过 Attribute 来进行富文本展示的设置，富文本属性都在 AttributeContainer 中设置，设置好的富文本直接通过 append 进行组合。编辑器其它的比如编辑、重做、存储或自定义的能力可以通过 NSViewRepresentable 来包装 Appkit 直接使用 Appkit 里的 NSTextView 的能力。

![](/uploads/develop-with-swiftui/12.png)

## Grid

![](/uploads/develop-with-swiftui/14.png)

## Vision

![](/uploads/develop-with-swiftui/17.png)

接下来详细的说下 SwiftUI 的视图组件的使用，这次的幻灯片程序用到的技术，除了解释执行代码的功能，其它基本都来自下面的内容。

## SwiftUI 组件


### 视图组件使用

#### SwiftUI 对标的 UIKit 视图

如下：

| SwiftUI | UIKit |
| ----------- | ----------- |
| Text 和 Label | UILabel |
| TextField | UITextField |
| TextEditor | UITextView |
| Button 和 Link | UIButton |
| Image | UIImageView |
| NavigationView | UINavigationController 和 UISplitViewController |
| ToolbarItem | UINavigationItem |
| ScrollView | UIScrollView |
| List | UITableView |
| LazyVGrid 和 LazyHGrid | UICollectionView |
| HStack 和 LazyHStack | UIStack |
| VStack 和 LazyVStack | UIStack |
| TabView | UITabBarController 和 UIPageViewController |
| Toggle | UISwitch |
| Slider | UISlider |
| Stepper | UIStepper |
| ProgressView | UIProgressView 和 UIActivityIndicatorView |
| Picker | UISegmentedControl |
| DatePicker | UIDatePicker |
| Alert | UIAlertController |
| ActionSheet | UIAlertController |
| Map | MapKit |


#### Text

基本用法

![](/uploads/develop-with-swiftui/g01.png)

```swift
// MARK: - Text
struct PlayTextView: View {
    let manyString = "这是一段长文。总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么吧。"
    var body: some View {
        ScrollView {
            Group {
                Text("大标题").font(.largeTitle)
                Text("说点啥呢？")
                    .tracking(30) // 字间距
                    .kerning(30) // 尾部留白
                Text("划重点")
                    .underline()
                    .foregroundColor(.yellow)
                    .fontWeight(.heavy)
                Text("可旋转的文字")
                    .rotationEffect(.degrees(45))
                    .fixedSize()
                    .frame(width: 20, height: 80)
                Text("自定义系统字体大小")
                    .font(.system(size: 30))
                Text("使用指定的字体")
                    .font(.custom("Georgia", size: 24))
            }
            Group {
                Text("有阴影")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .bold()
                    .italic()
                    .shadow(color: .black, radius: 1, x: 0, y: 2)
                Text("Gradient Background")
                    .font(.largeTitle)
                    .padding()
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors: [.white, .black, .red]), startPoint: .top, endPoint: .bottom))
                    .cornerRadius(10)
                Text("Gradient Background")
                    .padding(5)
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors: [.white, .black, .purple]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                ZStack {
                    Text("渐变透明材质风格")
                        .padding()
                        .background(
                            .regularMaterial,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .shadow(radius: 10)
                        .padding()
                        .font(.largeTitle.weight(.black))
                }
                .frame(width: 300, height: 200)
                .background(
                    LinearGradient(colors: [.yellow, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                Text("Angular Gradient Background")
                    .padding()
                    .background(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center))
                    .cornerRadius(20)
                Text("带背景图片的")
                    .padding()
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .background {
                        Rectangle()
                            .fill(Color(.black))
                            .cornerRadius(10)
                        Image("logo")
                            .resizable()
                            .frame(width: 100, height: 100)
                    }
                    .frame(width: 200, height: 100)
            }

            Group {
                // 设置 lineLimit 表示最多支持行数，依据情况依然有会被减少显示行数
                Text(manyString)
                    .lineLimit(3) // 对行的限制，如果多余设定行数，尾部会显示...
                    .lineSpacing(10) // 行间距
                    .multilineTextAlignment(.leading) // 对齐
                
                // 使用 fixedSize 就可以在任何时候完整显示
                Text(manyString)
                    .fixedSize(horizontal: false, vertical: true)
                
            }
            
            // 使用 AttributeString
            PTextViewAttribute()
                .padding()

            // 使用 Markdown
            PTextViewMarkdown()
                .padding()
            
            // 时间
            PTextViewDate()
            
            // 插值
            PTextViewInterpolation()
        }

    }
}
```

font 字体设置的样式对应 weight 和 size 可以在官方交互文档中查看 [Typography](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/#dynamic-type-sizes)

markdown 使用
```swift
// MARK: - Markdown
struct PTextViewMarkdown: View {
    let mdaStr: AttributedString = {
        
        var mda = AttributedString(localized: "这是一个 **Attribute** ~string~")
        
        /// 自定义的属性语法是^[string](key：value)
        mda = AttributedString(localized: "^[这是](p2:'one')^[一](p3:{k1:1,k2:2})个 **Attribute** ~string~", including: \.newScope)
        print(mda)
        /// 这是 {
        ///     NSLanguage = en
        ///     p2 = one
        /// }
        /// 一 {
        ///     NSLanguage = en
        ///     p3 = P3(k1: 1, k2: 2)
        /// }
        /// 个  {
        ///     NSLanguage = en
        /// }
        /// Attribute {
        ///     NSLanguage = en
        ///     NSInlinePresentationIntent = NSInlinePresentationIntent(rawValue: 2)
        /// }
        ///   {
        ///     NSLanguage = en
        /// }
        /// string {
        ///     NSInlinePresentationIntent = NSInlinePresentationIntent(rawValue: 32)
        ///     NSLanguage = en
        /// }
        
        // 从文件中读取 Markdown 内容
        let mdUrl = Bundle.main.url(forResource: "1", withExtension: "md")!
        mda = try! AttributedString(contentsOf: mdUrl,options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace), baseURL: nil) // .inlineOnlyPreservingWhitespace 支持 markdown 文件的换行
                
        // Markdown 已转换成 AtrributedString 结构。
        for r in mda.runs {
            if let ipi = r.inlinePresentationIntent {
                switch ipi {
                case .lineBreak:
                    print("paragrahp")
                case .code:
                    print("this is code")
                default:
                    break
                }
            }
            if let pi = r.presentationIntent {
                for c in pi.components {
                    switch c.kind {
                    case .paragraph:
                        print("this is paragraph")
                    case .codeBlock(let lang):
                        print("this is \(lang ?? "") code")
                    case .header(let level):
                        print("this is \(level) level")
                    default:
                        break
                    }
                }
            }
        }
        
        return mda
    }()
    var body: some View {
        Text(mdaStr)
    }
}
```

AttributedString 的使用
```swift
// MARK: - AttributedString
struct PTextViewAttribute: View {
    let aStr: AttributedString = {
        var a1 = AttributedString("这是一个 ")
        var c1 = AttributeContainer()
        c1.font = .footnote
        c1.foregroundColor = .secondary
        a1.setAttributes(c1)
        
        var a2 = AttributedString("Attribute ")
        var c2 = AttributeContainer()
        c2.font = .title
        a2.setAttributes(c2)
        
        var a3 = AttributedString("String ")
        var c3 = AttributeContainer()
        c3.baselineOffset = 10
        c3.appKit.foregroundColor = .yellow // 仅在 macOS 里显示的颜色
        c3.swiftUI.foregroundColor = .secondary
        c3.font = .footnote
        a3.setAttributes(c3)
        // a3 使用自定义属性
        a3.p1 = "This is a custom property."
        
        // formatter 的支持
        var a4 = Date.now.formatted(.dateTime
                                        .hour()
                                        .minute()
                                        .weekday()
                                        .attributed
        )
        
        let c4AMPM = AttributeContainer().dateField(.amPM)
        let c4AMPMColor = AttributeContainer().foregroundColor(.green)
        
        a4.replaceAttributes(c4AMPM, with: c4AMPMColor)
        let c4Week = AttributeContainer().dateField(.weekday)
        let c4WeekColor = AttributeContainer().foregroundColor(.purple)
        a4.replaceAttributes(c4Week, with: c4WeekColor)
        
        a1.append(a2)
        a1.append(a3)
        a1.append(a4)
        
        
        
        // Runs 视图
        for r in a1.runs {
            print(r)
        }
        /// 这是一个  {
        ///     SwiftUI.Font = Font(provider: SwiftUI.(unknown context at $7ff91d4a5e90).FontBox<SwiftUI.Font.(unknown context at $7ff91d4ad5d8).TextStyleProvider>)
        ///     SwiftUI.ForegroundColor = secondary
        /// }
        /// Attribute  {
        ///     SwiftUI.Font = Font(provider: SwiftUI.(unknown context at $7ff91d4a5e90).FontBox<SwiftUI.Font.(unknown context at $7ff91d4ad5d8).TextStyleProvider>)
        /// }
        /// String  {
        ///     SwiftUI.ForegroundColor = secondary
        ///     SwiftUI.BaselineOffset = 10.0
        ///     NSColor = sRGB IEC61966-2.1 colorspace 1 1 0 1
        ///     SwiftUI.Font = Font(provider: SwiftUI.(unknown context at $7ff91d4a5e90).FontBox<SwiftUI.Font.(unknown context at $7ff91d4ad5d8).TextStyleProvider>)
        ///     p1 = This is a custom property.
        /// }
        /// Tue {
        ///     SwiftUI.ForegroundColor = purple
        /// }
        ///   {
        /// }
        /// 5 {
        ///     Foundation.DateFormatField = hour
        /// }
        /// : {
        /// }
        /// 16 {
        ///     Foundation.DateFormatField = minute
        /// }
        ///   {
        /// }
        /// PM {
        ///     SwiftUI.ForegroundColor = green
        /// }
        
        return a1
    }()
    var body: some View {
        Text(aStr)
    }
}

// MARK: - 自定 AttributedString 属性
struct PAKP1: AttributedStringKey {
    typealias Value = String
    static var name: String = "p1"
    
    
}
struct PAKP2: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    public enum P2: String, Codable {
        case one, two, three
    }

    static var name: String = "p2"
    typealias Value = P2
}
struct PAKP3: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    public struct P3: Codable, Hashable {
        let k1: Int
        let k2: Int
    }
    typealias Value = P3
    static var name: String = "p3"
}
extension AttributeScopes {
    public struct NewScope: AttributeScope {
        let p1: PAKP1
        let p2: PAKP2
        let p3: PAKP3
    }
    var newScope: NewScope.Type {
        NewScope.self
    }
}

extension AttributeDynamicLookup{
    subscript<T>(dynamicMember keyPath:KeyPath<AttributeScopes.NewScope,T>) -> T where T:AttributedStringKey {
        self[T.self]
    }
}
```


时间的显示

```swift
// MARK: - 时间
struct PDateTextView: View {
    let date: Date = Date()
    let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        return df
    }()
    var dv: String {
        return df.string(from: date)
    }
    var body: some View {
        HStack {
            Text(dv)
        }
        .environment(\.locale, Locale(identifier: "zh_cn"))
    }
}
```

插值使用

```swift
// MARK: - 插值
struct PTextViewInterpolation: View {
    let nf: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currencyPlural
        return f
    }()
    var body: some View {
        VStack {
            Text("图文 \(Image(systemName: "sun.min"))")
            Text("💰 \(999 as NSNumber, formatter: nf)")
                .environment(\.locale, Locale(identifier: "zh_cn"))
            Text("数组： \(["one", "two"])")
            Text("红字：\(red: "变红了")，带图标的字：\(sun: "天晴")")
        }
    }
}

// 扩展 LocalizedStringKey.StringInterpolation 自定义插值
extension LocalizedStringKey.StringInterpolation {
    // 特定类型处理
    mutating func appendInterpolation(_ value: [String]) {
        for s in value {
            appendLiteral(s + "")
            appendInterpolation(Text(s + " ").bold().foregroundColor(.secondary))
        }
    }
    
    // 实现不同情况处理，可以简化设置修改器设置
    mutating func appendInterpolation(red value: LocalizedStringKey) {
        appendInterpolation(Text(value).bold().foregroundColor(.red))
    }
    mutating func appendInterpolation(sun value: String) {
        appendInterpolation(Image(systemName: "sun.max.fill"))
        appendLiteral(value)
    }
}
```



#### Link

使用方法如下：

```swift
struct PlayLinkView: View {
    @Environment(\.openURL) var openURL
    var aStr: AttributedString {
        var a = AttributedString("戴铭的博客")
        a.link = URL(string: "https://ming1016.github.io/")
        return a
    }
    var body: some View {
        VStack {
            // 普通
            Link("前往 www.starming.com", destination: URL(string: "http://www.starming.com")!)
                .buttonStyle(.borderedProminent)
            Link(destination: URL(string: "https://twitter.com/daiming_cn")!) {
                Label("My Twitter", systemImage: "message.circle.fill")
            }
            
            // AttributedString 链接
            Text(aStr)
            
            // markdown 链接
            Text("[Go Ming's GitHub](https://github.com/ming1016)")
            
            // 控件使用 OpenURL
            Link("小册子源码", destination: URL(string: "https://github.com/KwaiAppTeam/SwiftPamphletApp")!)
                .environment(\.openURL, OpenURLAction { url in
                    return .systemAction
                    /// return .handled 不会返回系统打开浏览器动作，只会处理 return 前的事件。
                    /// .discard 和 .handled 类似。
                    /// .systemAction(URL(string: "https://www.anotherurl.com")) 可以返回另外一个 url 来替代指定的url
                })
            
            // 扩展 View 后更简洁的使用 OpenURL
            Link("戴铭的微博", destination: URL(string: "https://weibo.com/allstarming")!)
                .goOpenURL { url in
                    print(url.absoluteString)
                    return .systemAction
                }
            
            // 根据内容返回不同链接
            Text("戴铭博客有好几个，存在[GitHub Page](github)、[自建服务器](starming)和[知乎](zhihu)上")
                .environment(\.openURL, OpenURLAction { url in
                    switch url.absoluteString {
                    case "github":
                        return .systemAction(URL(string: "https://ming1016.github.io/")!)
                    case "starming":
                        return .systemAction(URL(string: "http://www.starming.com")!)
                    case "zhihu":
                        return .systemAction(URL(string: "https://www.zhihu.com/people/starming/posts")!)
                    default:
                        return .handled
                    }
                })
        } // end VStack
        .padding()
        
    }
    
    // View 支持 openURL 的能力
    func goUrl(_ url: URL, done: @escaping (_ accepted: Bool) -> Void) {
        openURL(url, completion: done)
    }
}

// 为 View 扩展一个 OpenURL 方法
extension View {
    func goOpenURL(done: @escaping (URL) -> OpenURLAction.Result) -> some View {
        environment(\.openURL, OpenURLAction(handler: done))
    }
}
```

View 的 onOpenURL 方法可以处理 Universal Links。

```swift
struct V: View {
    var body: some View {
        VStack {
            Text("hi")
        }
        .onOpenURL { url in
            print(url.absoluteString)
        }
    }
}
```

#### Label

![](/uploads/develop-with-swiftui/g02.png)

```swift
struct PlayLabelView: View {
    var body: some View {
        VStack(spacing: 10) {
            Label("一个 Label", systemImage: "bolt.circle")
            
            Label("只显示 icon", systemImage: "heart.fill")
                .labelStyle(.iconOnly)
                .foregroundColor(.red)
            
            // 自建 Label
            Label {
                Text("自建 Label")
                    .foregroundColor(.orange)
                    .bold()
                    .font(.largeTitle)
                    .shadow(color: .black, radius: 1, x: 0, y: 2)
            } icon: {
                Image("p3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30)
                    .shadow(color: .black, radius: 1, x: 0, y: 2)
            }

            
            // 自定义 LabelStyle
            Label("有边框的 Label", systemImage: "b.square.fill")
                .labelStyle(.border)
            
            Label("仅标题有边框", systemImage: "text.bubble")
                .labelStyle(.borderOnlyTitle)
            
            // 扩展的 Label
            Label("扩展的 Label", originalSystemImage: "cloud.sun.bolt.fill")
            
        } // end VStack
    } // end body
}

// 对 Label 做扩展
extension Label where Title == Text, Icon == Image {
    init(_ title: LocalizedStringKey, originalSystemImage systemImageString: String) {
        self.init {
            Text(title)
        } icon: {
            Image(systemName: systemImageString)
                .renderingMode(.original) // 让 SFSymbol 显示本身的颜色
        }

    }
}

// 添加自定义 LabelStyle，用来加上边框
struct BorderLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label(configuration)
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(.purple, lineWidth: 4))
            .shadow(color: .black, radius: 4, x: 0, y: 5)
            .labelStyle(.automatic) // 样式擦除器，防止样式被 .iconOnly、.titleOnly 这样的 LabelStyle 擦除了样式。
                        
    }
}
extension LabelStyle where Self == BorderLabelStyle {
    internal static var border: BorderLabelStyle {
        BorderLabelStyle()
    }
}

// 只给标题加边框
struct BorderOnlyTitleLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
            configuration.title
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(.pink, lineWidth: 4))
                .shadow(color: .black, radius: 1, x: 0, y: 1)
                .labelStyle(.automatic)
        }
    }
}
extension LabelStyle where Self == BorderOnlyTitleLabelStyle {
    internal static var borderOnlyTitle: BorderOnlyTitleLabelStyle {
        BorderOnlyTitleLabelStyle()
    }
}
```


#### TextEditor

![](/uploads/develop-with-swiftui/g03.png)

对应的代码如下：

```swift
import SwiftUI
import CodeEditorView

struct PlayTextEditorView: View {
    // for TextEditor
    @State private var txt: String = "一段可编辑文字...\n"
    @State private var count: Int = 0
    
    // for CodeEditorView
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var codeMessages: Set<Located<Message>> = Set ()
    @SceneStorage("editLocation") private var editLocation: CodeEditor.Location = CodeEditor.Location()
    var body: some View {
        
        // 使用 SwiftUI 自带 TextEditor
        TextEditor(text: $txt)
            .font(.title)
            .lineSpacing(10)
            .disableAutocorrection(true)
            .padding()
            .onChange(of: txt) { newValue in
                count = txt.count
            }
        Text("字数：\(count)")
            .foregroundColor(.secondary)
            .font(.footnote)
        
        // 使用的 CodeEditorView 显示和编辑代码高亮的代码，还有 minimap
        CodeEditor(text: .constant("""
static func number() {
    // Int
    let i1 = 100
    let i2 = 22
    print(i1 / i2) // 向下取整得 4

    // Float
    let f1: Float = 100.0
    let f2: Float = 22.0
    print(f1 / f2) // 4.5454545
    
    let f4: Float32 = 5.0
    let f5: Float64 = 5.0
    print(f4, f5) // 5.0 5.0 5.0

    // Double
    let d1: Double = 100.0
    let d2: Double = 22.0
    print(d1 / d2) // 4.545454545454546

    // 字面量
    print(Int(0b10101)) // 0b 开头是二进制
    print(Int(0x00afff)) // 0x 开头是十六进制
    print(2.5e4) // 2.5x10^4 十进制用 e
    print(0xAp2) // 10*2^2  十六进制用 p
    print(2_000_000) // 2000000
    
    // isMultiple(of:) 方法检查一个数字是否是另一个数字的倍数
    let i3 = 36
    print(i3.isMultiple(of: 9)) // true
}
"""),
                   messages: $codeMessages,
                   language: .swift,
                   layout: CodeEditor.LayoutConfiguration(showMinimap: true)
        )
            .environment(\.codeEditorTheme, colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight)
        
        // 包装的 NSTextView
        HSplitView {
            PNSTextView(text: .constant("左边写...\n"), onDidChange: { (s, i) in
                print("Typing \(i) times.")
            })
                .padding()
            PNSTextView(text: .constant("右边写...\n"))
                .padding()
        } // end HSplitView
    } // end body
}

// MARK: - 自己包装 NSTextView
struct PNSTextView: NSViewRepresentable {
    @Binding var text: String
    var onBeginEditing: () -> Void = {}
    var onCommit: () -> Void = {}
    var onDidChange: (String, Int) -> Void = { _,_  in }
    
    // 返回要包装的 NSView
    func makeNSView(context: Context) -> PNSTextConfiguredView {
        let t = PNSTextConfiguredView(text: text)
        t.delegate = context.coordinator
        return t
    }
    
    func updateNSView(_ view: PNSTextConfiguredView, context: Context) {
        view.text = text
        view.selectedRanges = context.coordinator.sRanges
    }
    
    // 回调
    func makeCoordinator() -> TextViewDelegate {
        TextViewDelegate(self)
    }
}

// 处理 delegate 回调
extension PNSTextView {
    class TextViewDelegate: NSObject, NSTextViewDelegate {
        var tView: PNSTextView
        var sRanges: [NSValue] = []
        var typeCount: Int = 0
        
        init(_ v: PNSTextView) {
            self.tView = v
        }
        // 开始编辑
        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            self.tView.text = textView.string
            self.tView.onBeginEditing()
        }
        // 每次敲字
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            typeCount += 1
            self.tView.text = textView.string
            self.sRanges = textView.selectedRanges
            self.tView.onDidChange(textView.string, typeCount)
        }
        // 提交
        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            self.tView.text = textView.string
            self.tView.onCommit()
        }
    }
}

// 配置 NSTextView
final class PNSTextConfiguredView: NSView {
    weak var delegate: NSTextViewDelegate?
    
    private lazy var tv: NSTextView = {
        let contentSize = sv.contentSize
        let textStorage = NSTextStorage()
        
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(containerSize: sv.frame.size)
        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(
            width: contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        
        layoutManager.addTextContainer(textContainer)
        
        let t = NSTextView(frame: .zero, textContainer: textContainer)
        t.delegate = self.delegate
        t.isEditable = true
        t.allowsUndo = true
        
        t.font = .systemFont(ofSize: 24)
        t.textColor = NSColor.labelColor
        t.drawsBackground = true
        t.backgroundColor = NSColor.textBackgroundColor
        
        t.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        t.minSize = NSSize(width: 0, height: contentSize.height)
        t.autoresizingMask = .width

        t.isHorizontallyResizable = false
        t.isVerticallyResizable   = true
        
        return t
    }()
    
    private lazy var sv: NSScrollView = {
        let s = NSScrollView()
        s.drawsBackground = true
        s.borderType = .noBorder
        s.hasVerticalScroller = true
        s.hasHorizontalRuler = false
        s.translatesAutoresizingMaskIntoConstraints = false
        s.autoresizingMask = [.width, .height]
        return s
    }()
    
    var text: String {
        didSet {
            tv.string = text
        }
    }
    
    var selectedRanges: [NSValue] = [] {
        didSet {
            guard selectedRanges.count > 0 else {
                return
            }
            tv.selectedRanges = selectedRanges
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Error coder")
    }
    
    init(text: String) {
        self.text = text
        super.init(frame: .zero)
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        sv.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sv)
        NSLayoutConstraint.activate([
            sv.topAnchor.constraint(equalTo: topAnchor),
            sv.trailingAnchor.constraint(equalTo: trailingAnchor),
            sv.bottomAnchor.constraint(equalTo: bottomAnchor),
            sv.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
        sv.documentView = tv
    } // end viewWillDraw

}
```

SwiftUI 中用 NSView，可以通过 NSViewRepresentable 来包装视图，这个协议主要是实现 makeNSView、updateNSView 和 makeCoordinator 三个方法。makeNSView 要求返回需要包装的 NSView。每当 SwiftUI 的状态变化时触发 updateNSView 方法的调用。为了实现 NSView 里的 delegate 和 SwiftUI 通信，就要用 makeCoordinator 返回一个用于处理 delegate 的实例。


#### TextField

![](/uploads/develop-with-swiftui/g04.png)

使用方法如下：

```swift
struct PlayTextFieldView: View {
    @State private var t = "Starming"
    @State private var showT = ""
    @State private var isEditing = false
    var placeholder = "输入些文字..."
    
    @FocusState private var isFocus: Bool
    
    var body: some View {
        VStack {
            TextField(placeholder, text: $t)
            
            // 样式设置
            TextField(placeholder, text: $t)
                .padding(10)
                .textFieldStyle(.roundedBorder) // textFieldStyle 有三个预置值 automatic、plain 和 roundedBorder。
                .multilineTextAlignment(.leading) // 对齐方式
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .border(.teal, width: 4)
                .background(.white)
                .foregroundColor(.brown)
                .textCase(.uppercase)

            // 多视图组合
            HStack {
                Image(systemName: "lock.circle")
                    .foregroundColor(.gray).font(.headline)
                TextField(placeholder, text: $t)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit {
                        showT = t
                        isFocus = true
                    }
                    .onChange(of: t) { newValue in
                        t = String(newValue.prefix(20)) // 限制字数
                    }
                Image(systemName: "eye.slash")
                    .foregroundColor(.gray)
                    .font(.headline)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray, lineWidth: 1)
            )
            .padding(.horizontal)

            Text(showT)


            // 自定义 textFieldStyle 样式
            TextField(placeholder, text: $t)
                .textFieldStyle(PClearTextStyle())
                .focused($isFocus)
        }
        .padding()
    } // end body
}

struct PClearTextStyle: TextFieldStyle {
    @ViewBuilder
    func _body(configuration: TextField<_Label>) -> some View {
        let mirror = Mirror(reflecting: configuration)
        let bindingText: Binding<String> = mirror.descendant("_text") as! Binding<String>
        configuration
            .overlay(alignment: .trailing) {
                Button(action: {
                    bindingText.wrappedValue = ""
                }, label: {
                    Image(systemName: "clear")
                })
            }
        
        let text: String = mirror.descendant("_text", "_value") as! String
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(text.count > 10 ? .pink : .gray, lineWidth: 4)
            )
    } // end func
}
```

目前iOS 和 iPadOS上支持的键盘有：

* asciiCapable：能显示标准 ASCII 字符的键盘
* asciiCapableNumberPad：只输出 ASCII 数字的数字键盘
* numberPad：用于输入 PIN 码的数字键盘
* numbersAndPunctuation：数字和标点符号的键盘
* decimalPad：带有数字和小数点的键盘
* phonePad：电话中使用的键盘
* namePhonePad：用于输入人名或电话号码的小键盘
* URL：用于输入URL的键盘
* emailAddress：用于输入电子邮件地址的键盘
* twitter：用于Twitter文本输入的键盘，支持@和#字符简便输入
* webSearch：用于网络搜索词和URL输入的键盘

可以通过 keyboardType 修改器来指定。


#### Button

![](/uploads/develop-with-swiftui/g05.png)

```swift
struct PlayButtonView: View {
    var asyncAction: () async -> Void = {
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch {}
    }
    @State private var isFollowed: Bool = false
    var body: some View {
        VStack {
            // 常用方式
            Button {
                print("Clicked")
            } label: {
                Image(systemName: "ladybug.fill")
                Text("Report Bug")
            }

            // 图标
            Button(systemIconName: "ladybug.fill") {
                print("bug")
            }
            .buttonStyle(.plain) // 无背景
            .simultaneousGesture(LongPressGesture().onEnded({ _ in
                print("长按") // macOS 暂不支持
            }))
            .simultaneousGesture(TapGesture().onEnded({ _ in
                print("短按") // macOS 暂不支持
            }))
            
            
            // iOS 15 修改器的使用。role 在 macOS 上暂不支持
            Button("要删除了", role: .destructive) {
                print("删除")
            }
            .tint(.purple)
            .controlSize(.large) // .regular 是默认大小
            .buttonStyle(.borderedProminent) // borderedProminent 可显示 tint 的设置。还有 bordered、plain 和 borderless 可选。
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .accentColor(.pink)
            .buttonBorderShape(.automatic) // 会依据 controlSize 调整边框样式
            .background(.ultraThinMaterial, in: Capsule()) // 添加材质就像在视图和背景间加了个透明层达到模糊的效果。效果由高到底分别是.ultraThinMaterial、.thinMaterial、.regularMaterial、.thickMaterial、.ultraThickMaterial。
            
            // 风格化
            Button(action: {
                //
            }, label: {
                Text("风格化").font(.largeTitle)
            })
            .buttonStyle(PStarmingButtonStyle())
            
            
            // 自定义 Button
            PCustomButton("点一下触发") {
                print("Clicked!")
            }
            
            // 自定义 ButtonStyle
            Button {
                print("Double Clicked!")
            } label: {
                Text("点两下触发")
            }
            .buttonStyle(PCustomPrimitiveButtonStyle())

            // 将 Text 视图加上另一个 Text 视图中，类型仍还是 Text。
            PCustomButton(Text("点我 ").underline() + Text("别犹豫").font(.title) + Text("🤫悄悄说声，有惊喜").font(.footnote).foregroundColor(.secondary)) {
                print("多 Text 组合标题按钮点击！")
            }
            
            // 异步按钮
            ButtonAsync {
                await asyncAction()
                isFollowed = true
            } label: {
                if isFollowed == true {
                    Text("已关注")
                } else {
                    Text("关注")
                }
            }
            .font(.largeTitle)
            .disabled(isFollowed)
            .buttonStyle(PCustomButtonStyle(backgroundColor: isFollowed == true ? .gray : .pink))
        }
        .padding()
        .background(Color.skeumorphismBG)
        
    }
}

// MARK: - 异步操作的按钮
struct ButtonAsync<Label: View>: View {
    var doAsync: () async -> Void
    @ViewBuilder var label: () -> Label
    @State private var isRunning = false // 避免连续点击造成重复执行事件
    
    var body: some View {
        Button {
            isRunning = true
            Task {
                await doAsync()
                isRunning = false
            }
        } label: {
            label().opacity(isRunning == true ? 0 : 1)
            if isRunning == true {
                ProgressView()
            }
        }
        .disabled(isRunning)

    }
}

// MARK: - 扩展 Button
// 使用 SFSymbol 做图标
extension Button where Label == Image {
    init(systemIconName: String, done: @escaping () -> Void) {
        self.init(action: done) {
            Image(systemName: systemIconName)
                .renderingMode(.original)
        }
    }
}

// MARK: - 自定义 Button
struct PCustomButton: View {
    let desTextView: Text
    let act: () -> Void
    
    init(_ des: LocalizedStringKey, act: @escaping () -> Void) {
        self.desTextView = Text(des)
        self.act = act
    }
    
    var body: some View {
        Button {
            act()
        } label: {
            desTextView.bold()
        }
        .buttonStyle(.starming)
    }
}

extension PCustomButton {
    init(_ desTextView: Text, act: @escaping () -> Void) {
        self.desTextView = desTextView
        self.act = act
    }
}

// 点语法使用自定义样式
extension ButtonStyle where Self == PCustomButtonStyle {
    static var starming: PCustomButtonStyle {
        PCustomButtonStyle(cornerRadius: 15)
    }
}


// MARK: - ButtonStyle
struct PCustomButtonStyle: ButtonStyle {
    var cornerRadius:Double = 10
    var backgroundColor: Color = .pink
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)
                .shadow(color: configuration.isPressed ? .white : .black, radius: 1, x: 0, y: 1)
        )
        .opacity(configuration.isPressed ? 0.5 : 1)
        .scaleEffect(configuration.isPressed ? 0.99 : 1)
        
    }
}

// MARK: - PrimitiveButtonStyle
struct PCustomPrimitiveButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        // 双击触发
        configuration.label
            .onTapGesture(count: 2) {
                configuration.trigger()
            }
        // 手势识别
        Button(configuration)
            .gesture(
                LongPressGesture()
                    .onEnded({ _ in
                        configuration.trigger()
                    })
            )
    }
}

// MARK: - 风格化
struct PStarmingButtonStyle: ButtonStyle {
    var backgroundColor = Color.skeumorphismBG
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .shadow(color: .white, radius: configuration.isPressed ? 7 : 10, x: configuration.isPressed ? -5 : -10, y: configuration.isPressed ? -5 : -10)
                    .shadow(color: .black, radius: configuration.isPressed ? 7 : 10, x: configuration.isPressed ? 5 : 10, y: configuration.isPressed ? 5 : 10)
                    .blendMode(.overlay)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(backgroundColor)
            }
        )
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension Color {
    static let skeumorphismBG = Color(hex: "f0f0f3")
}

extension Color {
    init(hex: String) {
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff)
    }
}
```


#### ProgressView

![](/uploads/develop-with-swiftui/g06.jpeg)

用 ProgressViewStyle 协议，可以创建自定义的进度条视图。在 WatchOS 上会多一个 Guage 视图。

```swift
struct PlayProgressView: View {
    @State private var v: CGFloat = 0.0
    var body: some View {
        VStack {
            // 默认旋转
            ProgressView()
            
            // 有进度条
            ProgressView(value: v / 100)
                .tint(.yellow)
            
            ProgressView(value: v / 100) {
                Image(systemName: "music.note.tv")
            }
            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
            
            // 自定义样式
            ProgressView(value: v / 100)
                .padding(.vertical)
                .progressViewStyle(PCProgressStyle1(borderWidth: 3))
            
            ProgressView(value: v / 100)
                .progressViewStyle(PCProgressStyle2())
                .frame(height:200)
            
            Slider(value: $v, in: 0...100, step: 1)
        }
        .padding(20)
    }
}

// 自定义 Progress 样式
struct PCProgressStyle1: ProgressViewStyle {
    var lg = LinearGradient(colors: [.purple, .black, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
    var borderWidth: Double = 2
    
    func makeBody(configuration: Configuration) -> some View {
        let fc = configuration.fractionCompleted ?? 0
        
        return VStack {
            ZStack(alignment: .topLeading) {
                GeometryReader { g in
                    Rectangle()
                        .fill(lg)
                        .frame(maxWidth: g.size.width * CGFloat(fc))
                }
            }
            .frame(height: 20)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lg, lineWidth: borderWidth)
            )
            // end ZStack
        } // end VStack
    }
}

struct PCProgressStyle2: ProgressViewStyle {
    var lg = LinearGradient(colors: [.orange, .yellow, .green, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    var borderWidth: Double = 20
    
    func makeBody(configuration: Configuration) -> some View {
        let fc = configuration.fractionCompleted ?? 0
        
        func strokeStyle(_ g: GeometryProxy) -> StrokeStyle {
            StrokeStyle(lineWidth: 0.1 * min(g.size.width, g.size.height), lineCap: .round)
        }
        
        return VStack {
            GeometryReader { g in
                ZStack {
                    Group {
                        Circle()
                            .trim(from: 0, to: 1)
                            .stroke(lg, style: strokeStyle(g))
                            .padding(borderWidth)
                            .opacity(0.2)
                        Circle()
                            .trim(from: 0, to: fc)
                            .stroke(lg, style: strokeStyle(g))
                            .padding(borderWidth)
                    }
                    .rotationEffect(.degrees(90 + 360 * 0.5), anchor: .center)
                    .offset(x: 0, y: 0.1 * min(g.size.width, g.size.height))
                }
                
                Text("读取 \(Int(fc * 100)) %")
                    .bold()
                    .font(.headline)
            }
            // end ZStack
        } // end VStack
    }
}
```


#### Image

![](/uploads/develop-with-swiftui/g07.png)

```swift
struct PlayImageView: View {
    var body: some View {
        Image("logo")
            .resizable()
            .frame(width: 100, height: 100)
        
        Image("logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(.cyan, lineWidth: 4)
            )
            .shadow(radius: 10)
        
        // SF Symbols
        Image(systemName: "scissors")
            .imageScale(.large)
            .foregroundColor(.pink)
            .frame(width: 40, height: 40)
        
        // SF Symbols 多色时使用原色
        Image(systemName: "thermometer.sun.fill")
            .renderingMode(.original)
            .imageScale(.large)
    }
}
```


#### ControlGroup

```swift
struct PlayControlGroupView: View {
    var body: some View {
        ControlGroup {
            Button {
                print("plus")
            } label: {
                Image(systemName: "plus")
            }

            Button {
                print("minus")
            } label: {
                Image(systemName: "minus")
            }
        }
        .padding()
        .controlGroupStyle(.automatic) // .automatic 是默认样式，还有 .navigation
    }
}
```


#### GroupBox

![](/uploads/develop-with-swiftui/g08.png)

```swift
struct PlayGroupBoxView: View {
    var body: some View {
        GroupBox {
            Text("这是 GroupBox 的内容")
        } label: {
            Label("标题一", systemImage: "t.square.fill")
        }
        .padding()
        
        GroupBox {
            Text("还是 GroupBox 的内容")
        } label: {
            Label("标题二", systemImage: "t.square.fill")
        }
        .padding()
        .groupBoxStyle(PCGroupBoxStyle())

    }
}

struct PCGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
                .font(.title)
            configuration.content
        }
        .padding()
        .background(.pink)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
```



#### Stack

Stack View 有 VStack、HStack 和 ZStack

![](/uploads/develop-with-swiftui/g09.jpeg)

```swift
struct PlayStackView: View {
    var body: some View {
        // 默认是 VStack 竖排
        
        // 横排
        HStack {
            Text("左")
            Spacer()
            Text("右")
        }
        .padding()
        
        // Z 轴排
        ZStack(alignment: .top) {
            Image("logo")
            Text("戴铭的开发小册子")
                .font(.title)
                .bold()
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 0, y: 2)
                .padding()
        }
        
        Color.cyan
            .cornerRadius(10)
            .frame(width: 100, height: 100)
            .overlay(
                Text("一段文字")
            )
    }
}
```


#### NavigationView

![](/uploads/develop-with-swiftui/g10.jpeg)

对应代码如下：

```swift
struct PlayNavigationView: View {
    let lData = 1...10
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                List(lData, id: \.self) { i in
                    NavigationLink {
                        PNavDetailView(contentStr: "\(i)")
                    } label: {
                        Text("\(i)")
                    }
                }
            }
            
            ZStack {
                LinearGradient(colors: [.mint, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack {
                    Text("一个 NavigationView 的示例")
                        .bold()
                        .font(.largeTitle)
                        .shadow(color: .white, radius: 9, x: 0, y: 0)
                        .scaleEffect(2)
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button("bottom1") {}
                    .font(.headline)
                    Button("bottom2") {}
                    Button("bottom3") {}
                    Spacer()
                }
                .padding(5)
                .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        }
        .foregroundColor(.white)
        .navigationTitle("数字列表")
        .toolbar {
            // placement 共有 keyboard、destructiveAction、cancellationAction、confirmationAction、status、primaryAction、navigation、principal、automatic 这些
            ToolbarItem(placement: .primaryAction) {
                Button("primaryAction") {}
                .background(.ultraThinMaterial)
                .font(.headline)
            }
            // 通过 ToolbarItemGroup 可以简化相同位置 ToolbarItem 的编写。
            ToolbarItemGroup(placement: .navigation) {
                Button("返回") {}
                Button("前进") {}
            }
            PCToolbar(doDestruct: {
                print("删除了")
            }, doCancel: {
                print("取消了")
            }, doConfirm: {
                print("确认了")
            })
            ToolbarItem(placement: .status) {
                Button("status") {}
            }
            ToolbarItem(placement: .principal) {
                Button("principal") {
                    
                }
            }
            ToolbarItem(placement: .keyboard) {
                Button("Touch Bar Button") {}
            }
        } // end toolbar
    }
}

// MARK: - NavigationView 的目的页面
struct PNavDetailView: View {
    @Environment(\.presentationMode) var pMode: Binding<PresentationMode>
    var contentStr: String
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack {
                Text(contentStr)
                Button("返回") {
                    pMode.wrappedValue.dismiss()
                }
            }
        } // end ZStack
    } // end body
}

// MARK: - 自定义 toolbar
// 通过 ToolbarContent 创建可重复使用的 toolbar 组
struct PCToolbar: ToolbarContent {
    let doDestruct: () -> Void
    let doCancel: () -> Void
    let doConfirm: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .destructiveAction) {
            Button("删除", action: doDestruct)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("取消", action: doCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("确定", action: doConfirm)
        }
    }
}
```

toolbar 的位置设置可选项如下：

* primaryAction：放置到最主要位置，macOS 就是放在 toolbar 的最左边
* automatic：根据平台不同放到默认位置
* confirmationAction：一些确定的动作
* cancellationAction：取消动作
* destructiveAction：删除的动作
* status：状态变化，比如检查更新等动作
* navigation：导航动作，比如浏览器的前进后退
* principal：突出的位置，iOS 和 macOS 会出现在中间的位置
* keyboard：macOS 会出现在 Touch Bar 里。iOS 会出现在弹出的虚拟键盘上。


#### List

![](/uploads/develop-with-swiftui/g11.jpeg)

List 除了能够展示数据外，还有下拉刷新、过滤搜索和侧滑 Swipe 动作提供更多 Cell 操作的能力。

通过 List 的可选子项参数提供数据模型的关键路径来制定子项路劲，还可以实现大纲视图，使用 DisclosureGroup 和 OutlineGroup  可以进一步定制大纲视图。

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


#### LazyVStack 和 LazyHStack

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


#### LazyVGrid 和 LazyHGrid

![](/uploads/develop-with-swiftui/g12.jpeg)

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


#### ScrollView

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

#### 浮层

![](/uploads/develop-with-swiftui/g13.png)

浮层有 HUD、ContextMenu、Sheet、Alert、ConfirmationDialog、Popover、ActionSheet 等几种方式。这些方式实现代码如下：

```swift
struct PlaySuperposedLayerView: View {
    @StateObject var hudVM = PHUDVM()
    @State private var isShow = false
    @State private var isShowAlert = false
    @State private var isShowConfirmationDialog = false
    @State private var isShowPopover = false
    
    var body: some View {
        VStack {
            
            
            List {
                ForEach(0..<100) { i in
                    Text("\(i)")
                        .contextMenu {
                            // 在 macOS 上右键会出现的菜单
                            Button {
                                print("\(i) is clicked")
                            } label: {
                                Text("Click \(i)")
                            }
                        }
                }
            }
            .navigationTitle("列表")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button("查看 Sheet") {
                        isShow = true
                    }
                    
                    Button("查看 Alert") {
                        isShowAlert = true
                    }
                    
                    Button("查看 confirmationDialog", role: .destructive) {
                        isShowConfirmationDialog = true
                    }
                    
                    // Popover 样式默认是弹出窗口置于按钮上方，指向底部。
                    Button("查看 Popover") {
                        isShowPopover = true
                    }
                    .popover(isPresented: $isShowPopover, attachmentAnchor: .point(.trailing), arrowEdge: .trailing) {
                        Text("Popover 的内容")
                            .padding()
                    }
                    
                } // end ToolbarItemGroup
            } // end toolbar
            .alert(isPresented: $isShowAlert) {
                Alert(title: Text("弹框标题"), message: Text("弹框内容"))
            }
            .sheet(isPresented: $isShow) {
                print("dismiss")
            } content: {
                VStack {
                    Label("Sheet", systemImage: "brain.head.profile")
                    Button("关闭") {
                        isShow = false
                    }
                }
                .padding(20)
            }
            .confirmationDialog("确定删除？", isPresented: $isShowConfirmationDialog, titleVisibility: .hidden) {
                Button("确定") {
                    // do good thing
                }
                .keyboardShortcut(.defaultAction) // 使用 keyboardShortcut 可以设置成为默认选项样式
                
                Button("不不", role: .cancel) {
                    // good choice
                }
                
            } message: {
                Text("这个东西还有点重要哦")
            }
            
            Button {
                hudVM.show(title: "您有一条新的短消息", systemImage: "ellipsis.bubble")
            } label: {
                Label("查看 HUD", systemImage: "switch.2")
            }
            .padding()
        }
        .environmentObject(hudVM)
        .hud(isShow: $hudVM.isShow) {
            Label(hudVM.title, systemImage: hudVM.systemImage)
        }
    }
}

// MARK: - 供全局使用的 HUD
final class PHUDVM: ObservableObject {
    @Published var isShow: Bool = false
    var title: String = ""
    var systemImage: String = ""
    
    func show(title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
        withAnimation {
            isShow = true
        }
    }
}

// MARK: - 扩展 View 使其能够有 HUD 的能力
extension View {
    func hud<V: View>(
        isShow: Binding<Bool>,
        @ViewBuilder v: () -> V
    ) -> some View {
        ZStack(alignment: .top) {
            self
            
            if isShow.wrappedValue == true {
                PHUD(v: v)
                    .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isShow.wrappedValue = false
                            }
                        }
                    }
                    .zIndex(1)
                    .padding()
            }
        }
    }
}

// MARK: - 自定义 HUD
struct PHUD<V: View>: View {
    @ViewBuilder let v: V
    
    var body: some View {
        v
            .padding()
            .foregroundColor(.black)
            .background(
                Capsule()
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 5)
            )
    }
}
```


#### TabView

```swift
struct PlayTabView: View {
    @State private var selection = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                Text("one")
                    .tabItem {
                        Text("首页")
                            .hidden()
                    }
                    .tag(0)
                Text("two")
                    .tabItem {
                        Text("二栏")
                    }
                    .tag(1)
                Text("three")
                    .tabItem {
                        Text("三栏")
                    }
                    .tag(2)
                Text("four")
                    .tag(3)
                Text("five")
                    .tag(4)
                Text("six")
                    .tag(5)
                Text("seven")
                    .tag(6)
                Text("eight")
                    .tag(7)
                Text("nine")
                    .tag(8)
                Text("ten")
                    .tag(9)
            } // end TabView
            
            
            HStack {
                Button("上一页") {
                    if selection > 0 {
                        selection -= 1
                    }
                }
                .keyboardShortcut(.cancelAction)
                Button("下一页") {
                    if selection < 9 {
                        selection += 1
                    }
                }
                .keyboardShortcut(.defaultAction)
            } // end HStack
            .padding()
        }
    }
}
```

.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) 可以实现 UIPageViewController 的效果，如果要给小白点加上背景，可以多添加一个 .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always)) 修改器。


#### Toggle

![](/uploads/develop-with-swiftui/g14.png)

Toggle 可以设置 toggleStyle，可以自定义样式。使用示例如下

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


#### Picker

![](/uploads/develop-with-swiftui/g15.jpeg)

有 Picker 视图，还有颜色和时间选择的 ColorPicker 和 DatePicker。

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


#### Slider

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


#### Stepper

```swift
struct PlayStepperView: View {
    @State private var count: Int = 0
    var body: some View {
        Stepper(value: $count, step: 2) {
            Text("共\(count)")
        } onEditingChanged: { b in
            print(b)
        } // end Stepper
    }
}
```


#### Keyboard

键盘快捷键的使用方法如下：

```swift
struct PlayKeyboard: View {
    var body: some View {
        Button(systemIconName: "camera.shutter.button") {
            print("按了回车键")
        }
        .keyboardShortcut(.defaultAction) // 回车
        
        Button("ESC", action: {
            print("按了 ESC")
        })
        .keyboardShortcut(.cancelAction) // ESC 键
        
        Button("CMD + p") {
            print("按了 CMD + p")
        }
        .keyboardShortcut("p")
        
        Button("SHIFT + p") {
            print("按了 SHIFT + p")
        }
        .keyboardShortcut("p", modifiers: [.shift])
    }
}
```


### 视觉

#### Color

```swift
struct PlayColor: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Color 也是一个 View
            
            VStack(spacing: 10) {
                Text("这是一个适配了暗黑的文字颜色")
                    .foregroundColor(light: .purple, dark: .pink)
                    .background(Color(nsColor: .quaternaryLabelColor)) // 使用以前 NSColor
                
                Text("自定义颜色")
                    .foregroundColor(Color(red: 0, green: 0, blue: 100))
            }
            .padding()
            
        }
    }
}

// MARK: - 暗黑适配颜色
struct PCColorModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var light: Color
    var dark: Color
    
    private var adaptColor: Color {
        switch colorScheme {
        case .light:
            return light
        case .dark:
            return dark
        @unknown default:
            return light
        }
    }
    
    func body(content: Content) -> some View {
        content.foregroundColor(adaptColor)
    }
}

extension View {
    func foregroundColor(light: Color, dark: Color) -> some View {
        modifier(PCColorModifier(light: light, dark: dark))
    }
}
```


#### Effect

![](/uploads/develop-with-swiftui/g16.jpeg)

```swift
struct PlayEffect: View {
    @State private var isHover = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .black, .pink], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // 材质
                Text("材质效果")
                    .font(.system(size:30))
                    .padding(isHover ? 40 : 30)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onHover { b in
                        withAnimation {
                            isHover = b
                        }
                    }
                
                // 模糊
                Text("模糊效果")
                    .font(.system(size: 30))
                    .padding(30)
                    .background {
                        Color.black.blur(radius: 8, opaque: false)
                    }
                
                // 选择
                Text("3D 旋转")
                    .font(.largeTitle)
                    .rotation3DEffect(Angle(degrees: 45), axis: (x: 0, y: 20, z: 0))
                    .scaleEffect(1.5)
                    .blendMode(.hardLight)
                    .blur(radius: 3)
                
            }
                
        }
    }
}
```

材质厚度从低到高有：

* .regularMaterial
* .thinMaterial
* .ultraThinMaterial
* .thickMaterial
* .ultraThickMaterial


#### Animation

![](/uploads/develop-with-swiftui/g17.jpeg)

SwiftUI 里实现动画的方式包括有 .animation 隐式动画、withAnimation 和 withTransaction 显示动画、matchedGeometryEffect Hero 动画和 TimelineView 等。

示例代码如下：

```swift
struct PlayAnimation: View {
    @State private var isChange = false
    private var anis:[String: Animation] = [
        "p1": .default,
        "p2": .linear(duration: 1),
        "p3": .interpolatingSpring(stiffness: 5, damping: 3),
        "p4": .easeInOut(duration: 1),
        "p5": .easeIn(duration: 1),
        "p6": .easeOut(duration: 1),
        "p7": .interactiveSpring(response: 3, dampingFraction: 2, blendDuration: 1),
        "p8": .spring(),
        "p9": .default.repeatCount(3)
    ]
    @State private var selection = 1
    
    var body: some View {
        // animation 隐式动画和 withAnimation 显示动画
        Text(isChange ? "另一种状态" : "一种状态")
            .font(.headline)
            .padding()
            .animation(.easeInOut, value: isChange) // 受限的隐式动画，只绑定某个值。
            .onTapGesture {
                // 使用 withAnimation 就是显式动画，效果等同 withTransaction(Transaction(animation: .default))
                withAnimation {
                    isChange.toggle()
                }

                // 设置 Transaction。和隐式动画共存时，优先执行 withAnimation 或 Transaction。
                var t = Transaction(animation: .linear(duration: 2))
                t.disablesAnimations = true // 用来禁用隐式动画
                withTransaction(t) {
                    isChange.toggle()
                }
            } // end onHover
        
        LazyVGrid(columns: [GridItem(.adaptive(minimum: isChange ? 60 : 30), spacing: 60)]) {
            ForEach(Array(anis.keys), id: \.self) { s in
                Image(s)
                    .resizable()
                    .scaledToFit()
                    .animation(anis[s], value: isChange)
                    .scaleEffect()
            }
        }
        .padding()
        Button {
            isChange.toggle()
        } label: {
            Image(systemName: isChange ? "pause.fill" : "play.fill")
                .renderingMode(.original)
        }
        
        // matchedGeometryEffect 的使用
        VStack {
            Text("后台")
                .font(.headline)
            placeStayView
            Text("前台")
                .font(.headline)
            placeShowView
        }
        .padding(50)
        
        // 通过使用相同 matchedGeometryEffect 的 id，绑定两个元素变化。
        HStack {
            if isChange {
                Rectangle()
                    .fill(.pink)
                    .matchedGeometryEffect(id: "g1", in: mgeStore)
                    .frame(width: 100, height: 100)
            }
            Spacer()
            Button("转换") {
                withAnimation(.linear(duration: 2.0)) {
                    isChange.toggle()
                }
            }
            Spacer()
            if !isChange {
                Circle()
                    .fill(.orange)
                    .matchedGeometryEffect(id: "g1", in: mgeStore)
                    .frame(width: 70, height: 70)
            }
            HStack {
                Image("p1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                if !isChange {
                    Image("p19")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .matchedGeometryEffect(id: "g1", in: mgeStore)
                }
                Image("p1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
        }
        .padding()
        
        // 使用 isSource，作为移动到相同 matchedGeometryEffect id 的方法。
        HStack {
            Image("p19")
                .resizable()
                .scaledToFit()
                .frame(width: isChange ? 100 : 50, height: isChange ? 100 : 50)
                .matchedGeometryEffect(id: isChange ? "g2" : "", in: mgeStore, isSource: false)
            
            Image("p19")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .matchedGeometryEffect(id: "g2", in: mgeStore)
                .opacity(0)
        }
        
        
        
        // 点击跟随的效果
        HStack {
            ForEach(Array(1...4), id: \.self) { i in
                Image("p\(i)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: i == selection ? 200 : 50)
                    .matchedGeometryEffect(id: "h\(i)", in: mgeStore)
                    .onTapGesture {
                        withAnimation {
                            selection = i
                        }
                    }
                    .shadow(color: .black, radius: 3, x: 2, y: 3)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8).fill(.pink)
                .matchedGeometryEffect(id: "h\(selection)", in: mgeStore, isSource: false)
        )
        
        // matchedGeometryEffect 还可以应用到 List 中，通过 Array enumerated 获得 index 作为 matchedGeometryEffect 的 id。右侧固定按钮可以直接让对应 id 的视图滚动到固定按钮的位置
        
        
        // TimelineView
        TimelineView(.periodic(from: .now, by: 1)) { t in
            Text("\(t.date)")
            HStack(spacing: 20) {
                let e = "p\(Int.random(in: 1...30))"
                Image(e)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .animation(.default.repeatCount(3), value: e)
                
                TimelineSubView(date: t.date) // 需要传入 timeline 的时间给子视图才能够起作用。
                    
            }
            .padding()
        }
        
        // matchedGeometryEffect

        /// TimelineScheduler 的使用，TimelineScheduler 有以下类型
        /// .animation：制定更新的频率，可以控制暂停
        /// .everyMinute：每分钟更新一次
        /// .explicit：所有要更新的放到一个数组里
        /// .periodic：设置开始时间和更新频率
        /// 也可以自定义 TimelineScheduler
        TimelineView(.everySecond) { t in
            let e = "p\(Int.random(in: 1...30))"
            Image(e)
                .resizable()
                .scaledToFit()
                .frame(height: 40)
        }
        
        // 自定义的 TimelineScheduler
        TimelineView(.everyLoop(timeOffsets: [0.2, 0.7, 1, 0.5, 2])) { t in
            TimelineSubView(date: t.date)
        }
    }
    
    // MARK: - TimelineSubView
    struct TimelineSubView: View {
        let date : Date
        @State private var s = "let's go"
        // 顺序从数组中取值，取完再重头开始
        @State private var idx: Int = 1
        func advanceIndex(count: Int) {
            idx = (idx + 1) % count
            if idx == 0 { idx = 1 }
        }
        
        var body: some View {
            HStack(spacing: 20) {
                Image("p\(idx)")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .animation(.easeIn(duration: 1), value: date)
                    .onChange(of: date) { newValue in
                        advanceIndex(count: 30)
                        s = "\(date.hour):\(date.minute):\(date.second)"
                    }
                    .onAppear {
                        advanceIndex(count: 30)
                    }
                    
                Text(s)
            }
        }
    }
    
    // MARK: - 用 matchedGeometryEffect 做动画
    /// matchedGeometryEffect 可以无缝的将一个图像变成另外一个图像。
    @State private var placeStayItems = ["p1", "p2", "p3", "p4"]
    @State private var placeShowItems: [String] = []
    
    @Namespace private var mgeStore
    
    private var placeStayView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 30), spacing: 10)]) {
            ForEach(placeStayItems, id: \.self) { s in
                Image(s)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: s, in: mgeStore)
                    .onTapGesture {
                        withAnimation {
                            placeStayItems.removeAll { $0 == s }
                            placeShowItems.append(s)
                        }
                    }
                    .shadow(color: .black, radius: 2, x: 2, y: 4)
            } // end ForEach
        } // end LazyVGrid
    } // private var placeStayView
    
    private var placeShowView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)]) {
            ForEach(placeShowItems, id: \.self) { s in
                Image(s)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: s, in: mgeStore)
                    .onTapGesture {
                        withAnimation {
                            placeShowItems.removeAll { $0 == s }
                            placeStayItems.append(s)
                        }
                    }
                    .shadow(color: .black, radius: 2, x: 0, y: 2)
                    .shadow(color: .white, radius: 5, x: 0, y: 2)
            } // end ForEach
        } // end LazyVGrid
    } // end private var placeShowView
    
} // end struct PlayAnimation

// MARK: - 扩展 TimelineSchedule
extension TimelineSchedule where Self == PeriodicTimelineSchedule {
    static var everySecond: PeriodicTimelineSchedule {
        get {
            .init(from: .now, by: 1)
        }
    }
}

// MARK: - 自定义一个 TimelineSchedule
// timeOffsets 用完，就会再重头重新再来一遍
struct PCLoopTimelineSchedule: TimelineSchedule {
    let timeOffsets: [TimeInterval]
    
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> Entries {
        Entries(last: startDate, offsets: timeOffsets)
    }
    
    struct Entries: Sequence, IteratorProtocol {
        var last: Date
        let offsets: [TimeInterval]
        var idx: Int = -1
        mutating func next() -> Date? {
            idx = (idx + 1) % offsets.count
            last = last.addingTimeInterval(offsets[idx])
            return last
        }
    } // end Struct Entries
}

// 为自定义的 PCLoopTimelineSchedule 做一个 TimelineSchedule 的扩展函数，方便使用
extension TimelineSchedule where Self == PCLoopTimelineSchedule {
    static func everyLoop(timeOffsets: [TimeInterval]) -> PCLoopTimelineSchedule {
        .init(timeOffsets: timeOffsets)
    }
}
```


#### Canvas

Canvas 可以画路径、图片和文字、Symbols、可变的图形上下文、使用 CoreGraphics 代码和做动画。

图形上下文可以被 addFilter、clip、clipToLayer、concatenate、rotate、scaleBy、translateBy 这些方法来进行改变。

示例代码如下：

```swift
struct PlayCanvas: View {
    let colors: [Color] = [.purple, .blue, .yellow, .pink]
    
    var body: some View {
        
        // 画路径
        PCCanvasPathView(t: .rounded)
        PCCanvasPathView(t: .ellipse)
        PCCanvasPathView(t: .circle)

        // 图片和文字
        PCCanvasImageAndText(text: "Starming", colors: [.purple, .pink])

        // Symbol，在 Canvas 里引用 SwiftUI 视图
        Canvas { c, s in
            let c0 = c.resolveSymbol(id: 0)!
            let c1 = c.resolveSymbol(id: 1)!
            let c2 = c.resolveSymbol(id: 2)!
            let c3 = c.resolveSymbol(id: 3)!

            c.draw(c0, at: .init(x: 10, y: 10), anchor: .topLeading)
            c.draw(c1, at: .init(x: 30, y: 20), anchor: .topLeading)
            c.draw(c2, at: .init(x: 50, y: 30), anchor: .topLeading)
            c.draw(c3, at: .init(x: 70, y: 40), anchor: .topLeading)

        } symbols: {
            ForEach(Array(colors.enumerated()), id: \.0) { i, c in
                Circle()
                    .fill(c)
                    .frame(width: 100, height: 100)
                    .tag(i)
            }
        }

        // Symbol 动画和 SwiftUI 视图一样，不会受影响
        Canvas { c, s in
            let sb = c.resolveSymbol(id: 0)!
            c.draw(sb, at: CGPoint(x: s.width / 2, y: s.height /  2), anchor: .center)

        } symbols: {
            PCForSymbolView()
                .tag(0)
        }
    } // end var body
}

// MARK: - 给 Symbol 用的视图
struct PCForSymbolView: View {
    @State private var change = true
    var body: some View {
        Image(systemName: "star.fill")
            .renderingMode(.original)
            .font(.largeTitle)
            .rotationEffect(.degrees(change ? 0 : 72))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    change.toggle()
                }
            }
    }
}

// MARK: - 图片和文字
struct PCCanvasImageAndText: View {
    let text: String
    let colors: [Color]
    var fontSize: Double = 42
    
    var body: some View {
        Canvas { context, size in
            let midPoint = CGPoint(x: size.width / 2, y: size.height / 2)
            let font = Font.system(size: fontSize)
            var resolved = context.resolve(Text(text).font(font))
            
            let start = CGPoint(x: (size.width - resolved.measure(in: size).width) / 2.0, y: 0)
            let end = CGPoint(x: size.width - start.x, y: 0)
            
            resolved.shading = .linearGradient(Gradient(colors: colors), startPoint: start, endPoint: end)
            context.draw(resolved, at: midPoint, anchor: .center)
            
        }
    }
}

// MARK: - Path
struct PCCanvasPathView: View {
    enum PathType {
        case rounded, ellipse, casual, circle
    }
    let t: PathType
    
    var body: some View {
        Canvas { context, size in
            
            conf(context: &context, size: size, type: t)
        } // end Canvas
    }
    
    func conf( context: inout GraphicsContext, size: CGSize, type: PathType) {
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 25, dy: 25)
        var path = Path()
        switch type {
        case .rounded:
            path = Path(roundedRect: rect, cornerRadius: 35.0)
        case .ellipse:
            let cgPath = CGPath(ellipseIn: rect, transform: nil)
            path = Path(cgPath)
        case .casual:
            path = Path {
                let points: [CGPoint] = [
                    .init(x: 10, y: 10),
                    .init(x: 0, y: 50),
                    .init(x: 100, y: 100),
                    .init(x: 100, y: 0),
                ]
                $0.move(to: .zero)
                $0.addLines(points)
            }
        case .circle:
            path = Circle().path(in: rect)
        }
        
        
        let gradient = Gradient(colors: [.purple, .pink])
        let from = rect.origin
        let to = CGPoint(x: rect.width, y: rect.height + from.y)
        
        // Stroke path
        context.stroke(path, with: .color(.blue), lineWidth: 25)
        context.fill(path, with: .linearGradient(gradient, startPoint: from, endPoint: to))
    }
}
```

























