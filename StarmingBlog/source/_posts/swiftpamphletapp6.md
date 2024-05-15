---
title: 戴铭的开发小册子6.0，使用SwiftUI、SwiftData、Observable、NavigationSplitView 进行了重构
date: 2024-05-08 21:05:31
tags: [App]
categories: App
banner_img: /uploads/swiftpamphletapp6/05.png
---

目前戴铭的开发小册子已经上架 macOS 应用商店，[点击安装](https://apps.apple.com/cn/app/%E6%88%B4%E9%93%AD%E7%9A%84%E5%BC%80%E5%8F%91%E5%B0%8F%E5%86%8C%E5%AD%90/id1609702529?mt=12)，或在 macOS 应用商店“戴铭”关键字。

[![Available on the App Store](https://ming1016.github.io/qdimg/badge-download-on-the-mac-app-store.svg)](https://apps.apple.com/cn/app/id1609702529)

本版本解决了以前的几个问题。

第一个，存储的问题。以前使用的是三方数据库，写法比较繁琐且和 SwiftUI 结合的不好。现在用的是 SwiftData，写法简洁了很多，代码也好维护了。更多技术重构细节可以直接查看 App [代码](https://github.com/ming1016/SwiftPamphletApp)。

第二，手册内容和资料之间的关系。以前比较隔离，资料和手册没有联系。现在采用的是每个知识点都可以添加相关资料，这样更利于知识的积累。

第三，Github 库和开发者信息的管理问题。以前添加和删除都在代码层面，现在可以直接在 App 内进行。

这三个问题解决后，可以将更多精力花在内容的更新增加以及 App 使用体验上了。


![](/uploads/swiftpamphletapp6/01.png)

![](/uploads/swiftpamphletapp6/02.png)

![](/uploads/swiftpamphletapp6/03.png)

![](/uploads/swiftpamphletapp6/04.png)

![](/uploads/swiftpamphletapp6/05.png)

内容主要包含

- Apple 技术知识点以及示例
- 历年 WWDC

功能主要包含

- 手册书签收藏
- 资料收集整理
- 离线保存资料
- 知识点和资料关联
- 手册、WWDC和资料可搜索
- Github 开发者和仓库信息添加管理

知识点目前主要有 Swift 基础语法，SwiftUI，SwiftData，小组件等知识内容。其他内容还在迭代新增和更新中。