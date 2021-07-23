---
title: 我写技术文章的一点心得
date: 2021-07-24 05:52:45
tags: [iOS, Apple, Swift]
categories: Programming
---

## 前言
非常感谢大家抽出生命中宝贵的一段时间来听我接下来的一大段关于写文章那些事的唠叨。写文章的好处看看[《觉醒年代》](https://movie.douban.com/subject/30228394/)就知道了。

这篇文章我不会写一些常说的技巧，比如文章的内容前后要有逻辑关系，内容之间有关联。所讲知识前后的层次要平，不要在某个部分挖掘过深。写作过程中牢牢抓住要表达的内容，不要过于偏离主题。类似这样的技巧不会说。都说一流的人讨论思想、普通人讨论事情、三流的人讨论人，那么为了提高文章高度，除了说些事情，我还打算加些思想的内容。

大家都习惯去阅读他人人生体验来体验不一样的人生，这样的方式和评头论足一样简单舒服，轻松爽快。而主动去对自己思想进行研究和开发，通过写作输出自己独特的经历和思考却是困难且难受的，但这样从0到1和从0到10的创造过程获得的乐趣却是前者的百倍甚至更多，这背后所遵循的原则是怎样的呢？

每个心得都会基于某些原则，以至于思路不会散架，而所有的原则都无法违背物热力学第二定律，也就是熵增定律(强烈建议先看知乎[这篇](https://zhuanlan.zhihu.com/p/72896309)介绍)。就连进化论都是遵循熵增定律。

对于写作的心得我提炼出独特性、真实感、故事性和新意四个点，其中的独特性和新意都是逆着熵增的过程，其过程是非常难受煎熬的，可能做了大量付出也没结果，因为逆熵增是非线性的，无法预测的，只有在偶然的机会才会有开挂的感觉。对于真实感和故事性属于线性积累，和阅读别人的文章一样，是很容易做到的事情，都是熵增过程，有必要，容易看到结果，但会有内耗，如果没有更多独特性的经历来逆熵，可输出的内容会越来越混乱，落后，渐渐无用。因此独特性、真实感、故事性和新意这四个点之间需要平衡与演进，才能够保持进化的活力。

接下来我就详细展开来跟你说说独特性、真实感、故事性和新意四个点，通过我以前写的一些文章来详细说明。如果你还不知道如何下笔，我还会介绍一个容易着手去做记录和分享输出的方法步骤，最后会从头到尾举个例子按照前面介绍的步骤演示如何写完一篇技术文章。特别是那些逆熵的过程，让你能够多些体感。

## 四个点
先分别介绍下这四个点。

### 独特性
独特性也就是自己的经历和体验，这个是独一无二的，文章的内容如果有更多的个人经历，作为读者也就能够体验到更多的生活。

行万里路，多去做不同事情，多尝试不同方法，也就能够获取到更多的经历。独特性是内容中最重要的部分，如果这四点重要性共分十层的话，我认为独特性就可以占到六层。

### 真实感
记得一个美剧编剧分享过他写编剧的经验，其中提到要写的题材，他至少会花上一年以上的时间去收集和整理相关资料。他认为只有把题材相关细节都吃透了，编排到剧里，观众才会感觉更真实，代入感才会强，身同感受才会有共鸣。如果观众感到假，感觉不到用心，那他怎么会去了解你想表达的内容呢。

因此真实感是表达内容的基础，而且是最费时的。相较于独特的个人经历，真实感是需要花费大量时间去调研作者以前不了解的东西。而这个过程也是了解别人经历的过程，可以学习到很多以前不知道的事情。

真实感是对独特性的扩充，是丰富和挖掘沉淀独特性的，可以占到两层，后面的故事性和新意各占一层。

### 故事性
我很喜欢金庸的小说，特别是射雕英雄传、神雕侠侣和倚天屠龙记这三部，起初对金庸其它小说兴趣不大，也可能拍的电视剧不是我的菜。后来抱着爱屋及乌的态度，我尝试着打开笑傲江湖小说的开头开始读，一下子就被吸引进去了。不得不佩服金庸写故事的能力，太强大了。故事一开始制造了一个令人无法解释的案件，你会非常好奇的一直看下去，很想知道到底发生了什么。小说都进行了很长的部分令狐冲才出现，主角出现前还能吸引你看下去，可见金庸讲故事能力有多厉害。

自从迷上金庸的小说后，我也会试着写些小故事，同样我会注重把一些自身独特的经历穿插到写的小故事里，这些故事我发到了我的博客上，有[白龙班](https://ming1016.github.io/2019/06/19/white-dragon-class/)、[十中](https://ming1016.github.io/2016/04/04/tenth-middle-school/)、[白芈](https://ming1016.github.io/2018/01/04/baimi/)和[花野](https://ming1016.github.io/2018/01/04/huaye/)

故事性是一种技巧，是线性的，很容易通过大量积累掌握好，最终是好是差还是强依赖于独特性和真实感。

### 新意
新意这个点非常关键和重要，也是演进的重要因素，你仔细想想看，很多深度高的文章其实底层知识都是差不多的，能够真正有翻天覆地突进的技术演进不会很频繁，而且这些技术往往都在硬件厂商和实验室中产生出来。对于已有底层知识的输出区别只是应用场景和组合运用技巧上有区别，精彩的发掘和效果奇佳的收益也能够获得掌声。因此技术知识和经验输出的形式也非常重要和关键，如果没有新意，大家势必会对那些知识感觉到疲倦，没人看，写作也就没有了动力。

关于新意可以看到淘系公众号最近使用了视频的方式来讲他们的技术，看起来就很有趣。这方面只有你想不到，没有你做不到，打开脑壳，充分发挥想象吧。

新意之所以只占一层，因为新意获得成功的概率较低，是非线性的，因此需要不断去尝试不同的方式。需要依赖天时地利人和以及前三个点都做的足够好了，新意才会取得非常好的效果。

## 我以前的文章
前面讲了四个我觉得写技术文章最重要的点，只是说了下理论上的逻辑，体感还不够强，下面我结合我以前写的文章我们一起来看看这些文章背后那些独特的经历吧。

### A站 的 Swift 实践
《A站 的 Swift 实践》[上](https://mp.weixin.qq.com/s/rUZ8RwhWf4DWAa5YHHynsQ)、[下](https://mp.weixin.qq.com/s/EIPHLdxBMb5MiRDDfxzJtA)，当时发这篇文章时，关于 Swift 实践的文章也有很多，都是各厂自身实践经验，对于独特性这个点，开始想着把 A 站做过的事情说清楚就可以了，但是很多的经验和做的事情和其他厂做的差不多，这样写出来会没有什么特别的，所以需要着重说下做的和别人不一样的事情。A站比较有特色的是文章里提到的A站自研的声明式 UI Ysera 框架，这个是别人没有的，并且由于 Ysera 框架带来了和 SwiftUI 类似的优雅简洁，提升了整体开发的效率和体验。由于 A 站很早就进入了 Swift 开发模式，并且已有将近一半业务使用了 Swift 开发，所以 A 站相较其它厂走得更快些，对于 Swift 新特性运用的也更广，比如对于 Property Wrapper 的广泛应用，使得代码复杂度骤然降低。走得更远还表现在 Module 化上，A 站大半 Pod 都完成了 Module 化，这方面的经验也很多。

有了独特性，为了能够让阅读的人更有体感，需要对一些技术点进行进一步的描述，使得文章一方面能够让自己得到知识的总结沉淀，还能够对他人有用。这篇文章主要是在混编的内在原理上进行了剖析，这比只描述解决混编问题过程要更加通用些，同时也能起到授人以渔的目的。但掌握原理就需要去学习和提炼相关知识，所下的功夫也更大些。另外采用 Swift 的话，还有个绕不过去的担忧点需要面对，这就是 Swift 的动态性，Swift 这方面由于在 Swift 核心团队工作优先级中较低，相较于 OC 要弱和不成熟很多。所以关于动态化就要说清楚，说的全面点，最好是能够自己进行实验去验证，这个过程会往往枯燥漫长，需要较大的热情才能够完成。

关于故事性，故事性往往是用来引入读进去的一种办法，A 站的 Swift 实践这篇文章的开头通过讲述使用 Swift 的必要性、A 站为之付出的努力和收获、Swift 语言的演进的过程的方式尽量避开具体技术描述，而是使用通俗易懂的描述让读的人可以被轻松带入到文章中来。

### 深入剖析Auto Layout，分析iOS各版本新增特性
[《深入剖析Auto Layout，分析iOS各版本新增特性》](https://ming1016.github.io/2015/11/03/deeply-analyse-autolayout/)。写这个文章也是有着一段不同寻常的经历。那时刚到公司，所有布局都还是使用的 frame 方式，而 Auto Layout 苹果公司才推出不久，在另一位跟我一样新进公司熟悉 Auto Layout 同事的怂恿下，我打算在改版需求中使用 Auto Layout 来替换原有布局方式。但在需求开发刚开始时，那位熟悉 Auto Layout 的新同事突然离职了，我感觉失去了援手，但是我认可了这个技术，还是坚持使用它。期间碰到的苦难无数，布局思路带来了很多开发方式的改变，还有动画的结合会出现的各种效果不一致，其间公司老员工还不断劝我还是走老路比较稳妥。改版完后大部分主流程，包括首页发单、等待页、接单进行页都被改造成 Auto Layout。

更困难的事情还在后面呢，测试期间发现在 iOS6 上会出现各种崩溃、页面布局混乱、动画效果不一致等问题，我的 Bug 始终保持在 Bug 列表前十页。改 Bug 那些天，晚上调的眼发疼，深夜想的难入眠。线下 Bug 改完，上线后才是噩梦的开始，当时我们 App 的 iOS6 用户依旧很多，于是很多偶现崩溃被放大了，我的崩溃问题一直排在 Top1，虽然我很快找到了改好的办法，但是对于这几个偶现的问题还需要一个可靠可信服的解释，这样后面才能够让大家放心使用 Auto Layout。还记得当时周末坐在得实大厦窗户边的工位上，在查完和试完所有资料后依然无果时的无力感。本想着改回以前的 frame 布局算了，后又觉不甘。下几个周末跑到各大图书馆查看所有涉有 Auto Layout 的书，也是那个时候了解到了 VFL 语言。皇天不负有心人，WWDC 开始了，其中有个 Session 叫 Mysteries of Auto Layout，分为[上](https://developer.apple.com/videos/play/wwdc2015-218/)、[下](https://developer.apple.com/videos/play/wwdc2015-219/)两个部分，把 Auto Layout 的原理讲得非常透彻了，至此，透过原理我也找到了问题的根因，并把他们记录在了文章中。这部分内容我还在一个沙龙做了分享，下面是当时分享的 Auto Layout 的原理部分的内容：

![](/uploads/my-little-idea-about-writing-technical-article/1.PNG)

完整幻灯片参看[这里](https://ming1016.github.io/2021/07/13/deeply-analyse-autolayout-slides/)。

这些经验的总结在当时是非常新的，因为官方也是刚公布出其内部的原理，没有人能够更早的知道这些信息，估计也很少有人会考究这么多。有了这些由于一直坚持下来去找根因的经历才使得文章有了独特性。

当然，深入剖析 Auto Layout 这篇文章也加了 Auto Layout 的历史、生命周期、VFL 语言的介绍用来丰富内容的广度，以提升真实感，但你会发现独特性在这里显得尤为重要。

另外，在查找崩溃问题根因时，没有放弃，一直坚持的去找答案的过程也让我难忘。经常会听说到要去找自己热爱的事情，遵循自己所想。而实际上是那件热爱的事情是你愿意花很久甚至很多年需要克服痛苦，还能够继续忍耐，能忍他人所不能忍，赢过他人不是靠的热爱和能力，而是在万般艰难，别人都放弃而你坚持下来才赢的。巴菲特21年资产5000亿美元，其中4997亿美元是50岁之后赚到的，如果49岁那年他就不继续做了，那么他就不会有今年这样巨大的财富，就不会显示巨大的复利效应。

后来我还发现，不断坚持的一个窍门就是去庆祝大目标方向上的每个小小的成功，把这个小小的成功当成最后的成就那样去庆祝。

### 制作一个类似苹果VFL(Visual Format Language)的格式化语言来描述类似UIStackView那种布局思路，并解析生成页面
[这篇文章](https://ming1016.github.io/2016/07/21/assembleview/) 诞生的原因是我写了一个视图布局的库 AssembleView，通过这篇文章做了一个记录。这篇的独特性在于文章背后我特殊的经历。首先写 AssembleView 的起因在于之前大半年我使用自动布局写了大量的页面和一些动画，虽然有比系统更加简化的 Masonry 库可以使用，但是对于很早以前写过 H5 页面的我来说无论是从布局思路还有编写体验上，Masonry 依旧差的很远。苹果为自动布局发明的简洁 VFL 语言却没能用在更加先进的 UIStackView 布局思路上，于是在一次中午吃饭散步的过程中，我突然有了把 VFL 语言和 UIStackView 布局结合起来的想法，同时还想好了名字，叫做 AssembleView，也就是组装的视图的意思，心动不如行动，在接下来的一个需求周期中，我就着手一边开发 AssembleView 一边开发需求。每个需求只有一周的开发时间，当时需求只是更新评价的几个小页面部件，但为了将 AssembleView 运用进来，我把整个评价页面和功能进行了重写，包括标签云等复杂布局采用新库的重写。而这样的工作量仅在一周内完成了。

短时间完成 AssembleView 并应用到产品中，得益于 Deadline 的限制，设置时间节点，没有时间节点的目标那就是梦想，有了时间节点会让你保持一段时间专注，在限制的时间里，你没法去把事情做到方方面面都好，因此才会激发你，让你发挥自身的独特性，和别的不同，其实这种独特会让这件事情完成的更有价值。不要试着做最好的，而是力求做与众不同的。与众不同意味着创新，画草图和下笔写稿子都是创造的方式，这些过程不要去做雕琢、检查、取舍、反思这样的事情，而是释放自己的本能，去自由的发挥自己的积累和沉淀。艺术总是来自不完美，始于杂乱。

有了这样非同寻常的经历，使得这篇文章本身独特性的意义更大了。记录并分享，能够获得做着同样事情人的共鸣。

AssembleView 本身就是全新，因此从头到尾都是新意。

当时写这个库也是为了能够提高完成需求和维护需求的时间，有了精力才能够做更有趣有意义的事情嘛。五年后，苹果终于将 VFL 这种 DSL 语言运用 Swift 强大的 ResultBuilder 和不透明类型等特性进行了更好地完善，配合 Property Wrapper 和 Combine 还无缝衔接了先进的数据流架构，推出了 SwiftUI。

### 深入剖析 JavaScriptCore
[《深入剖析 JavaScriptCore》](https://ming1016.github.io/2018/04/21/deeply-analyse-javascriptcore/) 这篇文章要说独特性，那就是对 JavaScript 语言的好奇心。我很早就开始使用 JavaScript 来开发网站，工作和个人网站的前端都是依赖于这门语言，其实知情人都知道，选择 JavaScript 也是没有选择的选择。年轻时只顾着使用技术去做东西，也做了自己觉得非常有趣的程序，满足感十足，现在转向对其背后的机制技术好奇和感兴趣了。还有一个迫使自己去了解 JavaScript 引擎的原因是工作中做动态页面时需要用到对业务逻辑的解释执行处理。为了避免使用中出了问题会一脸懵，深入了解它显得很有必要。

光有想法是没有一点用的，JavaScriptCore 其实非常的庞大且复杂，当时能找到的大部分资料都是 Bridge 和 RN 的运用，好在开源了，了解内部的话还可以拉代码来看。但是直接埋进去看代码，代码量比较大，很容易 miss 掉其精妙之处。好在发现了 JavaScriptCore 项目核心开发者 Filip Pizlo，通过他的[个人网站](http://www.filpizlo.com/)找到了大量 JavaScriptCore 的一手资料，没日没夜的啃内容，同时还试着动手去实现一些技术细节，最终了解和学习了很多解释器、虚机相关知识。获取一样东西带来的满足感是没有获取经验带来的满足感更深刻。我把学到的这些经验都记录在了这篇文章中，这使得文章的独特性更加深刻，真实感达到了满棚。

### 深入剖析 JavaScript 编译器/解释器引擎 QuickJS - 多了解些 JavaScript 语言
对于 JavaScript 引擎，我先前就看了 JavaScriptCore，为啥还要再去看 QuickJS 这个轻量的 JavaScript 引擎呢。写[这篇文章](https://ming1016.github.io/2021/02/21/deeply-analyse-quickjs/)动力主要还是对QuickJS如何使用精简高效的代码实现了那么复杂功能，还有极高的性能。QuickJS 基本是从头看到尾，一点一点的分析，整个过程也都记录了下来。但是我觉得记录源码的分析还不够，虽然这些分析使得文章的真实感很高，前提是读的人也会埋进代码里。为了提高文章的独特性和故事性，我在文章开头加入了一些 JavaScript 的一些背景内容，还有些当年使用前端技术的体会和经验。

只看代码不去修改和调试，往往会很枯燥，我在分析代码前，也写了些和 QuickJS 工程配置 makefile 相关的内容，并以 QuickJS 本身的 makefile 的用法进行举例说明。另外还手把手说明了怎么用 Xcode 来编译安装调试 QuickJS 代码，这些都是比较独特的内容。QuickJS 的核心代码基本都写在一个文件里，阅读分析时需要非常的专注，如果不专注，可能这篇文章也就没法写完。如果你花大量时间在家玩游戏、看电视剧和刷短视频，而不工作，那么就会有危机感和负罪感。但是如果会去工作，但是期间总会找着间隙去做其他事情，刷刷微博，看看朋友圈，瞅瞅新闻什么的，那就不会有负罪感，因为你会觉得你还是在工作着呢。没全力去工作，而在假装工作着，可比完全不工作的危害更大。一心一意的长时间去做工作外的事情，反而能够开眼界扩视野，从而反哺工作，工作的更好更开心。新时代就会有新机会，同时也会有新的要求，比如知识的获取从单一感官方式变成了动态的，多感官的方式。以前只是文字和图片的书和博客，新时代就是视频、直播和播客，新时代你有更多方式出现在大家面前，出现的更多就代表了成功。未来会有更多感官方式，而且更加的智能。获取知识的门槛低了，人群也就更广了，也可以理解为新的机会更大了，保持专注不设限去感受新时代，对自己不断做出新的要求，就会有新的机会。

### 深入剖析 iOS 编译 Clang / LLVM
写[这篇文章](https://ming1016.github.io/2017/03/01/deeply-analyse-llvm/)的原因主要来自在公司做的 App 安装包体积瘦身的事情，经过各种工具使用和分析后，总是找不到突破口。需求还在不断叠加，也没有好的思路。当你遇到困难时，做不成的人才会告诉你你也做不成，如果你真的想做成，有这个理想就要自己去守护他。遇到困难离成功才会更接近。那些困难来自于有限的资源，比如没人、没钱等，但是正是由于这些资源的限制，才会迫使你去创新，你会通过自己的热情还有毅力来寻找独特更有效的方法，所以由于有限资源带来的困难才会让你去突破、思变和进取。

就在百般无奈，各种资源条件受限的情况下。我想着看能不能把需要繁琐手动检查的动作试着写成程序自动完成。于是我用一个周末开发了查找无用方法工具，能够自动查找出工程中没有用到的方法，也兼顾了我们工程的一些运行时调用的方法检查。这样重复繁重的检查工作就变得轻松了很多。

工具开发完后，我发现这工具的实现并无相关成熟理论来进行支持，以后怎么完善和优化这个工具也没有一点思路。为此我还苦恼了蛮久的。

经过一位同事提醒，说大学有门编译原理的课里面就有讲怎么分析代码的，于是我就开始针对性的翻阅相关资料。于是乎，我发现了一片蓝海，这里面涉及到的技术不光是分析代码，还有很多以前不了解的程序怎么跑起来的细节，这里的知识就像可以无限递归的树，能够将你所有时间都吞没。这篇文章我更新添加内容的次数不下十次，每当get到了新的东西都忍不住记录下来。这期间动手去实践一些知识点，也遇到很多问题，解决这些问题的过程，对相关知识理解就更深入了。后来在17年的@Swift 大会上还做了 LLVM 相关内容的分享，下图是其中一张 Slide。

![](/uploads/my-little-idea-about-writing-technical-article/2.png)

完整幻灯片参看[这里](https://ming1016.github.io/2017/05/27/slides-of-learn-what-interesting-things-you-can-do-with-iOS-compilation/)

### 深入剖析 WebKit
为了完成网页到原生代码的转换，我开始学习 Web 的标准，而 WebKit 是苹果公司对 Web 标准实现，V8和 Flutter 渲染技术的源头，WebKit 的学习能够让我更完整的了解网页从请求到布局再到渲染的流程和使用的相关技术。[WebKit的这篇文章](https://ming1016.github.io/2017/10/11/deeply-analyse-webkit/)我罗列了大量的 Web 规范资料，由于 WebKit 非常的庞大，架构也很复杂，文章里对架构也进行了详细的说明，对源码的结构做了详细的说明。全文按照一个页面从请求到最终渲染的流程顺序，依次对其关键环节里对应源代码和原理进行了详细的说明。完成这篇花费时间巨大，代码基本读了个遍。之后我对于前端技术有了更深的理解，特别是页面异步加载的流程和布局原理。

感觉这篇完全靠的是对前端技术的热情完成的。手冢治虫说过，那些投稿的人，都是热爱着漫画，把画出一部作品作为自己生命意义的人。所以他们才能获得成功，成为马拉松里跑到最后的人。热情可以增加25个 IQ 值。如果一个人仿佛开悟了的高僧，失去任何欲求、愿望、不甘、烦恨与伤痛，那么即使他去画漫画，即使基因再好，天赋再高，也只会画成佛教的禅画罢了。在比尔.布莱森在《人体简史》这本书中提到一个镜子相关的实验，实验来自一名防碎眼镜商人，在1980年创办了胚种精选择库（Repository for Germinal Choice），这个精子库只有诺贝尔获奖者和其他杰出知识权威的镜子。他想的是能够提供最好的精子生出天才婴儿，结果是在出生的200名儿童里，没有一个杰出天才，甚至连一个眼镜工程师都没能造出来，可见对做的事情有热情更加重要，而不仅仅只要基因好就行。

### 深入剖析 iOS 性能优化
[性能这篇](https://ming1016.github.io/2017/06/20/deeply-ios-performance-optimization/)最重要的是独特性，开始只是针对日常开发性能需要注意的一些点进行了归纳总结，后来需要对启动项进行分析，于是做了分析的工具，其间我无意多查看了下 thread_basic_info_t 这个结构体里的字段，发现了 cpu_usage，觉得日后必有用，于是留了个心眼。后来负责性能的同学看了我的这篇文章，跑来找我，跟我说 App 连续几个版本都有线上反馈耗电太大，他们自己也很容易复现出来。这几个版本调整了定位频率，排查了各种怀疑的点，电量消耗依然很大。起初我也没有思路，instruments 也看不出问题来，于是我使用分析启动项的方法，查看运行中方法调用次数，排序来看谁调用的频繁，后来发现调用频繁的方法数量太多很难排查定位。

这时先前留意的 cpu_usage 字段起来关键的作用，通过定时刷新获取线程中 CPU 使用情况，连续高使用就揪出详细线程堆栈，后来小范围灰度上线检测，直接定位到了问题的堆栈，很快的解决了这个大难题。而且有了这个手段，后面也有了底气，在遇到问题也不会慌了，而且线下也可以使用这个方法进行压力测试，以免把问题带到了线上。这个方案也更新记录到了文章中，有了这个不寻常的经历，文章也就有了很强的独特性。

### 启动
关于启动我写了两篇文章。第一篇是[《如何对 iOS 启动阶段耗时进行分析》](https://ming1016.github.io/2019/12/07/how-to-analyze-startup-time-cost-in-ios/)，另一篇是[《App 启动提速实践和一些想法》](https://ming1016.github.io/2020/12/18/thinking-in-how-to-speed-up-app/)。说起这两篇的独特性，那绝对是独一无二。我负责的这场血淋淋的战役真可以说是毕生难忘。项目起因不用猜也可以想到，启动速度持续劣化，导致用户体验变差，落后对手一倍，提速困难重重。临危受命，当时想到的只有一个字，那就是干。

开始最难的还是定方向和定策略以及决策。明确了整体的思路，所有任务就开始并行跑起来了。由于项目的重要性不言而喻，因此投入资源巨大，不光是我的人都参与了进来，还有很多其他团队也一起加入。停下所有手上低优事情，握紧拳头全力打赢关键战役。要的就是能够速战速决，一旦拖延，不光是士气没了，结果没达成，还会留下一堆烂摊子难有资源去清理。

由于初期谋划的方案全面、稠密以及有效，多个团队通力合作配合奇佳，使得在三周内超预期达成了目标，不光是领先了对手一倍，还比大部分头部 App 都要快。这三周说长不长，说短也不短，大量的开发、调试、工具设计开发、数据分析、检测和验证工作集中式的进行，对体力和脑力都是极大的挑战，且压力巨大。

第一篇记录了前期的策划内容以及一些提效工具的开发过程。对这三周干的事情进行了沉淀，沉淀的是一次独特的成功经验。第二篇是在一年后写的，更多的是记录了这一年我对启动这件事情的思考，一年时间的经历也很多，还主负责过包体积的项目，所以内容就显得更加丰富了些，有记录些对性能和调试工具的研究。

第二篇文章里我提到我发现了一个宝藏男孩[Michael Eisel](https://eisel.me/)，发现了很多二手资料都是源自他的博客。另外由于这一年也发现了性能防劣化中，自动化分析工具和能力相关技术了解的不够深入。于是专门去探索了下这方面的情况。对于目前为了保持双端一直 libimobiledevice，我发现了 Facebook 专门针对苹果系统开发的 idb，idb 做法明显更聪明些。

这些探究的过程至少是独特的。更独特的地方是文中写的那个A库多线程问题的排查经历。痛苦的经历我已在文中清晰详细的记录了，历时三天三夜，当大家试完所有情况，士气全无时，才柳暗花明又一村。全因苹果的一个 bug。经历这么一遭，对于 GCD 的队列排查定位问题难这点，我看国外对 iOS 并发开发方式吐槽的声音也很大，于是我很想了解多线程问题苹果未来会怎么处理。这就有了文中 Swift 并发提案部分的分析。当时这份提案还未进入正式流程（现在已经在 Swift 5.5正式发布了），未来并不明朗，我也担心会遗漏关键信息，于是对涉及相关的提案都进行了阅读，包括那些提案下所有的评论也都看了。

这两篇文章跨越了整整一年时间，这一年期间我基本没有写其他的文章，但是却沉淀了很多，所以第二篇实际上可写的内容非常多，一口气挑着重点的说了一大篇后，还删减了大量内容。写完第二篇我感觉到化繁为简的巨大好处。自己做的记录、素材和资料往往都是大量的，深究下去都是无穷无尽的感觉。因此需要从中提炼出自己的观点。从那么多内容中提炼出观点是需要足够的休息和放松，让你的潜意识主动来帮助你。这些休息和放松也可以是在日常的行为中，比如洗澡、去超市买东西、骑自行车、走路、锻炼、吃饭和睡觉等，特别是走路和睡觉持续时间长，最容易进入深度思考。不断给自己提问题进而更大量的阅读找答案，思考内在逻辑和联系。发散的找，专注的收敛提取观点，这样的观点是用钱买不到的。

通过大白话讲清楚，分享出去，这样的观点在他人接收时是自然地，意识不到其背后所花的时间和功夫，这就跟优秀的 App 一样，用起来是那么简单有效，丝毫不拖泥带水，用户也意识不到开发 App 所付出的脑动。这种化繁为简的过程也是将无序杂乱的东西清理掉，让你宝贵精炼的思想能够有地方存放。

灌篮高手中流川枫打篮球行云流水，天赋异禀。背后的努力谁又能知晓。我印象最深的一段是樱木花道为了取得晴子芳心，但始终技不如流川枫，总以为是天赋不够。一天晚上樱木花道很晚来到篮球馆，发现流川枫还在苦练，才发现原来白天看起来懒散傲慢的流川枫原来比谁都要刻苦，简单轻松从来都不是廉价的。

对于分享，有智慧的人都懂得给予越多收获越大。友情比金钱价值更高，就好像有一个开电影公司的朋友比拥有一家电影公司要好。分享不是要得到他人的认可，如果你知道这点，你拥有的能量就是无穷的，力量也是无敌的。

## 没怎么写过，那下一步怎么行动
看到这里，你一定会想“看你说了那么多，但我双手放在键盘前，脑袋还是一片空白，无从下手”。

如果想帮其他人，让他真的动手去做些什么事情，其实更应该是要让做这件事情变得容易很多倍，但方向是一样的，这样下次他就更好接受些。互联网开始发布内容门槛高，后来有了微博和朋友圈这种能够一句话就快速发布出去的产品后，大家发内容就比以前更多了。去读资料和文章，可以懂更多的知识，自身能力还是需要通过练习才能够有提升。想把事情做好，还是需要去做。

因此你应该更重视动手写，如果你不知道如何写，可能就不知道如何思考。有叛逆和逆向思维的人常常是爱问问题的人，爱自问爱思考，对那些已经共识正在运作的事物提出疑问，寻找和关注答案，这样才会有打破现状的意识。一些人小时候就能看到有这样的特点，因此在别人教你怎样怎样做时，不要太当回事，相信自己实践出来的答案。多听你喜欢人说话，多倾听，不断问还有没想说的。

还要从各种类型人那学习，甚至是和你观点不同的人。因为在每个人坚持的思想里，都会有他自己独特的经历和实践总结来的结论。通过他们的结论，你也可以自己去实践和验证形成自己的观点，这样就会有复利效应。做的结果其实并不重要，重要的是在做的过程中，你自己有没有变得更好。

你说的话，你的观点，你的评论都不能代表你，而是你所做的事情，花了很多时间做的事情那才是你。改变一个人的行为来改变思维，比改变一个人的思维来改变行为要容易的多很多。

因此，光看光听不动手写是没用的。那行动起来的话，怎么做更好些呢？

### 四个步骤

第一步，零散的想法、工作内容和看到的好的技术资料及时记录，先按照时间轴的方式记录。这一步是很容易操作的，几乎不用费脑，只需要机械的做记录就行，也不用考虑先前提到四个点里任何一个。

第二步，对于记录的内容进行分类，开始粒度可以粗一点，比如性能、架构、构建、编程语言、管理、成长、旅行和科技等，根据自身兴趣点和期望发展方向来就好。

第三步，做完一个项目，或者想对先前做的事情进行总结时，先一口气快速写出想表达的内容出来，这时写的内容体现出独特性，搭好骨架。然后针对写的内容中的一些技术点，进行真实感的完善。真实感的完善是需要很多素材和资料的，这时在第一步和第二步做的工作和积累就能够派上用场了。找到相关大分类进行细分来补充文章的血肉。

第四步，也是最后一步，可以充分发挥自己软实力和创造力，通过故事性和新意来披上文章的皮肤，让文章能够看起来更加完整和吸引人，提高阅读的体验。

完整完成这四个步骤并不容易，经常就会因为惰性半途而废。这时就需要 push 自己一把，方法的话，我这边的经验就是定目标，定时间节点。比如定好一个对外分享的时间，这样目标性更强，同时也有了约束和责任，自己的惰性在这一段时间内就能够得到很好的消减。

为了达成目的，彻底理清你想要啥，还需要清空干扰，方法很简单，除了当前最重要的事情，其它所有待做事情都记在备忘录里以便追踪防止遗漏。完成当前事情后，再去查看备忘录，然后定新目标新计划。

完成文章后可以通过下面八个问题来检查下文章的完成度。
1. 我为什么做这件事？
2. 谁已经做了？他们都是怎么做的？效果怎样？
3. 我和他们做的不一样在哪？怎么想到的？能详细具体说出涉及相关知识点吗？（⭐️重点，写好了的话，其他问题可有可无）
4. 我碰到了什么困难？
5. 我怎么解决的？
6. 做的有亮点吗？为什么是亮点？
7. 做完后效果是怎样的？超预期地方在哪？
8. 以后还有计划打算吗？为什么？

### 所用软件
下面是我写文章会用到的一些软件，以及我关注和用到的一些特性：

系统自带备忘录
* 零散想法和灵感记录
* 待做事项记录（一个一个直接删掉的感觉不错）
* 聚焦想法思路，不用去考虑分类整理等

[熊掌记](https://bear.app/cn/)
* 本地文档管理（多设备同步收费）
* 标签系统简化分类

[Notion](https://www.notion.so/)
* 在线文档管理
* 数据库方式管理，分类、检索和排序
* 字段自定义添加，比如标签、类别、链接、标题等等都可以自定义
* 基于数据库和自定义字段可生成看板、时间轴、日历、列表、表格、网格等不同视图样式查看。
* 有chrome插件

[VS Code](https://code.visualstudio.com/)
* 本地文档管理（文件夹，Git支持可多端同步）
* Markdown 插件支持（Markdown All in One、Pangu-Markdown、Markdown Preview Enhanced、Word Count CJK）

[Obsidian](https://obsidian.md/)
* 本地文档管理（文件夹）
* Markdown原生支持
* 插件系统，比如有大纲和看板等插件可用
* 双向链接与关系图谱

[Procreate](https://procreate.art/cn)
* 可以把在纸上的草图配上颜色

软件使用上，我会通过备忘录或熊掌记快速记录一些素材和想法，定期挪到 Notion 里，我是把 Notion 当做一个大仓库，写作的第二阶段整理分类我就是在 Notion 中完成的，充分利用 Notion 的自定义字段能力，对所有资料进行各种维度划分和归档。开始写文章时，初期会用 VS Code 来写，如果文章写长了就会打开 Obsidian 来继续写，主要是 Obsidian 的大纲效果比较好些。最后文章的配图我会使用 Procreate 来画，里面有辅助线，打开后可以很方便做参照，写图中文字就不容易偏了。

工具只是工具，记录的内容和自己的思想才是核心。我现在读书还是喜欢在纸上写笔记，特别有感触的才会提炼一些观点敲到备忘录中，比如我看了网飞（Nexflix）的[《不拘一格》](https://book.douban.com/subject/35102294/)后提炼了一些观点做了记录，笔记如下：
```bash
制度都是围绕着怎么不阻碍所要的人发挥。比如假期自由安排、无审批、决策权非自上而下，而是在认识一致情况下松散耦合。

要和不要什么样的人呢？

不要的人：

与人相处好，但能力平平
工作狂，缺少判断力
天资好，行动力强，但悲观、牢骚
有才华的混蛋：
特征
听到赞美就自觉优秀
对想法不明智的人，会进行嘲笑
会侮辱天赋不如自己的人
表现
喜欢会上慷慨陈词，重复表达自己观点
如没抓住他的要点，会打断别人的话
别人发言，不赞同时会不听，做自己的事情
别人啰嗦，没抓住要点，立刻打断
总想着怎么做才能表现好，得奖金，缺少开放的认知空间

为什么：管理花费精力多，讨论质量低，会排挤卓越员工。

要的人：

非凡创造力、工作出色（完成繁重任务）、合作好
在放松状态下，会灵光乍现
公司利益至上
自觉追求成功，无论是否有奖金（已给予能力匹配市场最高价）
当某一固定思维遇到瓶颈时，他总有办法摆脱瓶颈，或尝试不同角度看待问题
在有才能，受爱戴的前提下，自己犯错大声说，成功小声说，让人感觉亲近、真诚和体贴。
有良好的判断力

为什么：优秀的人激励其他优秀的人，出色成果感染更多人才。

只有公司里的员工都是上面提到的要的人时，公司的密度才高。这样的公司不是家庭而是专业运动队，运动队追求卓越，每个位置都是最佳人选；训练就是为了胜利，大家都能给予和接受反馈；成绩要好，不能只用努力就够了。

书中详细介绍了网飞的制度由来，大量员工的实际案例，碰到了问题如何完善了制度。非常全面进行了制度介绍，甚至包含了进行创新的几个步骤的详细说明，还有网飞创始人里德是如何做到让大家认识一致的。

最后是书中引用的小王子那段：
如果你想造艘船，
不要老催人去采木，
忙着分配工作
和发号施令。
而是要激起他们
对浩瀚无垠的
大海的向往。
```

## 举个例子，怎么写这次WWDC21的见闻文章
光说不练，这样不好吧，那就现举个例子，看看怎么按照上面的四个步骤一步一步写一篇技术文章。那就以现在刚开完的 WWDC21 为主题，写个《WWDC21我的见闻》吧。

首先我们先做第一步，从 WWDC21 开始，我就将我看到的信息、还有看感兴趣 Session 中有用的点都记录了下来，只考虑是否要记，二不考虑其它任何事情。你可以看我[WWDC21第一天的记录](https://ming1016.github.io/2021/06/08/wwdc2021-day1-note/)，我将其发到了我的博客和公众号上。后面几天我也不断的收集记录着零碎的信息。然后对这些记录进行分类。接下来再开始内容的撰写。

写 WWDC21 见闻录，你可以先想想着你想要什么内容，有没人提供，有的话可以直接链过来，没有的话可以自己去体会，去想，去经历，然后分享出来。

我会先写个总览，内容如下。

### 总览
WWDC21 官方通过一个页面汇总了发布的新技术，详见[这里](https://developer.apple.com/documentation/new-technologies-wwdc21)。WWDC21 里的代码范例官方都有提供和汇总，详见[这里](https://developer.apple.com/sample-code)。WWDC21 期间苹果也[列出了](https://developer.apple.com/wwdc21/beyond-wwdc/)苹果公司之外围绕 WWDC 其它组织的学习、交流和娱乐的活动。

如果没有太多时间看 Session 视频，也可以直接看其他人的笔记，国外有[WWDC NOTES](https://www.wwdcnotes.com/)，国内有老司机技术周刊的[WWDC21 内参](https://xiaozhuanlan.com/wwdc21)。往届内容也有人做了[汇总](https://github.com/Juanpe/About-SwiftUI)

简单笔记可以查缺补漏，Alejandro Martinez 在这篇文章[WWDC21 notes](https://alejandromp.com/blog/wwdc21-notes/)中对各种主题做了简单的记录，列出了关键字方便检索。

### Session推荐
全部 Session，在[这里](https://developer.apple.com/videos/wwdc2021/)查看。这里有份[推荐清单](https://useyourloaf.com/blog/wwdc-2021-viewing-guide/)。我也列了下我关注的 Session。如下：

SwiftUI 相关 Session：
* [What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10018/)：包括了所有SwiftUI这次的更新内容介绍。
* [Add rich graphics to your SwiftUI app](https://developer.apple.com/videos/play/wwdc2021/10021/)：内容包括安全区域、材质包、画布API等。
* [Craft search experiences in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10176/)：.searchable修饰符的使用。
* [Direct and reflect focus in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10023/)：关于移动焦点的使用。
* [SwiftUI on the Mac: Build the fundamentals](https://developer.apple.com/videos/play/wwdc2021/10062/)：内容是一步一步构建一个macOS应用。
* [SwiftUI on the Mac: The finishing touches](https://developer.apple.com/videos/play/wwdc2021/10289/)：展示如何通过设置让人们灵活定制一个应用程序。
* [Demystify SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10022/)：介绍了SwiftUI的三个核心Identity、Lifetime和Dependencies。
* [Discover concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10019/)：展示并发工作流如何和SwiftUI数据流进行结合。
* [SF Symbols in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10349/)：定义Symbols的大小，显示不同变体以及Symbols着色。

Swift Concurrency 相关 Session：
* [Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/)：了解 async/await 开发模式。
* [Explore structured concurrency in Swift](https://developer.apple.com/videos/play/wwdc2021/10134/)：内容包括创建不同类型并发任务，如何创建任务组，如何取消正在进行的任务。
* [Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)：内容有如何使用Swift actors组织资源竞争，actors如何工作等。
* [Swift concurrency: Behind the scenes](https://developer.apple.com/videos/play/wwdc2021/10254/)：了解更多Swift并发的细节，更安全的数据竞争和处理线程爆炸，和GCD的不同，线程模型怎么工作等。值得看多遍。
* [Swift concurrency: Update a sample app](https://developer.apple.com/videos/play/wwdc2021/10194/)：介绍async/await、actors和continuation在现实工作中的经验
* [Meet AsyncSequence](https://developer.apple.com/videos/play/wwdc2021/10058/)：流式传输数据。
* [Use async/await with URLSession](https://developer.apple.com/videos/play/wwdc2021/10095/)：URLSession中怎么使用async/await和AsyncSequence。

DocC：
* [Meet DocC documentation in Xcode](https://developer.apple.com/videos/play/wwdc2021/10166)：了解如何使用DocC，如何生成DocC档案，并让他们显示在文档浏览器中。
* [Host and automate your DocC documentation](https://developer.apple.com/videos/play/wwdc2021/10236)：如何通过自己的服务器托管DocC，自动构建和分发DocC档案。
* [Elevate your DocC documentation in Xcode](https://developer.apple.com/videos/play/wwdc2021/10167)：介绍写文档的最佳实践。
* [Build interactive tutorials using DocC](https://developer.apple.com/videos/play/wwdc2021/10235)：编写交互教程。

其它感兴趣的 Session：
* [Write a DSL in Swift using result builders](https://developer.apple.com/videos/play/wwdc2021/10253/)：使用 result builders 来创建DSL，是代码更容易阅读和维护。
* [Create 3D models with Object Capture](https://developer.apple.com/videos/play/wwdc2021/10076/)：捕获现实对象，生成3D模型。
* [What’s new in SF Symbols](https://developer.apple.com/videos/play/wwdc2021/10097/)：SF Symbols的更新。介绍如何让自定义符号支持单色、分层、调色板和多色渲染模式。
* [Explore the SF Symbols 3 app](https://developer.apple.com/videos/play/wwdc2021/10288/)：SF Symbols应用程序的更新。
* [Create custom symbols](https://developer.apple.com/videos/play/wwdc2021/10250/)：创建自定义symbols。
* [Ultimate application performance survival guide](https://developer.apple.com/videos/play/wwdc2021/10181/)：关于性能优化的话题，内容包括性能相关工具、指标和范式。会涉及到Instruments、XCTest、MetricKit等等技术和工具。iOS 15的动态链接器做了优化能够启动提速并减少Swift二进制大小。可以参看[这篇文章](https://medium.com/geekculture/how-ios-15-makes-your-app-launch-faster-51cf0aa6c520)
* [Symbolication: Beyond the basics](https://developer.apple.com/videos/play/wwdc2021/10211/)：介绍符号化的过程。
* [Meet the Swift Algorithms and Collections packages](https://developer.apple.com/videos/play/wwdc2021/10256/)：讲的通俗易懂。

### Swift 的一些更新
Paul Hudson 的这篇[What's new in Swift 5.5?](https://www.hackingwithswift.com/articles/233/whats-new-in-swift-5-5) 已经把这些更新说的非常详细了，每个更新点都有对应的例子可以试。今年苹果公司推出 AttributedString 用来替代 OC 时代的 NSAttributedString。AttributedString 是值类型，可以直接在 SwiftUI 的 Text 里使用。AttributedString 还支持简单的 Markdown 语法，Markdown 单行没问题，多行功能受限。

DocC 是通过 Xcode 编译后生成的文档，使用 Product -> Build Documentation 就会生成DocC。在函数接口代码上使用 Shift+Cmd+A 快捷键就会创建文档模板，有参数和返回值的话也会将其提取出来，包括参数类型等，并生成标准文档格式，方便你进行内容编写。基本 Markdown 语法是支持的。详细的介绍可以看前面列出的官方 Session，或者看这篇文章[How to document your project with DocC](https://www.hackingwithswift.com/articles/238/how-to-document-your-project-with-docc)。

### 今年重头戏 Swift Concurrency
ABI 稳定后，Swift 的核心团队可以开始关注 Swift 语言一直缺失的原生并发能力了。最初是由[Chris Lattner](https://twitter.com/clattner_llvm)在17年发的[Swift并发宣言](https://gist.github.com/lattner/31ed37682ef1576b16bca1432ea9f782)，从此开阔了大家的眼界。后来 Swift Evolution 社区讨论了十几个提案，几十个方案，以及几百页的设计文件，做了大量的改进，社区中用户积极的参与反馈，Chris 也一直在 Evolution 中积极的参与设计。

Swift Concurrency 的实现用了[LLVM的协程](https://llvm.org/docs/Coroutines.html)把 async/await 函数转换为基于回调的代码，这个过程发生在编译后期，这个阶段你的代码都没法辨识了。异步的函数被实现为 coroutines，在每次异步调用时，函数被分割成可调用的函数部分和后面恢复的部分。coroutine 拆分的过程发生在生成LLVM IR阶段。Swift使用了哪些带有自定义调用约定的函数保证尾部调用，并专门为Swift进行了调整。

Swift Concurrency 不是建立在 GCD 上，而是使用的一个全新的线程池。GCD 中启动队列工作会很快在提起线程，一个队列阻塞了线程，就会生成一个新线程。基于这种机制 GCD 线程数很容易比 CPU 核心数量多，线程多了，线程就会有大量的调度开销，大量的上下文切换，会使 CPU 运行效率降低。而 Swift Concurrency 的线程数量不会超过 CPU 内核，将上下文切换放到同一个线程中去做。为了实现线程不被阻塞，需要通过语言特性来做。做法是，每个线程都有一个堆栈记录函数调用情况，一个函数占一个帧。函数返回后，这个函数所占的帧就会从堆栈弹出。await 的 async 函数被作为异步帧保存在堆上等待恢复，而不阻碍其它函数入栈执行。在 await 后运行的代码叫 continuation，continuation 会在要恢复时放回到线程的堆栈里。异步帧会根据需要放回栈上。在一个异步函数中调用同步代码将添加帧到线程的堆栈中。这样线程就能够一直向前跑，而不用创建更多线程减少调度。

Douglas 在 Swift 论坛里发的 Swift Concurrency 下个版本的规划贴 [Concurrency in Swift 5 and 6](https://forums.swift.org/t/concurrency-in-swift-5-and-6/49337)，论坛里还有一个帖子是专门用来[征集Swift Concurrency意见](https://forums.swift.org/t/swift-concurrency-feedback-wanted/49336)的，帖子本身列出了 Swift Concurrency 相关的所有提案，也提出欢迎有新提案发出来，除了这些提案可以看外，帖子回复目前已经过百，非常热闹，可以看出大家对 Swift Concurrency 的关注度相当的高。

非常多的人参与了 Swift Concurrency 才使其看起来和用起来那么简单。Doug Gregor 在参与 John Sundell 的播客后，发了很多条推聊 Swift Concurrency，可以看到参与的人非常多，可见背后付出的努力有多大。下面我汇总了 Doug Gregor 在推上发的一些信息，你通过这些信息也可以了解 Swift Concurrency 幕后信息，所做的事和负责的人。

[@pathofshrines](https://twitter.com/pathofshrines)是 Swift Concurrency 整体架构师，包括低级别运行时和编译器相关细节。[@illian](https://twitter.com/illian)是 async sequences、stream 和 Fundation 的负责人。[@optshiftk](https://twitter.com/optshiftk)对 UI 和并发交互的极好的洞察力带来了很棒的 async 接口，[@phausler](https://twitter.com/phausler)带来了 async sequences。Arnold Schwaighofer、[@neightchan](https://twitter.com/neightchan)、[@typesanitizer](https://twitter.com/typesanitizer)还有 Tim Northover 实现了 async calling convention。

[@ktosopl](https://twitter.com/ktosopl)有很深厚的 actor、分布式计算和 Swift-on-Server 经验，带来了 actor 系统。Erik Eckstein 为 async 函数和actors建立了关键的优化和功能。

SwiftUI是[@ricketson_](https://twitter.com/ricketson_)和[@luka_bernardi](https://twitter.com/luka_bernardi)完成的async接口。async I/O的接口是[@Catfish_Man](https://twitter.com/Catfish_Man)完成的。[@slava_pestov](https://twitter.com/slava_pestov)处理了 Swift 泛型问题，还指导其他人编译器实现的细节。async 重构工具是Ben Barham 做的。大量代码移植到 async 是由[@AirspeedSwift](https://twitter.com/AirspeedSwift)领导，由 Angela Laar，Clack Cole，Nicole Jacques 和[@mishaldshah](https://twitter.com/mishaldshah)共同完成的。

[@lorentey](https://twitter.com/lorentey)负责 Swift 接口的改进。[@jckarter](https://twitter.com/jckarter)有着敏锐的语言设计洞察力，带来了语言设计经验和编译器及运行时实现技能。[@mikeash](https://twitter.com/mikeash) 也参与了运行时开发中。操作系统的集成是[@rokhinip](https://twitter.com/rokhinip)完成的，[@chimz](https://twitter.com/chimz)提供了关于 Dispatch 和 OS 很好的建议，Pavel Yaskevich 和 
[@hollyborla]()进行了并发所需要关键类型检查器的改进。[@kastiglione](https://twitter.com/kastiglione)、Adrian Prantl和[@fred_riss](https://twitter.com/fred_riss)实现了调试。[@etcwilde](https://twitter.com/etcwilde)和[@call1cc](https://twitter.com/call1cc)实现了语义模型中的重要部分。

[@evonox](https://twitter.com/evonox)负责了服务器Linux 的支持。[@compnerd](https://twitter.com/compnerd)将 Swift Concurrency 移植到了 Windows。

Swift Concurrency 模型简单，细节都被隐藏了，比 Kotlin 和 C++的 Coroutine 接口要简洁很多。比如 Task 接口形式就很简洁。Swift Concurrency 大体可分为 async/await、Async Sequences、结构化并发和  Actors。下面展开说下。

#### async/await
通过类似 throws 语法的 async 来指定函数为异步函数，异步函数才能够使用 await，使用异步函数要用 await。await 修饰在 suspension point 时当前线程可以让给其它任务执行，而不用阻塞当前线程，等 await 后面的函数执行完成再回来继续执行，这里需要注意的是回来执行不一定是在离开时的线程上。async/await 提案是[SE-0296](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md)。如果想把现有的异步开发带到 async/await 世界，请使用 withCheckedThrowingContinuation。

async/await 还有一个非常明显的好处，就是不会再有[weak self] dance 了。

#### Async Sequences
AsyncSequence 的使用方式是 for-await-in 和 for-try-await-in，系统提供了一些接口，如下：
* FileHandle.standardInput.bytes.lines
* URL.lines 
* URLSession.shared.data(from: URL)
* let (localURL, _ ) = try await session.download(from: url) 下载和get请求数据区别是需要边请求边存储数据以减少内存占用
* let (responseData, response) = try await session.upload(for: request, from: data)
* URLSession.shared.bytes(from: URL)
* NotificationCenter.default.notifications

#### 结构化并发
使用这些接口可以一边接收数据一边进行显示，AsyncSequence 的提案是[SE-0298](https://github.com/apple/swift-evolution/blob/main/proposals/0298-asyncsequence.md)（Swift 5.5可用）。AsyncStream 是创建自己异步序列的最简单的方法，处理迭代、取消和缓冲。AsyncStream 正在路上，提案是[SE-0314](https://github.com/apple/swift-evolution/blob/main/proposals/0314-async-stream.md)。

Task 为一组并发任务创建一个运行环境，async let 可以让任务并发执行，结构化并发（Structured concurrency，提案在路上[SE-0304](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md)）withTaskGroup 中 group.async 可以将并发任务进行分组。

#### Actors
我们写的程序会在进程中被拆成一个一个小指令，这些指令会在某刻会一个接一个同步的或者并发的执行。系统会用多个线程执行并行的任务，执行顺序是调度器来管理的，现代多核可以同时处理多个线程，当一个资源在多个线程上同时被更改时就会出问题。并发任务对数据资源操作容易造成数据竞争，以前需要手动放到串行队列、使用锁、调度屏障或 Atomics 的方式来避免。以前处理容易导致昂贵的上下文切换，过多线程容易导致线程爆炸，容易意外阻断线程导致后面代码没法执行，多任务相互的等待造成了死锁，block 和内存引用容易出错等等问题。

现在 Swift Concurrency 可以通过 actor 来创建一个区域，在这个区域会自动进行数据安全保护，保证一定时间只有一个线程访问里面数据，防止数据竞争。actor 内部对成员访问是同步的，成员默认是隔离的，actor 外部对 actor 内成员的访问只能是异步的，隐式同步以防止数据竞争。MainActor 继承自能确保全局唯一实例的 GlobalActor，保证任务在主线程执行，这样你就可以抛弃掉在你的 ViewModel 里写 DispatchQueue.main.async 了。

Actors 的概念通常被用于分布式计算，Actor 模型参看[Wikipedia](https://en.wikipedia.org/wiki/Actor_model)里的详细解释，Swift 中的实现效果也非常的理想。Actors 的提案[SE-0306](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)已在 Swift 5.5落实。

很多语言都支持 actors 还有 async/await，实现的方式也类似，actor 使用的不是锁，而是用的 async/await 这样能够在一个线程中切换上下文来避免线程空闲的线程模型。actor 还利用编译器，提前做会引起并发问题的检查。

actor 是遵循 Sendable 协议的，只有结构体和 final 类才能够遵循 Sendable，继承于 Sendable 协议的 Excutor 协议表示方法本身，SerialExecutor 表示以串行方式执行。actor 使用 C++写的，源码在[这里](https://github.com/apple/swift/blob/main/stdlib/public/Concurrency/Actor.cpp)，可以看到 actor 主要是通过控制各个 job 执行的状态的管理器。job 执行优先级来自 Task 对象，排队时需要确保高优 job 先被执行。全局 Executor 用来为 job 排队，通知 actor 拥有或者放弃线程，实现在[这里](https://github.com/apple/swift/blob/main/stdlib/public/Concurrency/GlobalExecutor.cpp)。由于等待而放弃当前线程让其他 actor 执行的 actor，在收到全局 Executor 创建一个新的 job 的通知，使其可以进入一个可能不同线程，这个过程就是并发模型中描述的 Actor Reentrancy。

#### Swift Concurrency相关提案集合
所有相关提案清单如下：
*  [SE-0296: Async/await](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md) [【译】SE-0296 Async/await](https://kemchenj.github.io/2021-03-06/)
*  [SE-0317: async let](https://github.com/apple/swift-evolution/blob/main/proposals/0317-async-let.md) 
*  [SE-0300: Continuations for interfacing async tasks with synchronous code](https://github.com/apple/swift-evolution/blob/main/proposals/0300-continuation.md) [【译】SE-0300 Continuation -- 执行同步代码的异步任务接口](https://kemchenj.github.io/2021-03-31/)
*  [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md) 
*  [SE-0298: Async/Await: Sequences](https://github.com/apple/swift-evolution/blob/main/proposals/0298-asyncsequence.md) [【译】SE-0298 Async/Await 序列](https://kemchenj.github.io/2021-03-10/)
*  [SE-0304: Structured concurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md) 
*  [SE-0306: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md) [【译】SE-0306 Actors](https://kemchenj.github.io/2021-04-25/)
*  [SE-0313: Improved control over actor isolation](https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md) 
*  [SE-0297: Concurrency Interoperability with Objective-C](https://github.com/apple/swift-evolution/blob/main/proposals/0297-concurrency-objc.md) [【译】SE-0297 Concurrency 与 Objective-C 的交互](https://kemchenj.github.io/2021-03-07/)
*  [SE-0314: AsyncStream and AsyncThrowingStream](https://github.com/apple/swift-evolution/blob/main/proposals/0314-async-stream.md) 
*  [SE-0316: Global actors](https://github.com/apple/swift-evolution/blob/main/proposals/0316-global-actors.md) 
*  [SE-0310: Effectful read-only properties](https://github.com/apple/swift-evolution/blob/main/proposals/0310-effectful-readonly-properties.md) 
*  [SE-0311: Task Local Values](https://github.com/apple/swift-evolution/blob/main/proposals/0311-task-locals.md) 
*  [Custom Executors](https://forums.swift.org/t/support-custom-executors-in-swift-concurrency/44425) 

#### 学习路径
如果打算尝试 Swift Concurrency 的话，按照先后顺序，可以先看官方手册介绍文章[Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)。再看[Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/)这个Session，了解背后原理看[Explore structured concurrency in Swift](https://developer.apple.com/videos/play/wwdc2021/10134)。动手照着试示例代码，看Paul的[Swift Concurrency by Example](https://www.hackingwithswift.com/quick-start/concurrency)这个系列。接着看[Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133)来了解 actors 怎么防止数据竞争。通过[Discover concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10019)看 concurrency 如何在 SwiftUI 中使用，[Use async/await with URLSession](https://developer.apple.com/videos/play/wwdc2021/10095)来看怎么在 URLSession 中使用 async/await。最后听听负责 Swift Concurrency 的 Doug Gregor 参加的一个[播客的访谈](https://www.swiftbysundell.com/podcast/99/)，了解下 Swift Concurrency 背后的故事。

#### Swift Concurrency 和 Combine
由于 Swift Concurrency 的推出和大量的 Session 发布，特别是[AsyncSequence](https://developer.apple.com/documentation/swift/asyncsequence/)的出现，以及正在路上的[AsyncStream、AsyncThrowingStream](https://github.com/apple/swift-evolution/blob/main/proposals/0314-async-stream.md)和[continuation](https://github.com/apple/swift-evolution/blob/main/proposals/0300-continuation.md)提案（在Xcode 13.0 beta 3 AsyncStream 正式[release](https://developer.apple.com/documentation/swift/asyncstream?changes=latest_beta)），这些越来越多和 Combine 功能重叠的特性出现在 Swift Concurrency 蓝图里时，大家开始猜测是否 Combine 会被 Swift Concurrency 替代。关于未来是 Swift Concurrency 还是 Combine，我的感觉是，Combine 更侧重在响应式编程上，而响应式编程并不是所有开发人员都会接受的，而 Swift Concurrency 是所有人都愿意接受的开发方式，从 Swift Concurrency 推出后开发者使用的数量和社区反应火热程度来看都比 Combine 要大。在苹果对 Combine 有下一步动作之前，我还是更偏向 Swift Concurrency。

见闻写到这里，把独特性比作骨架，真实感比作血肉，故事性和新意比作皮肤，你会发现没有写出自己的经历的话，就像进击巨人里的那些小巨人，即使有了完整的皮肤，但骨头架子不大是不会有开头踢破大门的只有骨架和血肉的巨型大巨人那么强大且震撼有力。

那么接下来我就描写一些我在 WWDC21 期间独特的一些经历。

### WWDC.playground直播活动

想想 WWDC21 过程中我还是有些经历，比如参加了苹果官方推荐的外围活动[WWDC.playgournd by SwiftGG](https://swift.gg/wwdc/)。
![](/uploads/my-little-idea-about-writing-technical-article/3.png)
![](/uploads/my-little-idea-about-writing-technical-article/4.png)

连续看了5天活动直播，还参加了一天的 Live Coding 介绍 SwiftUI 的新特性。直播 Live Coding 准备的时间很少，而且以前我还没有现场当着几千人面写代码的经历，直播前一天晚上赶着通宵达旦看完了相关 Session，写了些代码样例测试，当天白天还开了一个很长的会，回家前和同事讨论一个技术问题时，我发现我嗓子还哑了。到家坐在桌前脚还抽筋了，你可想象到我当时内心有多崩溃。

在直播前，我还专门的给思琦先演练了一遍，其中在介绍 AsyncImage 处理失败、空白、成功还有默认情况时，编译器报错提示无法找到原因，还提示让我提交 bug 的错误信息。直播开始前一直没有找到原因，重新敲了一遍才解决，所以心里没底，直播开始时还一直担心这个问题会重现。直播时在写到这段时果然编译器错误又出现了，当时我脑袋一片空白，心中大呼救我。好在没多一会我突然发现先前一段演示的 placeholder 接口没有删掉，原因真的就是这个，删掉后就正常了，别提有多开心了。后面就轻松了很多。由于只有一天时间准备，很多内容准备了，当时一边敲代码一边说也漏说了很多，比如 AsyncImage 使用的是 URLSession，用的是 URLCache，还不能自定义缓存。Refreshable 只能用在 List 里。SwiftUI 和数组绑定的代码是可以兼容前一个版本的。

另外还有个 WWDC 期间很火的老系统UI挑战赛让我印象深刻，其中有个18岁小伙用 SwiftUI 开发了经典 iPhone4可用版本最火爆，Github 地址[在这里](https://github.com/zzanehip/The-OldOS-Project)。

SwitUI 新特性太多了，直播没提到的还有 task modifier、separator、macOS 上的 table、Canvas、preview in landscape、@FocusState、more button 等等。当时直播有回放，可以在[这里看](https://www.bilibili.com/video/BV1H44y167b7)。更完整详细介绍建议看前面提到 SwiftUI 相关 Session。

WWDC.playgournd 最后一天直播有场 WWDC21 学生挑战赛获奖者张紫怡的分享，她分享了怎样准备挑战赛的过程，通过详细的过程介绍，心得体会，还有思考，让大家了解到了她的热情和才华，而且分享的形式和效果非常有新意。最后一场的回放[看这里](https://www.bilibili.com/video/BV1Fq4y1L7od)。看完这场后，我打算在19号 SwiftGG 和快手中学合办的 WWDC<T> 沙龙活动中使用一种不同的方式进行分享。原先打算的是使用先前写好的一个示例展示使用 SwiftUI 开发复杂应用如何快捷，同时介绍背后的技术。几天想来想去，反复推敲推翻，一直没有新思路。最后到了前一天，我有了个主意，可以使用 SwiftUI 来编写一个幻灯片程序来分享 SwiftUI 的内容啊，同时还能够分享这个幻灯片开发过程心得，这样才有独特性和真实感嘛。于是把准备了一年的内容都删了，就像当时启动那篇删得只剩一万字的文章一样，那篇文章发布前共删掉了四万个字。

### WWDC<T>沙龙活动

可想法总是很容易，实践起来却又是另一种情况。我对自制幻灯片的初步设想是第一能够前后翻页展示内容，第二能够支持和 Keynote 不一样的动画效果和页面美化，第三能够直接在幻灯片上进行一些 SwiftUI 功能的交互演示。

接下来就要开始实际去做了，我先拿出上周用铅笔在 A4 纸画的人草图加工来丰富展示，发现加工的时间来不及了，虽然现在加工速度比以前快了，但是时间太紧，还要写幻灯片程序呢。SwiftUI 开发确实快，每个页面我都写成一个 View，标题、大纲和示意图的组合我做成了通用 View，通过传入不同标题、大纲数组和图片数组来展示不同页面的内容，定义一个 ObservableObject 的类 GlobalStateInfo 作为 View Model 来存储需要的状态数据，比如当前在哪页，当前文字颜色，当前页背景颜色等，每个 View 里使用 @EnvironmentObject 就可以去获取和设置 GlobalStateInfo 了。

关于为了传递数据，是直接调用 EnvironmentObject，还是通过子视图传递 ObservedObject，两种方式哪个更好，在 WWDC21 的 Digital Lounges 里，苹果工程师的回答是两者用途不同。当大部分 View 都需要用到一些通用数据时，推荐使用 EnvironmentObject，因为没有实际使用 ObservableObject 的 View 不会被与之相关的代码搞乱。如果模型不是基于 View 层次结构的对象图，使用 ObservedObject。另外还有个 Digital Lounges 的问题，是问怎么从旧的 AppDelegate/SceneDelegate 生命周期转换到新的 SwiftUI 2 生命周期。苹果工程师说可以使用 UIApplicationDelegateAdaptor 属性包装器，SwiftUI 将实例化你的 UIApplicationDelegate 的一个实例，并以正常方式调用它。更详细的解答和其他的话题可以参看这篇[SwiftUI Lounge QAs](https://roblack.github.io/WWDC21Lounges/)，内容都是 roblack 从 Digital Lounges 里摘出来的，WWDC21 那几天我也在 Digital Lounges（报名早）看大家和苹果工程师的互动，后来看别人说 Digital Lounges 的 SwiftUI 那场爆满，已经超负荷运转了，感觉苹果最近变得更开放了，很多苹果工程师都开通了 Twitter 账号在 WWDC 期间积极和大家互动。

为了使页面不单调，我打算每页大纲的颜色做些区分，发现11页每个都配一遍看效果时间太紧，于是我选择了一些背景色通过随机读取，每次看到的颜色都是不同的，由于都是一个一个手动选出来的，所以不同组合效果也不会太差。

现在前后翻页展示内容这个想法是完成了，这也是 SwiftUI 开发的优势，能够快速构建页面架子和简单的数据页面同步设置。但是第二个想法，完成起来就非常费时费力且不那么顺利了。

首先说下字体，系统默认字体很正式，以往我都是直接用 iPad 手写，但是这次时间紧没法一个字一个字的写了，所以我打算选择其它字体，View 的 .font 修改器可以选择其它字体，方法是 .font(Font.custom("font-name", size: 110))。如果直接在Finder里查看字体没法得到可用的字体名，需要使用 NSFontManager.shared.availableMembers 来获取可用字体名。

接下来是标题，以往做幻灯，经常讲到具体内容时，特别是细节时，容易让看的人忘记当前页主题是啥。如果标题太大，可展示内容就少了，及时这样，观看的人也容易忽视主题。因此，我打算把标题做成一个循环的动画，这样就可以在我展开说内容的时候，看的人即使走神了还能够注意到当前页主题。标题的动画主要是控制好动画的时间，不能太快，不然会过于吸引注意。

以前 keynote 的转场动画我基本都试过，每次来回都是那些，很难和其他人做出差异来。只能靠图和配色作区分。这次我利用每页的内容大纲进入效果来作为转场动画。我先将大纲列表放到 VStack 里，ForEach 里获取到下标，通过下标获取列表数组里的 Text View。之所有要得到下标而不是直接获取列表数组里的 Text View，其原因是还会将这个下标用在转场动画效果上，我希望大纲列表的内容是一个接一个进来的，需要这个下标值来做时间间隔。Animation 的效果使用的是 interpolatingSpring，我将 damping 参数设置为0.3，这样弹性效果更佳。列表内容进入的是 GeometryEffect 协议，用来替代 AnimatableModifier，通过 AnimatablePair 来设置移动位置新旧值。直接一个方块滑入略显单调，使用 CGAffineTransform 里的 c 参数可以设置将矩形进行变形，会有一种被拉进来的感觉。变形过程配合滑入动画再加上 interpolatingSpring 设置的弹性效果，会让转场更有动感。

并行执行的动画越丰富，转场感觉就会更好，我想着每页都做个不同的效果，使用 Shape 绘制一些图形做背景动画，这样会有新鲜感。当第一页和第二页弄完后已经天亮了，经过一个上午，下午就要分享了。我还没有困意，因为后面还有那么多页面没有做完区分转场的动画和配色，更别说 SwiftUI 功能的交互演示了。而且具体分享的内容我还没有整体串一遍逻辑。一天一夜完成这个项目时间还是太紧，当时想着要再能多一天时间就好了。2点开始分享，1点我在旁边一个小会议室把整个内容自己在心里试着说了一遍。分享内容包括了自制低版本兼容 AsyncImage 演示、SwiftUI 那些版本兼容问题、SwiftUI 背后关键技术简介、SwiftUI 生命周期、布局、Modifier、不透明返回类型、属性包装、Result Builder、Geometry、Preview用的技术。

其中 SwiftUI 内部运作的机制是每个 View 都有自己的 Identity，SwiftUI 会将给 State 和 StateObject 分配内存空间的 Storage 和 View 的 Identity 绑定起来，共存亡。当相同 Identity 的状态数据发生变化了或者和 View 依赖关系改变了，就会重新建立 View 和 RenderNode 的依赖关系，他们之间的关系是图结构，图结构可以降低依赖关系检查复杂度。最后渲染出来。总的来说 SwiftUI 运行原理有三个点最重要，Identifier、生命周期和依赖。视图的生命周期是 Identifier 来决定的，state 生命周期和视图的生命周期是相同的。在生命周期中，state 有变化的时候会做diff，diff和渲染效率提升是使用图型依赖结构，只渲染状态依赖的视图，如果按照 UIKit 那样的树形结构做diff，效率会特别差。

现在很多常用开源库都已经对SwiftUI做了适配，苹果公司自己的App，比如天气、相册、快捷指令、地图和相册都有用到SwiftUI。以下是SwiftUI用到的语法特性：

* ResultBuilder
* ViewBuilder
* Trailing Closure
* Opaque Type
* Inline
* PropertyWrapper
* KeyPath
* DynamicMemberLookup

如果你使用这些特性也能够再造一个兼容低版本的类似 SwiftUI 的框架。SwiftUI 最显现的 DSL 技术使用的就是 ResultBuilder 语法特性，Result Builder的提案[SE-0289](https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md) 里有详细的描述，通过 Result Builder 下面的方法可以自定义出一个简洁的 DSL 出来，提高特定业务开发效率。

* buildBlock：构建基本语句的block组合结果。
* buildExpression：可选，给表达式提供上下文类型信息。
* buildOptional：对没有else的if语句支持。
* buildEither：构建选择语句不同结果。通过条件结果折叠成一个结果，实现对if-else和switch语句的支持。
* buildArray：将所有迭代结果合并成一个结果的方式实现对for...in语句的支持。
* buildFinalResult：可选，可以调用顶层函数体的结果进行处理，产生最终的返回结果。
* buildLimitedAvailability：会在if #available的block部分结果上调用，使result builder可以擦除类型信息。

这次的 WWDC 还专门有个 Session 讲解了怎么用 Result Builder 来做 DSL，这个 Session 是 [Write a DSL in Swift using result builders](https://developer.apple.com/videos/play/wwdc2021/10253/)。

Swift 视图返回的类型是不固定的，因此使用了 Swift 的不透明类型语法特性来进行支持，支持其返回带有大量泛型参数的庞大类型，这个类型中还包括了 Result Builder 中的 if 条件类型值，支持多分支类型。Opaque Types的提案在这里[SE-0244](https://github.com/apple/swift-evolution/blob/master/proposals/0244-opaque-result-types.md)。

跟着视图后面的点语法是 modifier，每个 modifier 都会在视图树中新建一个层，因此 modifier 的写的先后顺序不同，效果是不一样的。

对于数据的监听和响应使用的是 swift 里的属性包装语法特性，属性包装的提案是[SE-0258](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md)。包装后数据的使用就方便了很多，对于不同属性包装类别的选择可以按照数据类型和应用场景来，对于值类型，如果是只读的数据可以什么都不加，如果数据是可读写的，使用@State，如果数据是需要在其他视图进行读写并自己也同步响应的，使用@Binding进行声明。对于对象类型的数据，指向对象的引用能发生变化要用@ObservedObject来声明，引用不可改变，那么就用@StateObject，使用环境传递对象用@EnvironmentObject。

完整的 WWDC<T>沙龙活动回放可以扫下图中的二维码：
![](/uploads/my-little-idea-about-writing-technical-article/5.jpeg)

![](/uploads/my-little-idea-about-writing-technical-article/6.JPG)
![](/uploads/my-little-idea-about-writing-technical-article/7.jpeg)


下面是当时现场演示的部分幻灯片，动画的效果可以看上面的视频回放：

![](/uploads/my-little-idea-about-writing-technical-article/8.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/9.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/10.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/11.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/12.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/13.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/14.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/15.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/16.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/17.PNG)
![](/uploads/my-little-idea-about-writing-technical-article/18.PNG)

至此，这篇WWDC21见闻就写完了，详细描写自己WWDC21期间的一些独特经历和其中涉及相关技术，这样会让文章的独特性和真实感有很大的提升。

## 对独特性和新意的思考
通篇看下来，你是不是感觉到故事性和真实性其实是非常容易做到的。可以理解为只要努力些，时间再长些，这两点就能够完成，且能线性得到提高。只埋头做事情比较容易和舒适，但一直这么干，熵就会越来越多，不可逆的无用能量无法排除。而独特性意味着你会去体验适应新的环境，去获取实践新的认知，去结识新的朋友碰撞新的思路，使得自己体验到不同以往的经验。新意成功几率很低，非线性的，类似于基因突变产生的进化，这和努力无关。新意和独特性一样属于逆熵过程，不能忽视，大跨步的进步需要对传统的颠覆。新意会带来新的独特经历形成一个新的循环，不去尝试就不会有新的机会。

如果把本文当成一篇笔记，其间又融入了写作心得；如果把本文当做一篇写作心得，其间又穿插了大量笔记内容。你说这是不是也是一种新意呢。

对于新意，我印象最深的还是权力的游戏的血色婚礼，神来之笔，当Joffrey正最可气，少狼主正得势时，剧情完全打破传统，效果非常震撼。凡人皆有一死，凡事皆有可能，于是乎对后面剧情的推进更加期待了。而这个新意是建立在整个剧对真实感上的毫不含糊，包括了扎实的世界观构建，服饰道具高度的还原，完全把观众带入了故事中。另外作者对古历史的专研和记者经历的结合产生出的鲜明的人物刻画和独特的剧情设计也是本剧的骨架支撑，独特性的体现。

## Finally
今天我说的这些心得可以作为下笔“记录和分享”技术的一个契机，但是对于自己技术的成长，写文章并不是最终的目的，写作是你对自己思想的研究和开发。文章的上限是你的技术能力，文章只是让人了解你技术一种手段。因此更重要的是你做的技术是否有突破有演进，获得应用，并在产品中取得了好的效果。还有那些孤独着研究技术的时光，经历着一直努力着奋斗着却一直不被看见，得不到认同，也没有结果的岁月，还能够一直被自己的热情感动而不放弃去取得一点点进步带来的满足感。
































