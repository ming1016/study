---
title: 小册子之 SwiftUI 动画
date: 2024-05-25 19:20:09
tags: [SwiftUI]
categories: App
banner_img: /uploads/pamphlet-series-animation/01.png
---

以下内容已整理到小册子中，小册子代码在 [Github](https://github.com/ming1016/SwiftPamphletApp) 上，本文会随着系统更新和我更多的实践而新增和更新，你可以购买[“戴铭的开发小册子”](https://apps.apple.com/cn/app/%E6%88%B4%E9%93%AD%E7%9A%84%E5%BC%80%E5%8F%91%E5%B0%8F%E5%86%8C%E5%AD%90/id1609702529?mt=12)应用(98元)，来跟踪查看本文内容新增和更新。

本文属于小册子系列中的一篇，已发布系列文章有：

- [小册子之如何使用 SwiftData 开发 SwiftUI 应用](https://starming.com/2024/05/18/pamphlet-series-swiftdata/)
- [小册子之简说 Widget 小组件](https://starming.com/2024/05/18/pamphlet-series-widget/)
- [小册子之 List、Lazy 容器、ScrollView、Grid 和 Table 数据集合 SwiftUI 视图](https://starming.com/2024/05/18/pamphlet-series-listdataview/)
- [小册子之详说 Navigation、ViewThatFits、Layout 协议等布局 SwiftUI 组件](https://starming.com/2024/05/18/pamphlet-series-layout/)
- [小册子之 Form、Picker、Toggle、Slider 和 Stepper 表单相关 SwiftUI 视图](https://starming.com/2024/05/18/pamphlet-series-form/)
- 【本篇】[小册子之 SwiftUI 动画](https://starming.com/2024/05/25/pamphlet-series-animation/)


## SwiftUI动画
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
## contentTransition

`.contentTransition(.numericText())` 修饰符用于在视图内容发生变化时，以数字动画的方式进行过渡。

```swift
struct ContentView: View {
    @State private var filmNumber: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(filmNumber)")
                .contentTransition(.numericText())
                .animation(.easeIn, value: filmNumber)
            Stepper("电影数量", value: $filmNumber, in: 0...100)
        }
        .font(.largeTitle)
        .foregroundColor(.indigo)
    }
}
```
## animation修饰符



### 基本用法

在 SwiftUI 中，创建一个动画需要以下三个组成部分：

- 一个时间曲线函数
- 一个声明将状态（或特定的依赖项）与该时间曲线函数关联起来
- 一个依赖于该状态（或特定的依赖项）的可动画组件

动画的接口定义为 `Animation(timingFunction:property:duration:delay)`

- `timingFunction` 是时间曲线函数，可以是线性、缓动、弹簧等
- `property` 是动画属性，可以是颜色、大小、位置等
- `duration` 是动画持续时间
- `delay` 是动画延迟时间

三种写法

- `withAnimation(_:_:)` 全局应用
- `animation(_:value:)` 应用于 View
- `animation(_:)` 应用于绑定的变量

第一种

```swift
withAnimation(.easeInOut(duration: 1.5).delay(1.0)) {
    myProperty = newValue
}
```

第二种

```swift
View().animation(.easeInOut(duration: 1.5).delay(1.0), value: myProperty)
```

第三种

```swift
struct ContentView: View {
    @State private var scale: CGFloat = 1.0
    var body: some View {
        PosterView(scale: $scale.animation(.linear(duration: 1)))
    }
}

struct PosterView: View {
    @Binding var scale: CGFloat
    var body: some View {
        Image("evermore")
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .onAppear {
                scale = 1.5
            }
    }
}
```

在这个示例中，我们创建了一个 `MovieView`，它有一个状态变量 `scale`。当 `scale` 的值改变时，`PosterView` 中的海报图片会以线性动画的方式进行缩放。当 `PosterView` 出现时，`scale` 的值会改变为 1.5，因此海报图片会以线性动画的方式放大到 1.5 倍。

在 SwiftUI 中，我们也可以创建一个自定义的 `AnimatableModifier` 来实现对图文卡片大小的动画处理。

```swift
struct ContentView: View {
    @State private var isSmall = false
    var body: some View {
        VStack {
            Image("evermore")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(.rect(cornerSize: CGSize(width: 16, height: 16)))
            Text("电影标题")
                .font(.title)
                .fontWeight(.bold)
        }
        .animatableCard(size: isSmall ? CGSize(width: 200, height: 300) : CGSize(width: 400, height: 600))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 1)){
                isSmall.toggle()
            }
        }
    }
}

struct AnimatableCardModifier: AnimatableModifier {
    var size: CGSize
    var color: Color = .white
    
    var animatableData: CGSize.AnimatableData {
        get { CGSize.AnimatableData(size.width, size.height) }
        set { size = CGSize(width: newValue.first, height: newValue.second) }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .background(color)
            .cornerRadius(10)
    }
}

extension View {
    func animatableCard(size: CGSize,
                        color: Color = .white) -> some View {
        self.modifier(AnimatableCardModifier(size: size,
                                             color: color))
    }
}
```

SwiftUI 内置了许多动画过渡函数，主要分为四类：

- 时间曲线动画函数
- 弹簧动画函数
- 高阶动画函数
- 自定义动画函数


### 时间曲线动画函数

时间曲线函数决定了动画的速度如何随时间变化，这对于动画的自然感觉非常重要。

SwiftUI 提供了以下几种预设的时间曲线函数：

- `linear`：线性动画，动画速度始终保持不变。
- `easeIn`：动画开始时速度较慢，然后逐渐加速。
- `easeOut`：动画开始时速度较快，然后逐渐减速。
- `easeInOut`：动画开始和结束时速度较慢，中间阶段速度较快。

除此之外，SwiftUI 还提供了 `timingCurve` 函数，可以通过二次曲线或 Bézier 曲线来自定义插值函数，实现更复杂的动画效果。

以下是代码示例：

```swift
struct ContentView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            Text("电影标题")
                .font(.title)
                .padding()
            Image("evermore")
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                scale = 1.5
            }
        }
    }
}
```

在这个示例中，我们创建了一个 `MovieView`，它包含一个电影标题和一个电影海报。当视图出现时，海报的大小会以 `easeInOut` 的方式在 1 秒内放大到 1.5 倍。

### 弹簧动画函数

弹簧动画函数可以模拟物理世界中的弹簧运动，使动画看起来更加自然和生动。

SwiftUI 提供了以下几种预设的弹簧动画函数：

- `smooth`：平滑的弹簧动画，动画速度逐渐减慢，直到停止。
- `snappy`：快速的弹簧动画，动画速度快速减慢，然后停止。
- `bouncy`：弹跳的弹簧动画，动画在结束时会有一些弹跳效果。

除此之外，SwiftUI 还提供了 `spring` 函数，可以自定义弹簧动画的持续时间、弹跳度和混合持续时间，实现更复杂的弹簧动画效果。

以下是代码示例：

```swift
struct ContentView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            Text("电影标题")
                .font(.title)
                .padding()
            Image("evermore")
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 1)) {
                scale = 1.5
            }
        }
    }
}
```

在这个示例中，我们创建了一个 `MovieView`，它包含一个电影标题和一个电影海报。当视图出现时，海报的大小会以自定义的弹簧动画方式在 0.5 秒内放大到 1.5 倍。

### 高阶动画函数

高级动画函数可以在基础动画函数的基础上，添加延迟、重复、翻转和速度等功能，使动画效果更加丰富和复杂。

以下是这些函数的简单介绍：

- `func delay(TimeInterval) -> Animation`：此函数可以使动画在指定的时间间隔后开始。
- `func repeatCount(Int, autoreverses: Bool) -> Animation`：此函数可以使动画重复指定的次数。如果 `autoreverses` 参数为 `true`，则每次重复时动画都会翻转。
- `func repeatForever(autoreverses: Bool) -> Animation`：此函数可以使动画无限次重复。如果 `autoreverses` 参数为 `true`，则每次重复时动画都会翻转。
- `func speed(Double) -> Animation`：此函数可以调整动画的速度，使其比默认速度快或慢。

以下是代码示例：

```swift
struct MovieView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            Text("电影标题")
                .font(.title)
                .padding()
            Image("movie_poster")
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).delay(0.5).repeatCount(3, autoreverses: true).speed(2)) {
                scale = 1.5
            }
        }
    }
}
```

在这个示例中，我们创建了一个 `MovieView`，它包含一个电影标题和一个电影海报。当视图出现时，海报的大小会以 `easeInOut` 的方式在 1 秒内放大到 1.5 倍，然后在 0.5 秒后开始，重复 3 次，每次重复都会翻转，速度是默认速度的 2 倍。

### 自定义动画函数

SwiftUI 可以通过实现 `CustomAnimation` 协议来完全自定义插值算法。

以下是一个简单的 `Linear` 动画函数的实现：

```swift
struct ContentView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            Text("电影标题")
                .font(.title)
                .padding()
            Image("evermore")
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .animation(.myLinear(duration: 1), value: scale) // use myLinear animation
        }
        .onAppear {
            scale = 1.5
        }
    }
}


struct MyLinearAnimation: CustomAnimation {
  var duration: TimeInterval

  func animate<V>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic {
    if time <= duration {
      value.scaled(by: time / duration)
    } else {
      nil
    }
  }

  func velocity<V: VectorArithmetic>(
    value: V, time: TimeInterval, context: AnimationContext<V>
  ) -> V? {
    value.scaled(by: 1.0 / duration)
  }

  func shouldMerge<V>(previous: Animation, value: V, time: TimeInterval, context: inout AnimationContext<V>) -> Bool where V : VectorArithmetic {
    true
  }
}

extension Animation {
  public static func myLinear(duration: TimeInterval) -> Animation { // define function like linear
    return Animation(MyLinearAnimation(duration: duration))
  }
}
```



## Transaction

### Transaction 使用指南

这段内容主要介绍了 SwiftUI 中的 `Transaction` 和 `withTransaction`。`Transaction` 是 SwiftUI 中用于控制动画的一种方式，它可以用来定义动画的详细参数，如动画类型、持续时间等。`withTransaction` 是一个函数，它接受一个 `Transaction` 实例和一个闭包作为参数，闭包中的代码将在这个 `Transaction` 的上下文中执行。

以下是一个使用 `Transaction` 和 `withTransaction` 的代码示例：

```swift
struct ContentView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            Text("电影标题")
                .font(.title)
                .padding()
            Image("evermore")
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
        }
        .onAppear {
            let transaction = Transaction(animation: .easeInOut(duration: 1))
            withTransaction(transaction) {
                scale = 1.5
            }
        }
    }
}
```

在这个示例中，我们创建了一个 `MovieView`，它包含一个电影标题和一个电影海报。当视图出现时，我们创建了一个 `Transaction`，并设置了动画类型为 `easeInOut`，持续时间为 1 秒。然后我们在 `withTransaction` 的闭包中改变 `scale` 的值，这样海报的大小就会以 `easeInOut` 的方式在 1 秒内放大到 1.5 倍。

### 使用 `Transaction` 和 `withTransaction`

SwiftUI 中 `Transaction` 的 `disablesAnimations` 和 `isContinuous` 属性，以及 `transaction(_:)` 方法怎么使用？

`disablesAnimations` 属性可以用来禁止动画，`isContinuous` 属性可以用来标识一个连续的交互（例如拖动）。`transaction(_:)` 方法可以用来创建一个新的 `Transaction` 并在其闭包中设置动画参数。

以下是一个使用这些特性的代码示例：

```swift
struct ContentView: View {
    @State var size: CGFloat = 100
    @GestureState var dragSize: CGSize = .zero

    var body: some View {
        VStack {
            Image("fearless")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size) // 使用 size 控制尺寸，而非位置
                .animation(.spring(), value: size) // 使用弹簧动画
                .transaction {
                    if $0.isContinuous {
                        $0.animation = nil // 拖动时，不设置动画
                    } else {
                        $0.animation = .spring() // 使用弹簧动画
                    }
                }
                .gesture(
                    DragGesture()
                        .updating($dragSize, body: { current, state, transaction in
                            state = .init(width: current.translation.width, height: current.translation.height)
                            transaction.isContinuous = true // 拖动时，设置标识
                        })
                )

            Stepper("尺寸: \(size)", value: $size, in: 50...200) // 使用 Stepper 替代 Slider
            Button("开始动画") {
                var transaction = Transaction()
                if size < 150 { transaction.disablesAnimations = true }
                withTransaction(transaction) {
                    size = 50
                }
            }
        }
    }
}
```

在这个示例中，当 `size` 小于 150 时，我们禁用动画。通过 `.isContinuous` 属性，我们可以标识一个连续的交互（例如拖动）。在这个示例中，当拖动时，我们禁用动画。通过 `transaction(_:)` 方法，我们可以创建一个新的 `Transaction` 并在其中设置动画参数。

### 用于视图组件

大部分 SwiftUI 视图组件都有 `transaction(_:)` 方法，可以用来设置动画参数。比如 NavigationStack, Sheet, Alert 等。

`Transaction` 也可以用于 `Binding` 和 `FetchRequest`。

看下面的例子：

```swift
struct ContentView: View {
    @State var size: CGFloat = 100
    @State var isBold: Bool = false
    let animation: Animation? = .spring

    var sizeBinding: Binding<CGFloat> {
        let transaction = Transaction(animation: animation)
        return $size.transaction(transaction)
    }

    var isBoldBinding: Binding<Bool> {
        let transaction = Transaction(animation: animation)
        return $isBold.transaction(transaction)
    }

    var body: some View {
        VStack {
            Image(systemName: "film")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size) // 使用 size 控制尺寸，而非位置
                .font(.system(size: size, weight: isBold ? .bold : .regular)) // 使用 isBold 控制粗细
            Stepper("尺寸: \(size)", value: sizeBinding, in: 50...200)
            Toggle("粗细", isOn: isBoldBinding)
        }
        .padding()
    }
}
```

### 传播行为

`Transaction` 可以用于控制动画的传播行为。在 SwiftUI 中，动画可以在视图层次结构中传播，这意味着一个视图的动画效果可能会影响到其子视图。`Transaction` 可以用来控制动画的传播行为，例如禁用动画、设置动画类型等。

以下是一个使用 `Transaction` 控制动画传播行为的代码示例：

```swift
enum BookStatus {
    case small, medium, large, extraLarge
}

extension View {
    @ViewBuilder func debugAnimation() -> some View {
        transaction {
            debugPrint($0.animation ?? "")
        }
    }
}

struct ContentView: View {
    @State var status: BookStatus = .small

    var animation: Animation? {
        switch status {
        case .small:
            return .linear
        case .medium:
            return .easeIn
        case .large:
            return .easeOut
        case .extraLarge:
            return .spring()
        }
    }

    var size: CGFloat {
        switch status {
        case .small:
            return 100
        case .medium:
            return 200
        case .large:
            return 300
        case .extraLarge:
            return 400
        }
    }

    var body: some View {
        VStack {
            Image(systemName: "book")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .debugAnimation() // 查看动画变化信息
            Button("改变状态") {
                var transaction = Transaction(animation: animation)
                withTransaction(transaction) {
                    switch self.status {
                    case .small:
                        self.status = .medium
                    case .medium:
                        self.status = .large
                    case .large:
                        self.status = .extraLarge
                    case .extraLarge:
                        self.status = .small
                    }
                }
            }
        }
    }
}
```

这个示例中，我们创建了一个 `BookView`，它包含一个书籍图标。我们通过 `BookStatus` 枚举来控制书籍的大小，通过 `animation` 计算属性来根据状态返回不同的动画类型。在 `withTransaction` 中，我们根据状态创建一个新的 `Transaction`，并在其中设置动画类型。通过 `debugAnimation` 修饰符，我们可以查看动画的变化信息。

### TransactionKey

TransactionKey 是一种在 SwiftUI 的视图更新过程中传递额外信息的机制，它可以让你在不同的视图和视图更新之间共享数据。

```swift
struct ContentView: View {
    @State private var store = MovieStore()
    var body: some View {
        VStack {
            Image("evermore")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .saturation(store.isPlaying ? 1 : 0) // 滤镜变化
                .transaction {
                    $0.animation = $0[StatusKey.self].animation
                }

            PlayView(store: store)
            PauseView(store: store)
        }
    }
}

struct PlayView: View {
    let store: MovieStore
    var body: some View {
        Button("播放") {
            withTransaction(\.status, .playing) {
                store.isPlaying.toggle()
            }
        }
    }
}

struct PauseView: View {
    let store: MovieStore
    var body: some View {
        Button("暂停") {
            withTransaction(\.status, .paused) {
                store.isPlaying.toggle()
            }
        }
    }
}

@Observable
class MovieStore {
    var isPlaying = false
}

enum MovieStatus {
    case playing
    case paused
    case stopped

    var animation: Animation? {
        switch self {
        case .playing:
            Animation.linear(duration: 2)
        case .paused:
            nil
        case .stopped:
            Animation.easeInOut(duration: 1)
        }
    }
}

struct StatusKey: TransactionKey {
    static var defaultValue: MovieStatus = .stopped
}

extension Transaction {
    var status: MovieStatus {
        get { self[StatusKey.self] }
        set { self[StatusKey.self] = newValue }
    }
}
```

以上代码中，我们创建了一个 `MovieStore` 类，用于存储电影播放状态。我们通过 `PlayView` 和 `PauseView` 分别创建了播放和暂停按钮，点击按钮时，我们通过 `withTransaction` 函数改变了 `MovieStore` 的 `isPlaying` 属性，并根据状态设置了动画类型。在 `ContentView` 中，我们通过 `transaction` 修饰符设置了动画类型为 `MovieStatus` 中的动画类型。

### AnyTransition

`AnyTransition` 是一个用于创建自定义过渡效果的类型，它可以让你定义视图之间的过渡动画。你可以使用 `AnyTransition` 的 `modifier` 方法将自定义过渡效果应用到视图上。

```swift
struct ContentView: View {
    
    @StateObject var musicViewModel = MusicViewModel()
    
    var body: some View {
        VStack {
            ForEach(musicViewModel.musicNames, id: \.description) { musicName in
                if musicName == musicViewModel.currentMusic {
                    Image(musicName)
                        .resizable()
                        .frame(width: 250, height: 250)
                        .ignoresSafeArea()
                        .transition(.glitch.combined(with: .opacity))
                }
            }
            
            Button("Next Music") {
                musicViewModel.selectNextMusic()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct MyTransition: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(active ? .degrees(Double.random(in: -10...10)) : .zero)
            .offset(x: active ? CGFloat.random(in: -10...10) : 0, y: active ? CGFloat.random(in: -10...10) : 0)
    }
}

extension AnyTransition {
    static var glitch: AnyTransition {
        AnyTransition.modifier(
            active: MyTransition(active: true),
            identity: MyTransition(active: false)
        )
    }
}

class MusicViewModel: ObservableObject {
    @Published var currentMusic = ""
    
    let musicNames = ["fearless", "evermore", "red", "speaknow", "lover"]
    
    init() {
        currentMusic = musicNames.first ?? "fearless"
    }
    
    func selectNextMusic() {
        guard let currentIndex = musicNames.firstIndex(of: currentMusic) else {
            return
        }
        
        let nextIndex = currentIndex + 1 < musicNames.count ? currentIndex + 1 : 0
        
        withAnimation(.easeInOut(duration: 2)) {
            currentMusic = musicNames[nextIndex]
        }
    }
}
```

以上代码中，我们创建了一个 `MusicViewModel` 类，用于存储音乐播放状态。我们通过 `MyTransition` 自定义了一个过渡效果，通过 `AnyTransition` 的 `modifier` 方法将自定义过渡效果应用到视图上。在 `ContentView` 中，我们通过 `transition` 修饰符设置了过渡效果为 `glitch`，并在点击按钮时切换音乐。
## Matched Geometry Effect

### 位置变化

Matched Geometry Effect 是一种特殊的动画效果。当你有两个视图，并且你想在一个视图消失，另一个视图出现时，创建一个平滑的过渡动画，你就可以使用这个效果。你只需要给这两个视图添加同样的标识符和命名空间，然后当你删除一个视图并添加另一个视图时，就会自动创建一个动画，让一个视图看起来像是滑动到另一个视图的位置。

示例代码如下：

```swift
struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    @Namespace var musicSelectionNamespace
    var body: some View {
        VStack {
            HStack {
                ForEach(viewModel.topMusic) { item in
                    Button(action: { viewModel.selectTopMusic(item) }) {
                        ZStack {
                            Image(item.name)
                                .resizable()
                                .frame(width: 60, height: 60)
                            Text(item.name)
                                .fontDesign(.rounded)
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                        }
                    }
                    .matchedGeometryEffect(id: item.id, in: musicSelectionNamespace)
                }
            }
            .frame(minHeight: 150)
            Spacer()
                .frame(height: 250)
            HStack {
                ForEach(viewModel.bottomMusic) { item in
                    Button(action: { viewModel.selectBottomMusic(item) }) {
                        ZStack {
                            Image(item.name)
                                .resizable()
                                .frame(width: 90, height: 90)
                            Text(item.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                        }
                    }
                    .matchedGeometryEffect(id: item.id, in: musicSelectionNamespace)
                }
            }
            .frame(minHeight: 150)
        }
    }
}
```

以上代码中，我们创建了一个 `ContentView` 视图，其中包含两个 `HStack` 视图，分别展示了 `viewModel` 中的 `topMusic` 和 `bottomMusic` 数组。我们为每个 `topMusic` 和 `bottomMusic` 元素创建了一个 `Button` 视图，当用户点击按钮时，会调用 `viewModel` 中的 `selectTopMusic` 和 `selectBottomMusic` 方法。我们使用 `matchedGeometryEffect` 修饰符为每个 `Button` 视图添加了一个标识符，这样当用户点击按钮时，就会自动创建一个动画，让一个视图看起来像是滑动到另一个视图的位置。

### 大小变化

Matched Geometry Effect 在大小和位置上都可以进行动画过渡，这样可以让你创建更加复杂的动画效果。

以下是一个视图大小切换的示例：

```swift
struct ContentView: View {
    @State var isExpanded: Bool = false
    
    private var albumId = "Album"
    
    @Namespace var expansionAnimation
    
    var body: some View {
        VStack {
            albumView(isExpanded: isExpanded)
        }
        .padding()
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
    
    @ViewBuilder
    func albumView(isExpanded: Bool) -> some View {
        let imageSize = isExpanded ? CGSize(width: 300, height: 450) : CGSize(width: 100, height: 150)
        Image(isExpanded ? "evermore" : "fearless")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: imageSize.width, height: imageSize.height)
            .clipped()
            .matchedGeometryEffect(id: albumId, in: expansionAnimation)
            .overlay {
                Text("Taylor Swift")
                    .font(isExpanded ? .largeTitle : .headline)
                    .fontDesign(.monospaced)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
            }
    }
}
```


### 内容位置变化

内容位置变化的动画效果。以下是一个内容位置变化的示例：

```swift
struct ContentView: View {
    @State var show = false
    @Namespace var placeHolder
    @State var albumCoverSize: CGSize = .zero
    @State var songListSize: CGSize = .zero
    var body: some View {
        ZStack {
            VStack {
                Text("Taylor Swift，1989年12月13日出生于美国宾夕法尼亚州，美国乡村音乐、流行音乐女歌手、词曲创作人、演员、慈善家。")
                    .font(.title)
                    .fontDesign(.monospaced)
                    .fontDesign(.rounded)
                    .padding(20)
                Spacer()
            }
            Color.clear
                // AlbumCover placeholder
                .overlay(alignment: .bottom) {
                    Color.clear // AlbumCoverView().opacity(0.01)
                        .frame(height: albumCoverSize.height)
                        .matchedGeometryEffect(id: "bottom", in: placeHolder, anchor: .bottom, isSource: true)
                        .matchedGeometryEffect(id: "top", in: placeHolder, anchor: .top, isSource: true)
                }
                .overlay(
                    AlbumCoverView()
                        .sizeInfo($albumCoverSize)
                        .matchedGeometryEffect(id: "bottom", in: placeHolder, anchor: show ? .bottom : .top, isSource: false)
                )
                .overlay(
                    SongListView()
                        .matchedGeometryEffect(id: "top", in: placeHolder, anchor: show ? .bottom : .top, isSource: false)
                )
                .animation(.default, value: show)
                .ignoresSafeArea()
                .overlayButton(show: $show)
        }
    }
}

struct AlbumCoverView: View {
    var body: some View {
        Image("evermore")
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}

struct SongListView: View {
    var body: some View {
        List {
            Text("Fearless")
            Text("Speak Now")
            Text("Red")
            // ...
        }
    }
}

extension View {
    func overlayButton(show: Binding<Bool>) -> some View {
        self.overlay(
            Button(action: {
                withAnimation {
                    show.wrappedValue.toggle()
                }
            }) {
                Image(systemName: "arrow.up.arrow.down.square")
                    .font(.largeTitle)
                    .padding()
                    .background(Color.white.opacity(0.75))
                    .clipShape(Circle())
            }
            .padding()
            , alignment: .topTrailing
        )
    }
    
    func sizeInfo(_ size: Binding<CGSize>) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { size.wrappedValue = $0 }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
```

我们使用 `matchedGeometryEffect` 修饰符为 `AlbumCoverView` 和 `SongListView` 添加了一个标识符，这样当用户点击按钮时，就会自动创建一个动画，让 `AlbumCoverView` 和 `SongListView` 看起来像是从一个位置切换到另一个位置。


### 点击显示详细信息

点击显示详细信息的动画效果。

```swift
struct ContentView: View {
    @Namespace var animation
    @State var showDetail = false
        
    var body: some View {
        ZStack {
            if (!showDetail) {
                VStack {
                    Text("Taylor Swift")
                            .matchedGeometryEffect(id: "artist", in: animation)
                            .font(.largeTitle.bold())
                            .foregroundColor(Color.white)
                    
                    Text("美国歌手")
                        .matchedGeometryEffect(id: "description", in: animation)
                        .font(.title3.bold())
                        .foregroundColor(Color.white)


                }
                .padding(30)
                .background(
                    Rectangle().fill(.black.gradient)
                        .matchedGeometryEffect(id: "background", in: animation)

                )
            } else {
                SingerView(animation: animation)

            }
        }
        .onTapGesture {
            withAnimation {
                showDetail.toggle()
            }
        }
    }
}

struct SingerView: View {
    var animation: Namespace.ID

    var body: some View {
        VStack{
            Text("Taylor Swift")
                    .matchedGeometryEffect(id: "artist", in: animation)
                    .font(.largeTitle.bold())
                    .foregroundColor(Color.white)
            
            Text("美国歌手")
                .matchedGeometryEffect(id: "description", in: animation)
                .font(.title3.bold())
                .foregroundColor(Color.white)

            Spacer()
                .frame(height: 30)
            Text("泰勒·阿利森·斯威夫特（Taylor Swift），1989年12月13日出生于美国宾夕法尼亚州，美国乡村音乐、流行音乐女歌手、词曲创作人、演员、慈善家。")
                .font(.subheadline.bold())
                .foregroundColor(Color.white)
            
            Spacer()
                .frame(height: 30)
            Image("evermore")
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerSize: CGSize(width: 16, height: 16)))
            
            Text("Evermore 是 Taylor Swift 的最新专辑，这是她在 2020 年的第二张专辑，也是她的第九张录音室专辑。")
                .font(.subheadline.bold())
                .foregroundColor(Color.white)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.all, 20)
        .background(
            Rectangle().fill(.black.gradient)
                .matchedGeometryEffect(id: "background", in: animation)
                .ignoresSafeArea(.all)
        )
    }
}
```


### 导航动画

以下是一个导航动画的示例：

```swift
struct ContentView: View {
    @Namespace var animation
    @State var selectedManga: String? = nil
        
    var body: some View {
        ZStack {
            if (selectedManga == nil) {
                MangaListView(animation: animation, selectedManga: $selectedManga)

            } else {
                MangaDetailView(selectedManga: $selectedManga, animation: animation)
            }
        }

    }
}

struct MangaDetailView: View {
    @Binding var selectedManga: String?
    var animation: Namespace.ID
    
    var body: some View {
        VStack {
            Text( "\(selectedManga ?? "")")
                    .matchedGeometryEffect(id: "mangaTitle", in: animation)
                    .font(.title3.bold())
                    .foregroundColor(Color.black)
            
            Spacer()
                .frame(height: 50)

            Button(action: {
                withAnimation {
                    selectedManga = nil
                }
            }, label: {
                Text( "返回")
                    .font(.title3.bold())
                    .foregroundColor(Color.black)
            })
            .foregroundColor(Color.red)
            .padding(.all, 8)
            .background(
                RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                    .fill(Color.white.gradient)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.all, 20)
        .background(
            Color(UIColor.systemTeal)
                .matchedGeometryEffect(id: "background", in: animation)
                .ignoresSafeArea(.all)
        )
    }
}


struct MangaListView: View {
    var animation: Namespace.ID
    @Binding var selectedManga: String?

    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    selectedManga = "海贼王"
                }
            }, label: {
                Text( "海贼王")
                    .matchedGeometryEffect(id: "mangaTitle", in: animation)
                    .font(.title3.bold())
                    .foregroundColor(Color.black)
            })
            .foregroundColor(Color.black)
            .padding(.all, 8)
            .background(
                RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                    .fill(Color.teal)
            )
            
            Button(action: {
                withAnimation {
                    selectedManga = "火影忍者"
                }
            }, label: {
                Text( "火影忍者")
                    .font(.title3.bold())
                    .foregroundColor(Color.black)
            })
            .foregroundColor(Color.black)
            .padding(.all, 8)
            .background(
                RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                    .fill(Color.mint)
                    .matchedGeometryEffect(id: "background", in: animation)
            )

            Button(action: {
                withAnimation {
                    selectedManga = "进击的巨人"
                }
            }, label: {
                Text( "进击的巨人")
                    .font(.title3.bold())
                    .foregroundColor(Color.black)
            })
            .foregroundColor(Color.black)
            .padding(.all, 8)
            .background(
                RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                    .fill(Color.orange)
            )

            Button(action: {
                withAnimation {
                    selectedManga = "鬼灭之刃"
                }
            }, label: {
                Text( "鬼灭之刃")
                    .font(.title3.bold())
                    .foregroundColor(Color.black)
            })
            .foregroundColor(Color.black)
            .padding(.all, 8)
            .background(
                RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                    .fill(Color.purple)
            )

            Button(action: {
                withAnimation {
                    selectedManga = "我的英雄学院"
                }
            }, label: {
                Text( "我的英雄学院")
                    .font(.title3.bold())
                    .foregroundColor(Color.black)
            })
            .foregroundColor(Color.black)
            .padding(.all, 8)
            .background(
                RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                    .fill(Color.green)
            )
        }
    }
}

```

### geometryGroup

`.geometryGroup()` 主要用于处理一组视图动画变化时不协调的问题。如果你有一组视图，它们的位置和大小会随着动画变化，你可以使用 `.geometryGroup()` 修饰符来确保它们的位置和大小保持一致。
## PhaseAnimator

PhaseAnimator

以下代码示例演示了如何使用 `PhaseAnimator` 视图修饰符创建一个动画，该动画通过循环遍历所有动画步骤来连续运行。在这个例子中，我们使用 `PhaseAnimator` 来创建一个简单的动画，该动画通过循环遍历所有动画步骤来连续运行。当观测值发生变化时，动画会触发一次。

```swift
enum AlbumAnimationPhase: String, CaseIterable, Comparable {
    case evermore, fearless, folklore, lover, midnights, red, speaknow

    static func < (lhs: AlbumAnimationPhase, rhs: AlbumAnimationPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct ContentView: View {
    @State var animate: Bool = false

    var body: some View {
        ScrollView {
            PhaseAnimator(
                AlbumAnimationPhase.allCases,
                trigger: animate,
                content: { phase in
                    VStack {
                        ForEach(AlbumAnimationPhase.allCases, id: \.self) { album in
                            if phase >= album {
                                VStack {
                                    Image(album.rawValue)
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                    Text(album.rawValue.capitalized)
                                        .font(.title)
                                }
                                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                            }
                        }
                    }
                    .padding()
                }, animation: { phase in
                    .spring(duration: 0.5)
                }
            )
        } // end ScrollView
        Button(action: {
            animate.toggle()
        }, label: {
            Text("开始")
                .font(.largeTitle)
                .bold()
        })
    }
}
```

在上面的代码中，我们首先定义了一个枚举类型 `AlbumAnimationPhase`，用于表示专辑的不同阶段。然后，我们在 `ContentView` 视图中创建了一个 `PhaseAnimator` 视图修饰符，该修饰符接受一个观测值 `trigger`，用于触发动画。在 `content` 闭包中，我们遍历所有专辑，并根据当前阶段 `phase` 来决定是否显示专辑。在 `animation` 闭包中，我们使用 `.spring(duration: 0.5)` 创建了一个弹簧动画效果。   
## KeyframeAnimator

`KeyframeAnimator`是一个在SwiftUI中创建关键帧动画的工具。关键帧动画是一种动画类型，其中定义了动画开始和结束的关键帧，以及可能的一些中间关键帧，然后动画系统会在这些关键帧之间进行插值以创建平滑的动画。

`KeyframeAnimator`接受一个初始值，一个内容闭包，以及一个关键帧闭包。初始值是一个包含了动画所需的所有属性的结构（在这个例子中是`scale`，`rotation`和`offset`）。内容闭包接受一个这样的结构实例，并返回一个视图。这个视图将使用结构中的值进行配置，以便它可以根据这些值进行动画。关键帧闭包接受一个这样的结构实例，并定义了一系列的关键帧轨道。每个轨道都对应于结构中的一个属性，并定义了一系列的关键帧。每个关键帧都定义了一个值和一个时间点，动画系统将在这些关键帧之间进行插值。

此外，SwiftUI提供了四种不同类型的关键帧：`LinearKeyframe`，`SpringKeyframe`，`CubicKeyframe`和`MoveKeyframe`。前三种关键帧使用不同的动画过渡函数进行插值，而`MoveKeyframe`则立即跳转到指定值，无需插值。

`KeyframeAnimator`可以用于创建各种复杂的动画效果，例如根据滚动位置调整关键帧驱动的效果，或者根据时间进行更新。


```swift
struct ContentView: View {
    @State var animationTrigger: Bool = false

    var body: some View {
        VStack {
            KeyframeAnimator(
                initialValue: AnimatedMovie(),
                content: { movie in
                    Image("evermore")
                        .resizable()
                        .frame(width: 100, height: 150)
                        .scaleEffect(movie.scaleRatio)
                        .rotationEffect(movie.rotationAngle)
                        .offset(y: movie.verticalOffset)
                }, keyframes: { movie in
                    KeyframeTrack(\.scaleRatio) {
                        LinearKeyframe(1.0, duration: 0.36)
                        SpringKeyframe(1.5, duration: 0.8, spring: .bouncy)
                        SpringKeyframe(1.0, spring: .bouncy)
                    }

                    KeyframeTrack(\.rotationAngle) {
                        CubicKeyframe(.degrees(-30), duration: 1.0)
                        CubicKeyframe(.zero, duration: 1.0)
                    }

                    KeyframeTrack(\.verticalOffset) {
                        LinearKeyframe(0.0, duration: 0.1)
                        SpringKeyframe(20.0, duration: 0.15, spring: .bouncy)
                        CubicKeyframe(-60.0, duration: 0.2)
                        MoveKeyframe(0.0)
                    }
                }
            )
        }
    }
}

struct AnimatedMovie {
    var scaleRatio: Double = 1
    var rotationAngle = Angle.zero
    var verticalOffset: Double = 0
}
```

以上代码中，我们首先定义了一个`AnimatedMovie`结构，它包含了动画所需的所有属性。然后，我们在`ContentView`视图中创建了一个`KeyframeAnimator`，该修饰符接受一个观测值`animationTrigger`，用于触发动画。在`content`闭包中，我们使用`Image`视图创建了一个电影海报，并根据`AnimatedMovie`结构中的值对其进行配置。在`keyframes`闭包中，我们为每个属性定义了一系列的关键帧轨道。例如，我们为`scaleRatio`属性定义了三个关键帧，分别使用`LinearKeyframe`和`SpringKeyframe`进行插值。我们还为`rotationAngle`和`verticalOffset`属性定义了两个关键帧轨道，分别使用`CubicKeyframe`和`MoveKeyframe`进行插值。


也可以使用 `.keyframeAnimator` 修饰符来创建关键帧动画。以下是一个示例，演示了如何使用 .keyframeAnimator 修饰符创建一个关键帧动画，该动画在用户点击时触发。

```swift
struct ContentView: View {
    @State var animationTrigger: Bool = false
    
    var body: some View {
        Image("evermore")
            .resizable()
            .frame(width: 100, height: 150)
            .scaleEffect(animationTrigger ? 1.5 : 1.0)
            .rotationEffect(animationTrigger ? .degrees(-30) : .zero)
            .offset(y: animationTrigger ? -60.0 : 0.0)
            .keyframeAnimator(initialValue: AnimatedMovie(),
                              trigger: animationTrigger,
                              content: { view, value in
                view
                    .scaleEffect(value.scaleRatio)
                    .rotationEffect(value.rotationAngle)
            },
                              keyframes: { value in
                KeyframeTrack(\.scaleRatio) {
                    LinearKeyframe(1.5, duration: 0.36)
                    SpringKeyframe(1.0, duration: 0.8, spring: .bouncy)
                    SpringKeyframe(1.5, spring: .bouncy)
                }
                
                KeyframeTrack(\.rotationAngle) {
                    CubicKeyframe(.degrees(-30), duration: 1.0)
                    CubicKeyframe(.zero, duration: 1.0)
                }
                
                KeyframeTrack(\.verticalOffset) {
                    LinearKeyframe(-60.0, duration: 0.1)
                    SpringKeyframe(0.0, duration: 0.15, spring: .bouncy)
                    CubicKeyframe(-60.0, duration: 0.2)
                    MoveKeyframe(0.0)
                }
            })
        
            .onTapGesture {
                withAnimation {
                    animationTrigger.toggle()
                }
            }
    }
}

struct AnimatedMovie {
    var scaleRatio: Double = 1
    var rotationAngle = Angle.zero
    var verticalOffset: Double = 0
}
```

在这个例子中，我们创建了一个 `AnimatedMovie` 结构，它包含了动画所需的所有属性。然后，我们在 `ContentView` 视图中创建了一个 `KeyframeAnimator`，该修饰符接受一个观测值 `animationTrigger`，用于触发动画。在 `content` 闭包中，我们使用 `Image` 视图创建了一个电影海报，并根据 `AnimatedMovie` 结构中的值对其进行配置。在 `keyframes` 闭包中，我们为每个属性定义了一系列的关键帧轨道。例如，我们为 `scaleRatio` 属性定义了三个关键帧，分别使用 `LinearKeyframe` 和 `SpringKeyframe` 进行插值。我们还为 `rotationAngle` 和 `verticalOffset` 属性定义了两个关键帧轨道，分别使用 `CubicKeyframe` 和 `MoveKeyframe` 进行插值。
## 布局动画
```swift
import SwiftUI

struct AnimateLayout: View {
 @State var changeLayout: Bool = true
 @Namespace var namespace

 var body: some View {
  VStack(spacing: 30) {
   if changeLayout {
    HStack { items }
   } else {
    VStack { items }
   }
   Button("切换布局") {
    withAnimation { changeLayout.toggle() }
   }
  }
  .padding()
 }

 @ViewBuilder var items: some View {
  Text("one")
   .matchedGeometryEffect(id: "one", in: namespace)
  Text("Two")
   .matchedGeometryEffect(id: "Two", in: namespace)
  Text("Three")
   .matchedGeometryEffect(id: "Three", in: namespace)
 }
}
```

## 动画-例子

动画的例子有很多。准备中... 请期待。

