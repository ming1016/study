---
title: 我为什么写了《跟戴铭学iOS编程》这本书
date: 2020-04-12 20:31:03
tags: [iOS, book]
categories: Programming
---

在我改了几次封面后，书已上架。

![](/uploads/why_write_study_ios_programming_with_daiming_book_and_draw_recently/01.jpg)
![](/uploads/why_write_study_ios_programming_with_daiming_book_and_draw_recently/02.jpg)
![](/uploads/why_write_study_ios_programming_with_daiming_book_and_draw_recently/03.jpg)
![](/uploads/why_write_study_ios_programming_with_daiming_book_and_draw_recently/04.png)
![](/uploads/why_write_study_ios_programming_with_daiming_book_and_draw_recently/05.jpg)
![](/uploads/why_write_study_ios_programming_with_daiming_book_and_draw_recently/06.png)
![](/uploads/why_write_study_ios_programming_with_daiming_book_and_draw_recently/07.png)

## 为什么写《跟戴铭学iOS编程》

又到了新的一年开始换工作的季节，我身边好多熟人也都开始寻找机会，看起来离职原因各有不同，有绩效不好的、和领导处不好的、多年难晋升的、做的事情难提升自己的、有更好机会的。但究其核心，我觉得还是危机感，想着如果脱离现在所处公司环境，没有现在的级别位置，自己还剩下什么，在一群候选人里，自己有没有胜于其他人的亮点，是否能够脱颖而出。我时常会思考这些问题，做了多年技术，一直在想，相同时间里接触和学习什么知识才是物有所值的。

计算机领域，作为开发者最开始接触，同时也是运用最多的就是编程语言，现在学习 iOS 开发一定要选择用 Swift。那么，从 Swift 官方手册学习完 Swift 语法，熟练进行 App 开发上架及日常迭代开发后，还要学习什么才能够让自己能够更进一步呢，才能让自己更有竞争力，我觉得这个是需要反复思考的。我不觉得无休止的跟进每年系统升级新特性，比如 ARKit、WatchKit、Force Touch、iBeacon、SiriKit 等，或者熟练系统和开源控件，比如Segmented Control、Picker View、Pop、能够对自己有本质的提高。不是说学这些没用，而是够用就行，毕竟开发 App 来服务用户，最终还是需要由这些来支持功能开发。

我想表达的是，对于你个人来说，当你要从普通开发者往架构设计师这条路上走，除了满足用户功能需求的开发，还需要了解更多技术选型，才能为团队开发效率和质量提供支持保障。这不光是凭借经验就能够做到的，还需要对编程语言和编程范式有更多的了解，我在写《跟戴铭学iOS编程》这本书时，我对 Swift 语言做了深挖，而不是照搬手册，也是想让你能够通过泛型，集合、内存和范式更多了解 Swfit 这门语言。同时结合实际开发中使用最频繁的场景，比如 JSON 数据处理，网络请求和界面布局，从底层源码层面来剖析这些应用场景背后的代码实现原理。本书 Swift 章节最后还详细说了怎么用 Swift 开发了语言转换器和解释器，一步一步掌握语言解析的过程，这部分内容是对上次我在 @Swift 大会上讲的内容的补充，大会幻灯片可见：[这次swift大会分享准备的幻灯片和 demo | 戴铭的博客 - 星光社](https://ming1016.github.io/2018/09/17/produce-slides-of-third-at-swift-conference/)。

对语言编译过程的学习，价值是很高的，本书也着重介绍了编译以及编译产物的知识和运用。你可以回想下，当碰到一个以前没有做过的需求，解决一个没有碰到过的线上问题时，处理的方案肯定是有高低之分的，了解的越多越深入，方案就更有效，比如先前热修复时期，为了能够让原生开发不学前端代码进行热修复，利用 Clang 进行代码转换，从而节省了学习成本，再到后来，为了提升修复代码性能而内置解释器解释编译出的字节码，说明了贫穷往往会限制想象力，而富有的知识能够提高想象空间。当然编译的知识不光只限于这些，比如使用 LLVM 中的静态检查能力可以辅助监控代码质量，学习编译前端知识也能够使自己具有动手处理代码的能力，比如根据自己工程特点进行代码的批量处理，省时省力。我在最近做启动优化时发现，使用编译前端的知识还能够很轻松的处理特定规则的文件，甚至直接从代码中提取需要的部分，从而提高分析启动问题的效率。

对编译产物结构进行了解，不光能逆向看竞品，还能够了解和处理其它很多其它事情，比如 c 语言方法 hook，方法调用堆栈符号化的原理，启动时二进制加载过程的了解等。这些知识点既不容易过时也具有通用性，这些年来，计算机底层不断演进，系统不断趋同，特别是数据结构的设计就有很多值得学习和借鉴的，比如去了解编译产物导出符号为什么 trie 数据结构，能够学习到时间和空间复杂度在实际场景中是如何做选择的。

现在各公司正在尝试运用跨端技术，当你从 React Native 到 Weex，再到小程序，直到现在 Google 出的 Flutter，一路跟过来，你一定会觉得很疲惫，即使你都已熟练掌握了怎么使用，开发了很多功能，趟过了无数坑，当你面对下一个流行框架时，你可能又要重新来过。那怎样才能够使自己价值提高呢，一个合格的架构师需要具有的是看清技术本质和趋势的能力。而了解这些技术本质是了解隐藏在这些跨端技术背后的实现，这些实现主要用到了 DSL 转义、热更新、JavaScriptCore 桥接原生、解释器、WebCore 渲染的改造（Flutter），这些在本书中都会详细的跟你说，特别是最后大前端技术那章，会深入介绍WebKit 中的 JavaScriptCore 和 WebCore 的原理和源码实现，以求让你能够知其然知其所以然。

你会发现当你学习了上面提到的知识并加以实际运用后，工作中处理问题，甚至是疑难杂症时，你的脑海中就不再是一张白纸无从下手，而是满满的一书柜整理好的资料信手拈来。同时自己的竞争力也能够得到提升。

## PS

书出版后，巧哥在公众号上做了推荐《[iOS 界的黑客与画家 - 戴铭](https://mp.weixin.qq.com/s/82ZZTmGRNcYINuVqEGz38A)》，硬核号主冬瓜的文章也介绍了这本书《[说一说戴铭老师新书中的技术侧重](https://mp.weixin.qq.com/s/1eG5alckPs8ODh72tzA77w)》

欲购《跟戴铭学iOS编程》这本书，通过这个[京东链接](https://item.m.jd.com/product/12839082.html?dist=jd)可以以全网最低价49元买到，也可加我微信 allstarming，备注“购书”来购买。
































