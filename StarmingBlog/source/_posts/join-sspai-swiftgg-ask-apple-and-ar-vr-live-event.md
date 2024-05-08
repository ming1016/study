---
title: 参加了少数派和 SwiftGG 举办的《和我们一起畅想 Apple 的 AR 与 VR》直播活动
date: 2022-10-24 15:47:34
tags: [Apple]
categories: Programming
banner_img: /uploads/join-sspai-swiftgg-ask-apple-and-ar-vr-live-event/01.png
---

上周，我参加了少数派和 SwiftGG 举办的《和我们一起畅想 Apple 的 AR 与 VR》直播活动，这里是[视频回放](https://weibo.com/1914010467/MbvfZp6Fj)。其中聊了些参加 Ask Apple 活动的一些感受和收获，还聊了些 Apple XR 相关内容。

## Ask Apple

![](/uploads/join-sspai-swiftgg-ask-apple-and-ar-vr-live-event/01.png)

这次 Apple 的 [Ask Apple](https://www.apple.com.cn/newsroom/2022/10/apple-introduces-ask-apple-for-developers/) 活动有中文集锦版块，我感觉很贴心，先前 Apple 在 WWDC 期间的 Digital Lounge 中都是英文，阅读起来时间成本很高，需要过滤很多信息。我觉得参加活动的开发者分为两种，一种是在工作中有问题想要解决的，他们也会用各种渠道去找解法，比如请教身边有经验的人，问其他公司的朋友，或者直接在官方 feedback 里提。另一种开发者是当前没有疑难杂症，只是想关注下其他人关注的问题，还有看看有没有自己平时没太注意到的技术是否能够用到自己的工作中。

在 WeatherKit 主题环节中，有开发者问是否有有完整的天气相关的 Symbol 可以用，苹果工程师会列出自己整理的天气 Symbol 名称集，真是非常贴心了。

我还从天气主题的问答中，了解到天气预报还有分钟级的，不过目前可以用的国家只有美国、英国和爱尔兰。大部分国家会有恶劣天气事件可以用。天气主题中，大家很关注的是天气请求配额的问题，毕竟用多了是要自己掏腰包的嘛。了解到的情况是天气请求配额并不是简单的按请求次数来的，服务端会缓存的数据请求，相同的请求在缓存时间内请求多次也只算一次，数据更新了才会算新增加一次。

在 SF Symbols 环节有个有趣的情况，当时 Apple 工程师问大家平时自制 Symbol 一般用啥工具，举例是  Illustrator、Sketch、Affinity Designer，却没提最近最火的 Figma，Apple 提供的素材也没有 Figma 格式的，于是大家都回答 Figma，气氛略显尴尬，当然不排除砸场子的可能。我想大家只是希望 Apple 能够了解到 Figma 阵营已经很壮大了。

在 Widget 主题环节，开发者都提到了widget刷新频率问题，其实是有官方文档[《Keeping a Widget Up To Date》](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)专门阐述这个问题的， Apple 工程师也找出来发到了 Slack 中。

还有个是 SwiftUI 这次新推出的共享面板支持 ShareLink，我看还有开发者不知道，可能是他没来得及看 WWDC Session。其实这样没来得及看或者没时间看 Session 的人应该还有很多，正在解决手头问题或者开发新功能，碰到了具体问题就来问的。Ask Apple 这样的活动就可以解决他们的燃眉之急。

对于很多人关注用户体验的人，很关注后台任务怎样更新资源策略，Apple 工程师回答的很详细，还贴出了 一个官方 [demo](https://developer.apple.com/documentation/backgroundtasks/refreshing_and_maintaining_your_app_using_background_tasks)，我正好也全面了解了下。另外今年 Apple 推出的 Background Asset 可以让系统统筹进行资源更新，这个更新过程可以发生在 App 未启动状态。

[fatbobman](https://twitter.com/fatbobman/) 整理了 Ask Apple 活动中关于 CoreData 的内容，[上 ](https://www.fatbobman.com/posts/Core-Data-of-Ask-Apple-2022/) 和 [下](https://www.fatbobman.com/posts/Core-Data-of-Ask-Apple-2022-2/)。先前关注他博客里提到他开发的 App 用的是 Core Data 和 CloudKit，fatbobman 自己也在 Ask Apple 中问了相关问题，看得出他的收获很大。


## XR

![](/uploads/join-sspai-swiftgg-ask-apple-and-ar-vr-live-event/02.png)

直播活动后半场环节是围绕 Apple 可能推出 XR 设备的讨论。

记得19年有篇报道称苹果内部有人透露出他们会在22年先推出结合AR和VR的头盔。23年再出轻便的 XR 眼镜，代号是 N421，官方回应的是硬件可能会不同，也可能不会推出。透露消息的人称自己是在 Apple 的千人大会上了解到的，参会人都是参与 XR 的项目组成员。

目前来看22年都快要结束了，还没有新 XR 消息。根据这几年苹果为XR做的技术铺垫，我觉得很有可能是一个轻便的很时尚的 AR 眼镜，不会像赛亚人那种很科幻的样子。

关于什么是 AR 什么是 VR，我觉得像环球影城里的哈利波特城堡还有迪斯尼加勒比海盗那种，在移动中结合了真实场景和虚幻场景的就是 AR。坐着不动体验比拟真实场景的虚幻场景，比如迪士尼的飞跃地平线就是VR。最终带来的愉悦感其实是差不多的。

眼镜最担心的是常带的电量问题。

我觉得 Apple 的这款常态是待机模式。待机模式会常显，类似 apple watch 和 iphone14 的那种常显，这样可以做到非常省电，内容类似 lock screen，可以自定义时间组件和下面三方 app 提供的 widget 和 live active。这样就在最省电的情况下依然可以看到自己关注的信息。

第二种是激活状态，这个状态下会开启摄像头，完成类似 iPhone 和 iPad 上的 AR 功能。AR Quick look、扫描物品、WorldMap、人物跟踪、4K、Location Anchor 这些 ARKit 的功能和应用都可以使用。

最后还可能会有投屏模式，可以将手机、电脑甚至是 Watch 上的内容投到眼镜上。使用通用控制功能，可以让 Apple Watch、iPhone、iPad 触摸屏、鼠标和键盘都可以进行眼镜的输入控制。

通过苹果申请的专利来看，他们使用的是无线充电模式，到时候可能会类似 airpod 那样的充电盒子的方式，比如可充电的眼镜盒。另外有个专利显示苹果设备是可以看穿到外部的，很有可能会是外带的轻便眼镜，而不会是头盔。因为 VR 头盔可以活动范围太小，不健康，不符合苹果提倡那种 Apple watch 运动模式的健康生活方式。

那什么 Apple 的技术会用到眼镜上呢？

ARKit 以及基于 ARKit 的 RoomPlan 和 Live Text 很明显就是给眼镜用的，RoomPlan 解决的是眼镜应用中虚拟物品摆放的问题，Live Text 可以解决现实世界中信息的识别问题。

ARKit 目前用的最多的应该就是 AR Quick Look 这个技术，它可以很方便的将虚拟物品摆到现实中。网页结合很简单，在 a 标签加上rel=ar 属性，然后href里添加模型USDZ文件连接就行了。

ARKit4 的地理位置跟踪，可以在坐标点上放置虚拟元素，当别人打开 AR 应用走到放置的区域时，就可以加载出预先放置的虚拟元素。

新增 Motion Capture 2D 和 3D 骨骼检测，还有耳骨检测，可能是想检测对方有没有在看你。

交互界面上，SwiftUI 和 Stage Manager 肯定会用于眼镜的 UI 和 UX 设计中。SwiftUI 描述界面和交互设计是再合适不过的了。Stage Manager 可以将空间里大量的复杂交互应用进行分组。

对于镜片显示的技术来说，苹果收购了多家研发 [micro LED](https://en.wikipedia.org/wiki/MicroLED) 的公司，micro LED 像素间距的上限更小，比 LCD 和 mini LED 都要小得多，上限高，就能有更大的分辨率的可能，更小的屏幕能够做到更高的分辨率。micro LED 使用的是非有机材料，相比较于 OLED 寿命要长，有着和 OLED 一样的高色彩对比度，还有更高的亮度尼特上限。micro LED 比过渡型的 mini LED 要省电。micro LED 的缺点是成本高，这个是目前在 micro LED 在攻克的难题。

Apple 的 Pro Display XDR 和最新的 iPad Pro MacBook Pro，用的是过渡到 micro LED 的 mini LED 屏幕，Pro Display XDR 亮度能够到1600尼特，并且使用寿命和节能都比 OLED 好，这点可以看出 Apple 未来的方向会体验更好的 micro LED。

从苹果收购 Beates 后，苹果加强了耳机硬件实力，空间音频可以提高虚拟世界元件的真实感，比如头顶有只虚拟的鸟，鸟叫声也是从上面传来，这样的感觉是不是很真实。

现在市场上已经推出了一些眼镜。微软的 VR + AR 的大头盔 Hololens 面对的不是普通用户而是专业人，比如建筑行业通过头盔可以看到现在建筑的情况，测量和检测，辅助工程，提高效率，保障安全。Hololens 售价是3500美金。Facebook 的 Oculus VR头显着重元宇宙，VR 主要是在室内场景使用，但室内里可以娱乐的东西太多了，竞争必然会很激烈。轻便的 AR 在户外的设备竞争会少些，目前用的最多的也就是听音频和看手表的设备，操作也比较麻烦，室外会有很多等待或者枯燥的时间待开发。

Snapchat 做的眼镜是为开发AR滤镜的人用的。Google 今年推出一个用于翻译垂直领域的眼镜，感觉应该是上次 Google Glass 没做成，吃一亏长一智，这次打算先精准定位下翻译这个市场。

开发者最关心的应该是如果 Apple 眼镜时代到来了，需要做哪些准备，储备什么技术。

我认为学好 ARKit 和 SwiftUI 是最有用的。还有这次 Ask Apple 活动里的那些技术主题，应该也是个信号，可以着重学习。

偏硬件的主题有[增强现实](https://developer.apple.com/documentation/arkit/)、[RoomPlan](https://developer.apple.com/documentation/roomplan/)、照片与相机、[能耗与性能](https://developer.apple.com/documentation/metrickit/improving_your_app_s_performance)。偏界面交互的主题有设计、[SwiftUI](https://developer.apple.com/documentation/SwiftUI)、[WeatherKit](https://developer.apple.com/documentation/WeatherKit)、[Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)、[Live Text](https://developer.apple.com/documentation/visionkit/enabling_live_text_interactions_with_images)、[机器学习](https://developer.apple.com/machine-learning/create-ml/)、隐私、Focus 等。

Apple 眼镜时代带来了更多机会。下面是我比较感兴趣的会带来的变化。

首先是数字收藏品，这对于数字艺术创作者来说有了更多机会。数字雕塑、模型、挂画和时钟等会更多的出现在房间、办公室甚至室外。

对艺术创作者体验来说，可能更接近以前雕塑家和壁画画家，只是减少了现场的清理工作，失误了也不用重头再来，简单的做个撤回就好了。因此创作者可以更好地专注在创作本身。

绘画素材的收集，以前可能更多的是速写或者拍照，现在用眼镜就能很方便的把整个环境都扫描下来，回到工作室可以慢慢的在各个角度来观察素材。






