---
title: WWDC 2021 Day1 笔记
date: 2021-06-08 16:54:01
tags: [iOS, Apple, Swift]
categories: Programming
---

WWDC开始了，一周时间会有大量Session可学习，这个页面[https://github.com/twostraws/wwdc](https://github.com/twostraws/wwdc) 收集了来自社区的各种WWDC活动、新闻和教程的链接，随着WWDC的进行，页面内容会不断更新，去年2020年的汇总页在这里[https://github.com/twostraws/wwdc/blob/3d3b093218af06465b6b268b23e13e2ad6e2d9f8/README.md](https://github.com/twostraws/wwdc/blob/3d3b093218af06465b6b268b23e13e2ad6e2d9f8/README.md) 。Apple官方收集的开发者组织活动页面是[https://developer.apple.com/wwdc21/beyond-wwdc/](https://developer.apple.com/wwdc21/beyond-wwdc/) ，其中有SwiftGG翻译组组织的活动，介绍页[https://swift.gg/wwdc/](https://swift.gg/wwdc/) ，会在本周每晚8点线上直播交流WWDC21中关注度高的话题以及live coding展示热点技术，嘉宾有喵神、故胤道长、mmoaay、61、钟颖、周楷雯等。

[https://www.wwdcnotes.com/](https://www.wwdcnotes.com/) 这是一些WWDC的笔记（比看视频快）汇总，可以订阅他的RSS，还在更新中

下载WWDC2021高清Session视频脚本：[https://github.com/dmthomas/AppleVideoDownloadScripts](https://github.com/dmthomas/AppleVideoDownloadScripts)


## 一些关注点收集


-  SharePlay（使用Group Activities框架）同步共享设备上App的操作和播放 
-  FaceTime on Web 
-  Live Text（看讲座时可以直接拍照拷贝代码了，iPhoneX below not support） 
-  iPadOS 多任务感觉更难用了 
-  Notes: Tag browser 
-  Quick Note（方便） 
-  Swift Playgrounds able to build apps（SwiftUI only）（Let's try to build and upload App on iPad） 
-  iCloud+ hides ip and location ==? VPN（VPN apps:"Shit"） 
-  Craig drove Apple Car? 
-  Universal Control （just support M1） 
-  ShortCuts for Mac 
-  Object Capture（Dream comes true） 
-  Actor（Apple SDK会大量使用，[@MainActor ](/MainActor ) 属性包装 in UIKit，BUT，Swift Concurrency requires a deployment target of macOS 12, iOS 15, tvOS 15, and watchOS 8 or newer. :( Damn that's sad）  
-  A/B testing in App Store 
-  Xcode Cloud（not in 99$，Bitrise die?）多设备云测试（截图）。自建的构建流程可以从中借鉴。 
-  TestFlight for the Mac 
-  Xcode 13 has Vim mode 
-  Xcode 13 一些重要优化和新功能： 
   - Smarter Swift Code Completion
   - Faster Swift Builds
   - Swift Documentation Compiler
-  To build documentation for your Swift framework or package, choose Product > Build Documentation 
-  SwiftUI gains more control over lower-level drawing primitives with the new Canvas API. 
-  SwiftUI AsyncImage [https://developer.apple.com/documentation/swiftui/asyncimage](https://developer.apple.com/documentation/swiftui/asyncimage) 
-  List has gained a lot of new capabilities this year: 
   - Swipe Actions [https://developer.apple.com/documentation/swiftui/texteditor/swipeactions(edge:allowsfullswipe:content:)?changes=latest_minor](https://developer.apple.com/documentation/swiftui/texteditor/swipeactions(edge:allowsfullswipe:content:)?changes=latest_minor)
   - Pull-to-refresh (with .refreshable(action:)) （just work with List, not scroll view, bug?） [https://developer.apple.com/documentation/swiftui/texteditor/refreshable(action:)?changes=latest_minor](https://developer.apple.com/documentation/swiftui/texteditor/refreshable(action:)?changes=latest_minor)
   - Separator customization

-  SwiftUI has a new, pretty cool, **debugging** utility to help you understand what is causing a view to be reevaluated. Call `Self._printChanges()` inside the body of a view to print out the changes that have triggered the view update. 
-  SwiftUI：Map、Photo、ShortCuts、Weather、Apple Pay、Find Mine(WatchOS) 
-  SF Symbols update [https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/](https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/) 
-  AttributedString：support Markdown syntax，init(markdown:options:baseURL:) （you can delete your hand-rolled markdown parser） [https://developer.apple.com/documentation/foundation/attributedstring](https://developer.apple.com/documentation/foundation/attributedstring) 
-  HTTP analyzer in Instruments, intriguing（Charles？） 
-  Surge works fine on the iOS 15 beta 1. 
-  StoreKit 2 APIs Provide Customer Support 
-  New ⌘+Shift+G in Finder 
-  macOS 12 Beta 上微信会崩 
-  iOS 15 Beta 非常流畅，九宫格键盘好用了 
-  UIButton support multiple lines of text 
-  Selective Shader Debugger 
-  Screen Time API 家庭控制，做限制 



## 一些SwiftUI相关Session


- Write a DSL in Swift using result builders [https://developer.apple.com/videos/play/wwdc2021/10253/](https://developer.apple.com/videos/play/wwdc2021/10253/)
- Demystify SwiftUI [https://developer.apple.com/videos/play/wwdc2021/10022/](https://developer.apple.com/videos/play/wwdc2021/10022/)
- Discover concurrency in SwiftUI [https://developer.apple.com/videos/play/wwdc2021/10019/](https://developer.apple.com/videos/play/wwdc2021/10019/)
































