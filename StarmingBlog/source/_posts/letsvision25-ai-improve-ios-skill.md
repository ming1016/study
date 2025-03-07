---
title: 使用 AI 突破 iOS 开发者能力边界
date: 2025-03-06 14:54:11
tags: [iOS, AI]
categories: AI
banner_img: /uploads/letsvision25-ai-improve-ios-skill/08.jpg
---

![](/uploads/letsvision25-ai-improve-ios-skill/01.jpg)

之前在 KWDC 和 iOS Conf SG 用英文做过[性能优化进化](https://starming.com/2024/10/28/kwdc24-in-seoul/)和[启动优化](https://starming.com/2025/01/21/ios-conf-sg-25-share/)的技术分享。以下是我这次在上海举行的 Let's Vision 25 大会上分享的内容。

## 前言

![](/uploads/letsvision25-ai-improve-ios-skill/02.jpg)

从变形金刚的机械美学启蒙，到用 Objective-C 构建第一个 iOS 应用，每个技术突破都带来新的创作可能。AI带来的变革尤为特殊——它首次实现了"所想即所得"的开发体验。过去需要数周研究的 CoreAnimation 动画，现在通过自然语言描述即可生成基础实现；曾经需要阅读大量 RFC 文档的网络协议，如今通过 AI 助手可以快速理解关键点。

![](/uploads/letsvision25-ai-improve-ios-skill/03.jpg)

根据GitHub官方统计，使用 Copilot 的开发者代码完成速度提升55%，而我的实践数据显示，在SwiftUI动画开发场景中，AI工具可减少70%的 API 查阅时间。

## AI 编程工具

![](/uploads/letsvision25-ai-improve-ios-skill/04.jpg)


| 工具类型 | 我的选择               | 核心优势         | 适用场景   | 候选方案           |
| ---- | ------------------ | ------------ | ------ | -------------- |
| 本地推理 | Ollama+Deepseek-r1 | 32B参数平衡性能/显存 | 代码审查   | LM Studio      |
| 知识管理 | AnythingLLM        | 支持PDF/代码库索引  | 技术文档检索 | OpenWebUI      |
| 云端开发 | Cursor+Claude3.7   | 实时联网/多文件分析   | 全栈调试   | VSCode+Copilot |

推荐在 Xcode 中配置 Copilot 双面板布局：左侧编写业务逻辑，右侧自动生成单元测试用例。对于 CoreData 等 ORM 操作，尝试用"逆向Prompt"技巧：先让AI生成代码，再要求它解释可能出现的问题。

使用本地大模型的好处是可以使用 Swift 项目代码作为训练集，进行模型微调。

## 提示词

![](/uploads/letsvision25-ai-improve-ios-skill/05.jpg)

提示词非常重要，现在推理模型出来后，我觉得最重要的是描述清楚想要得到结果是什么样的。然后再设定好范围和边界。

比如
```
1/ 角色设定
你是有10年经验的CoreAnimation专家，擅长用显式动画优化交互体验

2/ 任务描述
我需要实现类似Apple Music专辑封面的3D翻转效果，要求：
- 使用CATransform3D实现透视投影
- 支持手势控制翻转角度
- 优化iPad多任务场景下的性能

3/ 约束条件
- 目标系统iOS15+
- 避免使用第三方库
- 优先考虑Metal加速方案

4/ 输出格式
分步骤给出实现方案，标记出需要特别注意的点
```

有了工具，了解了提示词，接下来就可以做一些能够开心的事情了。对于我来说提升技能是最能让我开心的事。

## 想提升的技能

![](/uploads/letsvision25-ai-improve-ios-skill/06.jpg)

我感兴趣的事情其实挺多，比如画漫画，做幻灯片，游戏相关的 Blender 、Godot 和 Vision OS。

开发相关的有密码技术、网络技术、编译器和虚机等。

另外开发各类的 APP 技能也是我想要掌握的。比如日历、日记、天气、健康、拍照、漫画阅读器和音视频播放器等等。

当然，我当前眼前最想提升的就是幻灯片的质量，因为我要用它在会上来做分享呀。

## 开发幻灯片 APP 需要什么知识

![](/uploads/letsvision25-ai-improve-ios-skill/07.jpg)


以前我为了能够更好的分享内容，我做了个幻灯片软件。

接下来我想完善这个幻灯片软件，于是我这样问了 AI

```
我想开发一个 PPT 这样的 macOS 应用，这个应用有哪些功能，分别需要什么方面的技术知识
```

AI 的回答分为基础功能、进阶、高级、技术架构、挑战等部分。基础部分主要包括了界面、文档和幻灯片编辑的功能和使用的技术。

进阶里有模板、动画和多媒体的功能和技术。


- 基础功能
   - 界面
      - 功能：窗口、菜单栏、工具栏、幻灯片缩略图、编辑区
      - 技术：Swift/SwiftUI、AppKit、NSWindowController、NSDocument、NSDraggingDestination
   - 文档
      - 功能：新建、打开、保存、自动保存、版本恢复
      - 技术：FileManager、NSSavePanel、NSOpenPanel
   - 幻灯片编辑
      - 功能：添加/删除幻灯片、调整顺序、编辑文本/形状/图片
      - 技术：NSView 或 CALayer 实现画布、NSTextView 或自定义文本渲染、NSBezierPath 或 Core Graphics 进行图形绘制。
- 进阶
   - 模版与主题
      - 功能：预置模板、自定义主题
      - 技术：NSUserDefaults、动态渲染实时应用到幻灯片元素
   - 动画与过渡效果
      - 功能：元素入场动画、幻灯片切换效果
      - 技术：Core Animation、CAAnimation 和 CALayer 实现关键帧动画、时间轴控制
   - 协作
      - 功能：多人实时编辑、版本历史、云端存储
      - 技术：WebSocket、冲突解决（OT）算法、CloudKit、NSUbiquitousKeyValueStore
   - 多媒体支持
      - 功能：插入图片、音频、视频、形状、图标
      - 技术：AVFundation、NSImageView、Core Plot
- 高级
   - 导出和分享
      - 功能：导出 PDF、视频、HTML、图片、Markdown
      - 技术：NSPrintOperation 或 PDFKit，AVAssetWriter 逐帧渲染幻灯片
   - 智能建议
      - 功能：自动排版、配色建议、AI 生成内容
      - 技术：Core ML、NaturalLanguage、LLM
   - 插件系统
      - 功能：第三方插件扩展（图表库、AI 工具）
      - 技术：NSBundle 加载插件、定义插件接口协议
- 技术架构
   - 设计模式：MVVM、响应式编程
   - 数据存储：SwiftData、NSCache 缓存
- 适配 macOS 特性
   - Dark Mode：通过 NSAppearance 适配深色主题
   - 沙盒机制：处理文件访问权限和安全性
- 关键挑战
   - 复杂动画：高性能渲染需要 Metal 或 Core Animation 优化


目前我最希望能够学习到的就是其中的动画部分，因为我希望 PPT 能够通过动画看起来更生动些。

AI 能够解决传统动画开发的一些痛点：

| 功能模块       | 传统开发痛点                 | AI解决方案                          | 效率提升 |
|----------------|------------------------------|-------------------------------------|----------|
| 动画系统       | 关键帧参数调试耗时           | 自然语言转CAKeyframeAnimation代码  | 65%      |
| 布局引擎       | 多设备适配复杂               | 深度学习预测最佳constraint组合      | 80%      |
| 协作同步       | 冲突解决算法实现难度高        | 生成OT算法Swift实现模板             | 70%      |
| 性能优化       | Metal Shader调试困难         | 自动生成性能分析报告及优化建议       | 90%      |

一些操作技巧：
- 逆向工程法：将Keynote动画导出为视频，用Vision框架分析帧差异生成CAAnimation参数
```
Screen Recording → (Vision分析) → CoreAnimation指令集 → (AI转换) → SwiftUI可编辑代码
```

- 提示词演进
   - 初级："如何实现页面翻转动画"
   - 进阶："生成支持手势控制的CATransform3D动画，要求60fps流畅运行"
   - 专家："创建可中断的物理动画系统，模拟纸张的弯曲刚度和空气阻力"
- 调试技巧
   - 在Xcode中配置`CA_DEBUG_TRANSACTIONS`环境变量
   - 使用Instruments的Core Animation分析模板
   - 通过AI解释`CAMediaTimingFunction`的贝塞尔曲线参数

![](/uploads/letsvision25-ai-improve-ios-skill/08.jpg)

## 基础提示词

接下来就看看我是怎么使用 AI 的来学习动画的吧。

![](/uploads/letsvision25-ai-improve-ios-skill/09.png)

我们先看看基础提示词，框定一些基本技术，这里列出是我常用的技术，比如 SwiftUI、Swift Concurrency、SwiftData 和 Observation。

## 动画描述提示词

下面我对我要实现的动画做一个描述，现有幻灯片有个比较大的痛点，就是当我想在幻灯片上指出某个区域时，需要用到银光笔。如果能够直接在幻灯片中实现点击，然后通过一些效果表示点击的地方那不是更好。

于是我做了这样一个描述的提示词。让其在点击拖动时会产生变色的光晕效果，这个光晕会随着时间渐渐消失，可以多点触控，能够有多条轨迹，发光效果使用模糊滤镜实现的，颜色会随时间自动的变化。

![](/uploads/letsvision25-ai-improve-ios-skill/10.png)

代码可以看到颜色随时间变化这个需求主要是通过 truncatingRemainder 这个方法来实现的。使用 Canvas 的上下 addFilter 方法设置模糊效果，然后形状设置成圆形。

![](/uploads/letsvision25-ai-improve-ios-skill/11.png)

![](/uploads/letsvision25-ai-improve-ios-skill/18.jpg)

下一个例子。提示词是点击或拖动会产生随机的形状，这些形状包括圆形、矩形、圆角矩形、胶囊形、椭圆形和三角形，每个形状都有随机的颜色和大小，形状出现时有缩放动画，然后渐渐消失。最多同时显示50个形状，形状之间保持最小间距。

![](/uploads/letsvision25-ai-improve-ios-skill/12.png)

得到了代码。

```swift
ForEach(shapes) { shape in
    // 描边和尺寸设置
    shape.view
        .stroke(shape.color, lineWidth: 2) // 描边样式
        .frame(width: shape.size * shape.scale, height: shape.size * shape.scale) // 动态尺寸
        .position(shape.position)
        .opacity(shape.opacity)
        .animation(.easeOut(duration: animationDuration), value: shape.scale)
}

// 随机图形
static func randomShape() -> some Shape {
    let shapes: [AnyShape] = [
        AnyShape(Circle()), 
        AnyShape(Rectangle()),
        AnyShape(RoundedRectangle(cornerRadius: 25)),
        AnyShape(Capsule()),
        AnyShape(Ellipse()),
        AnyShape(Triangle()) // Added Triangle
    ]
    return shapes.randomElement()!
}

// 三角形状 Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension Color {
    static var random: Color {
        Color(red: .random(in: 0...1),
              green: .random(in: 0...1),
              blue: .random(in: 0...1))
    }
}
```

从代码中可以看出颜色是通过 rgb 三个值随机组合获得的随机颜色，在 randomShape 这个函数中实现了各个形状，基本都是内置的 Shape 形状。

点击运行可以看到效果。

![](/uploads/letsvision25-ai-improve-ios-skill/14.png)

## 从其它语言代码获取提示词

![](/uploads/letsvision25-ai-improve-ios-skill/15.png)

这是一个 Rect 的动画代码，完整代码地址在[这里](https://codepen.io/thebabydino/pen/WNVPdJg)。代码不少，如果对 CSS 动画不熟还挺难看懂，那么我们可以让 AI 帮我们获取这段代码的动画描述，让他通过描述转化成 SwiftUI 动画的提示词。这就是得到的提示词。

![](/uploads/letsvision25-ai-improve-ios-skill/16.png)

可以看到 AI 生成的提示词比我们写的更有条理，他会先说最终的视觉效果是什么样的，然后会对动画的特点做详细的说明，比如是按照什么速度和方向旋转，完成一圈的时间，是否循环。还生成了技术要点，比如环形渐变用 AngularGradient ，边框效果用 mask 和 strokeBorder，blur 效果模拟发光。用 GeometryReader 来确保边框大小。还有布局上一些值的设置。可以说是非常精确和详细了。

通过这些提示词得到的 SwiftUI 代码我们就容易看懂了。比如 GlowingCardBorder 这个边框视图的颜色设置，尺寸的计算等，还有 TimelineView 如何计算时间。

运行这段代码的效果如下图：

![](/uploads/letsvision25-ai-improve-ios-skill/17.png)

我们可以学到 CSS → SwiftUI 转换法则
```swift
protocol AnimationTranspiler {
    func convert(keyframes: CSSKeyframe) -> CAKeyframeAnimation
    func translate(easing: BezierCurve) -> CAMediaTimingFunction
    func adapt(layout: FlexBox) -> SwiftUI Layout
}

// AI生成的转换中间件示例
class CSS2SwiftAITranspiler {
    func parseTransform(transform: String) -> CATransform3D {
        // 使用NLP识别translateX/rotate等操作
        // 生成优化后的CATransform3D链式调用
    }
}
```

![](/uploads/letsvision25-ai-improve-ios-skill/19.jpg)

## 代码复用

![](/uploads/letsvision25-ai-improve-ios-skill/20.png)

这是一个会发光和改变形状的动效，左边是代码，可以看到很多值的设置都是写在各处表达式中的，如果想复用这段动画代码进行一些调整就很费劲。于是我写出这样的提示词。先让他将动画的部分进行复用，实现更多自定义，然后利用提示词再优化下代码。比如减少重复的部分，编写已用接口等。

![](/uploads/letsvision25-ai-improve-ios-skill/21.png)


AI 依据提示会帮着生成一个接口配置结构体，里面可以对动效做详细的设置。比如角的弧度，变换的幅度，颜色和阴影等。还可以对不同参数组合进行配置，方便复用。

![](/uploads/letsvision25-ai-improve-ios-skill/22.png)

这里是一个新的设置，主要是将背景设置为黄色，改变了角的弧度还有阴影部分。拖动的时候会发现，对拖动后的弹性做了些参数调整，弹起来更加流畅些了。

![](/uploads/letsvision25-ai-improve-ios-skill/23.png)

![](/uploads/letsvision25-ai-improve-ios-skill/24.jpg)

## 学习技术

![](/uploads/letsvision25-ai-improve-ios-skill/25.png)

这个效果，可以看到一群散开的小圆，慢慢聚合点缀成文字。

如果我想了解这个动画效果后面的技术，可以这样问 AI。先让他系统性的检查代码中的动画实现，然后说下每个动画的技术。最后说下每个技术的最佳实践。

![](/uploads/letsvision25-ai-improve-ios-skill/26.png)

AI 的回答如下：

```
主要使用了以下几种动画技术：

## **SpriteKit 粒子动画**：
- 使用 `SKShapeNode` 创建粒子节点
- 通过 `SKAction` 实现粒子的移动动画

let move = SKAction.move(to: targetPosition, duration: duration)
let scale = SKAction.scale(to: 1.0, duration: duration)
particle.run(SKAction.group([move, scale]))


## **粒子动画效果**：
- 初始化时粒子随机分布
- 文字组装动画（1.5-3.0秒）
- 触摸爆炸效果（0.3秒）
- 重新组装动画（1.5-2.0秒）

## **SwiftUI 动画**：
- 使用 `withAnimation` 制作按钮滑入动画

withAnimation(.spring(duration: 0.6)) {
    buttonOffset = 0
}


## **核心动画技术**：
- 使用 Core Text (`CTLine`, `CTRun`) 创建文字路径
- 使用 `CGPath` 进行路径采样，确定粒子目标位置

## **动画时序控制**：
- 使用 `DispatchQueue.main.asyncAfter` 控制动画延时
- 设置动画缓动效果：`.easeOut`
- 使用不同的动画持续时间创造自然的视觉效果

这个示例综合运用了 SpriteKit、SwiftUI 和 Core Graphics 的动画能力，创造了一个复杂的交互式文字粒子动画效果。
```

通过 AI 的回答可以看到动画中的粒子节点时使用 SpriteKit 创建的。粒子不同时段的动画的参数也给了出来。还有文字形状使用 Core Text 的 CTLine 和 CTRun 创建的文字路径，用 CGPath 进行了路径的采样确定粒子目标位置。

![](/uploads/letsvision25-ai-improve-ios-skill/28.jpg)

## 从开源库学习

背景的这个颜色会变的效果来自一个开源库，你可以看到颜色的变化的节奏并不死板，而且颜色融合的效果也很好。我们可以通过 AI 来了解背后是怎么做到的。

AI 分析后，会告诉我各个动画的效果是在哪个文件实现的。

![](/uploads/letsvision25-ai-improve-ios-skill/29.png)

我们能够一目了然用了哪些动画，以及是在哪个文件中写的。比如弹性动画效果是在 BlobLayer.swift 里用 CASpringAnimation 创建的，用到了哪些属性。定时器是在 FluidGradientView.swift 里通过 Combine 创建的，触发时机是随机的。

渐变动画是基于 CAGradientLayer 创建的子类 BlobLayer 来创建的径向渐变。

如何使用这个库，也可以让 AI 提供范例，这样应用到自己项目也会很容易。下面就是它提供的使用范例。

![](/uploads/letsvision25-ai-improve-ios-skill/30.png)

可以看到这个库的接口非常清晰，除了基础颜色可以定义外，还能够添加叠加高亮色，其中加白是为了让颜色不要太艳丽，加黄是为了让颜色偏暖些。

## 接口使用

![](/uploads/letsvision25-ai-improve-ios-skill/31.png)

下面我想说说接口的使用，比如 SF Symbol 新增了 symbolEffect 来给 SF Symbol 做动效，第一个是不断的晃动，第二个是给晃动加了延时，第三个是在两个 SF Symbol 切换时加上过渡效果。那么怎么全面掌握 symbolEffect 接口所有动效及用法呢？

我们可以直接这样问 AI。它会整理好所有的基础动画效果。

```
在 SwiftUI 中，`symbolEffect` 修饰符可以为 SF Symbols 添加动画效果。以下是主要的 symbolEffect 类型：

## 基础动画效果:

.symbolEffect(.bounce) // 弹跳
.symbolEffect(.scale) // 缩放
.symbolEffect(.pulse) // 脉冲
.symbolEffect(.wiggle) // 摇摆
.symbolEffect(.appear) // 出现
.symbolEffect(.disappear) // 消失
.symbolEffect(.replace) // 替换


## 变体动画效果:

.symbolEffect(.bounce.up) // 向上弹跳
.symbolEffect(.bounce.down) // 向下弹跳
.symbolEffect(.variableColor) // 变色
.symbolEffect(.iterative) // 迭代动画


## 常用选项设置:

// 重复选项
.symbolEffect(.bounce, options: .repeat(3)) // 重复3次
.symbolEffect(.bounce, options: .repeat(.forever)) // 无限重复
.symbolEffect(.bounce, options: .repeat(.continuous)) // 连续重复

// 速度选项
.symbolEffect(.bounce, options: .speed(2)) // 2倍速


## 组合效果:

// 可以组合多个效果
.symbolEffect(.bounce)
.symbolEffect(.variableColor)


你当前代码中使用的是：

.symbolEffect(.wiggle, options: .repeat(.continuous))

这会让图标持续不断地进行摇摆动画。

注意：某些效果可能需要 iOS 17.0+ 或 macOS 14.0+ 及以上版本才能使用。

结合 transition 来使用


import SwiftUI

struct ContentView: View {
    @State private var isPresented = false

    var body: some View {
        if isPresented {
            Image(systemName: "swift")
                .font(.system(size: 100))
                .transition(.symbolEffect(.appear))
        } else {
            Button("Show symbol", action: { isPresented.toggle() })
        }
    }
}


// contentTransition


import SwiftUI

struct ContentView: View {
    @State private var isPresented = false
    
    var body: some View {
        VStack(spacing: 50){
            Image(systemName: isPresented ? "checkmark.circle.fill" : "faceid")
                .font(.system(size: 100))
                .contentTransition(.symbolEffect(.replace))
            
            Button("Show symbol", action: { isPresented.toggle() })
        }
    }
}

```

会说变体动画有哪些，组合效果，有哪些选项，比如设置重复次数，速度等。最后还会举例怎么使用。

## 修改动画效果

![](/uploads/letsvision25-ai-improve-ios-skill/33.png)

下面我们看看如何通过 AI 来修改动画的效果，左边代码会显示一个火焰的动效，现在我们让颜色有变化。提示词指明增加颜色的随机性，然后让粒子大小也能够有变化。

![](/uploads/letsvision25-ai-improve-ios-skill/34.png)

可以看到右侧火焰的颜色变成随机的来了。

![](/uploads/letsvision25-ai-improve-ios-skill/35.png)

接下来再看看怎么让粒子的轨迹能够有变化，提示 AI 让运动轨迹变成螺旋运动，带些波浪效果，然后让运动的中心点移到画布的中心。

![](/uploads/letsvision25-ai-improve-ios-skill/36.png)

会生成对应的运算表达式。

```swift
// 添加螺旋运动
let spiralRadius = canvasSize.width/3 * (1-time)
let spiralAngle = rotations * time * .pi * 2 + startingRotation

// 添加波浪效果
let waveAmplitude = canvasSize.width/6 * Darwin.sin(time * .pi * 4)

let x = canvasSize.width/2 + Darwin.cos(spiralAngle) * spiralRadius + waveAmplitude
let y = canvasSize.height/2 + Darwin.sin(spiralAngle) * spiralRadius * 0.8

// 使用非线性alpha衰减
let alpha = Darwin.pow(1-time, 1.5)
```

运行后看到粒子的轨迹已经变了。

![](/uploads/letsvision25-ai-improve-ios-skill/38.png)

## 编辑器的开发

接下来我要讲的是这个用来展示代码的编辑器，以前用的三方的，定制起来不方便，还需要考虑升级和兼容问题。

![](/uploads/letsvision25-ai-improve-ios-skill/39.png)

左侧代码是我幻灯片中标题文字动画选择的部分，目前这个编辑器不光可以浏览代码，还能够修改代码，比如更改 animationType 的值，就可以更改文字动画效果。

![](/uploads/letsvision25-ai-improve-ios-skill/40.png)

这个其中一种动画效果，也是我用在提示词上的文字动画。我们用这个编辑器来改改文字内容，文字大小。

那么这个编辑器的提示词是什么呢？我希望这个编辑器是原生的，但是 SwiftUI 的 TextEditor 现在还无法进行深入的定制，我发现很多好的原生编辑器都是使用 AppKit 的控件来做的。所以我希望它是在 SwiftUI 下用 NSViewRepresentable 来包装现有的 AppKit。

功能上我需要的是能够显示语法高亮，而且是多语言的，Swift 语法用来显示开发代码，Markdown 语法用来显示提示词问题和答案之类。高亮逻辑会在文本改变时触发。这样能够保证修改代码后依旧能够正确显示高亮。确保 NSTextView 和 SwiftUI 的数据流能够双向绑定。再让其支持 UndoManager 撤销操作和快捷键，因为代码会经常敲错，需要快速回退。

另外是对语法高亮支持的说明，说明需要支持多语言。支持配色主题等。

最后就是换行到语法格式对应的地方。

![](/uploads/letsvision25-ai-improve-ios-skill/43.jpg)

## 总的来说

这几年用 AI 的工具以来，我最大的感触就是用 AI 去学习喜欢却不擅长的，用 AI 去做必要却枯燥繁琐的。这样就有更多的时间去做很少的事情，因为

只有很少的书值得去读，
很少的作者值得关注，
很少的朋友值得交往，
很少的事情值得投入，
很少的道理值得明白，
很少的资产值得投资，
很少的目标值得追逐。









