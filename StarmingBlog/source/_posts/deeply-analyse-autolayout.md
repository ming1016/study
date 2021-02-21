---
title: 深入剖析Auto Layout，分析iOS各版本新增特性
date: 2015-11-03 21:17:54
tags: [Autolayout, iOS]
categories: Programming
---
先前写到的一篇Masonry心得文章里已经提到了很多AutoLayout相关的知识，这篇我会更加详细的对其知识要点进行分析和整理。

# 来历
一般大家都会认为Auto Layout这个东西是苹果自己搞出来的，其实不然，早在1997年Alan Borning, Kim Marriott, Peter Stuckey等人就发布了《Solving Linear Arithmetic Constraints for User Interface Applications》论文（论文地址：<http://constraints.cs.washington.edu/solvers/uist97.html>）提出了在解决布局问题的Cassowary constraint-solving算法实现，并且将代码发布在他们搭建的Cassowary网站上<http://constraints.cs.washington.edu/cassowary/>。后来更多开发者用各种语言来写Cassowary，比如说pybee用python写的<https://github.com/pybee/cassowary>。自从它发布以来JavaScript，.NET，JAVA，Smalltall和C++都有相应的库。2011年苹果将这个算法运用到了自家的布局引擎中，美其名曰Auto Layout。

## Cassowary
Cassowary是个解析工具包，能够有效解析线性等式系统和线性不等式系统，用户的界面中总是会出现不等关系和相等关系，Cassowary开发了一种规则系统可以通过约束来描述视图间关系。约束就是规则，能够表示出一个视图相对于另一个视图的位置。

# Auto Layout的生命周期
进入下面主题前可以先介绍下加入Auto Layout的生命周期。在得到自己的layout之前Layout Engine会将Views，约束，Priorities（优先级），instrinsicContentSize（主要是UILabel,UIImageView等）通过计算转换成最终的效果。在Layout Engine里会有约束变化到Deferred Layout Pass再到应用Run Loop再回到约束变化这样的循环机制。

## 约束变化
触发约束变化包括
* Activating或Deactivating
* 设置constant或priority
* 添加和删除视图

这个Engine遇到约束变化会重新计算layout，获取新值后会call它的superview.setNeedsLayout()

## Deferred Layout Pass
在这个时候主要是做些容错处理，更新约束有些没有确定或者缺失布局声明的视图会在这里处理。接着从上而下调用layoutSubviews()来确定视图各个子视图的位置，这个过程实际上就是将subview的frame从layout engine里拷贝出来。这里要注意重写layoutSubviews()或者执行类似layoutIfNeeded这样可能会立刻唤起layoutSubviews()的方法，如果要这样做需要注意手动处理的这个地方自己的子视图布局的树状关系是否合理。

## 生命周期中需要注意的事项
* 不要期望frame会立刻变化。
* 在重写layoutSubviews()时需要非常小心。

# 约束
Auto Layout你的视图层级里所有视图通过放置在它们里面的约束来动态计算的它们的大小和位置。一般控件需要四个约束决定位置大小，如果定义了intrinsicContentSize的比如UILabel只需要两个约束即可。

## 约束方程式
view1.attribute1 = mutiplier * view2.attribute2 + constant

```objectivec
redButton.left = 1.0 * yellowLabel.right + 10.0 //红色按钮的左侧距离黄色label有10个point
```

## 使用API添加约束
使用NSLayoutConstraint类（最低支持iOS6）添加约束。NSLayoutConstraint官方参考：<https://developer.apple.com/library/prerelease/ios/documentation/AppKit/Reference/NSLayoutConstraint_Class/index.html>
```objectivec
[NSLayoutContraint constraintWithItem:view1
                                                 attribute:NSLayoutAttributeBottom
                                               relatedBy:NSLayoutRelationEqual
                                                    toItem:view2
                                                 attribute:NSLayoutAttributeBottom
                                                multiplier:1.0
                                                 constant:-5]
```
把约束用约束中两个view的共同父视图或者两视图中层次高视图的- (void)addConstraint:(NSLayoutConstraint *)constraint方法将约束添加进去。

## 使用VFL语言添加约束
先举个简单的例子并排两个view添加约束
```objectivec
[NSLayoutConstraint constraintWithVisualFormat:@“[view1]-[view2]"
                                                                  options:0
                                                                  metrics:nil
                                                                     views:viewsDictionary;
```

viewDictionary可以通过NSDictionaryOfVariableBindings方法得到

```objectivec
UIView *view1 = [[UIView alloc] init];
UIView *view2 = [[UIView alloc] init];
viewsDictionary = NSDictionaryOfVariableBindings(view1,view2);
```

### options
可以给这个位掩码传入NSLayoutFormatAlignAllTop使它们顶部对齐，这个值的默认值是NSLayoutFormatDirectionLeadingToTrailing从左到右。可以使用NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom 表示两个视图的顶部和底部约束相同。

### metrics
这个参数作用是替换VFL语句中对应的值
```objectivec
CGRect viewFrame = CGRectMake(50, 50, 100, 100);
NSDictionary *views = NSDictionaryOfVariableBindings(view1, view2);
NSDictionary *metrics = @{@"left": @(CGRectGetMinX(viewFrame)),
                                           @"top": @(CGRectGetMinY(viewFrame)),
                                        @"width": @(CGRectGetWidth(viewFrame)),
                                       @"height": @(CGRectGetHeight(viewFrame))};
[view1 addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[view(>=width)]" options:0 metrics:metrics views:views]];
```
使用NSDictionaryOfVariableBindings(...)快速创建
```objectivec
NSNumber *left = @50;
NSNumber *top = @50;
NSNumber *width = @100;
NSNumber *height = @100;

NSDictionary *views = NSDictionaryOfVariableBindings(view1, view2);
NSDictionary *metrics = NSDictionaryOfVariableBindings(left, top, width, height);

[view1 addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[view(>=width)]" options:0 metrics:metrics views:views]];
```

### VFL几个基本例子
* [view1(50)]-10-[view2(100)] 表示view1宽50，view2宽100，间隔10
* [view1(>=50@750)] 表示view1宽度大于50，约束条件优先级为750（优先级越大优先执行该约束，最大1000）
* V:[view1][view2(==view1)] 表示按照竖直排，上面是view1下面是一个和它一样大的view2
* H:|-[view1]-[view2]-[view3(>=20)]-| 表示按照水平排列，|表示父视图，各个视图之间按照默认宽度来排列

## VFL介绍
无论使用哪种方法创建约束都是NSLayoutConstraint类的成员，每个约束都会在一个Objective-C对象中存储y = mx + b规则，然后通过Auto Layout引擎来表达该规则，VFL也不例外。VFL由一个描述布局的文字字符串组成，文本会指出间隔，不等量和优先级。官方对其的介绍：Visual Format Language <https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/AutolayoutPG/VisualFormatLanguage.html>

## VFL的语法
* 标准间隔：[button]-[textField]
* 宽约束：[button(>=50)]
* 与父视图的关系：|-50-[purpleBox]-50-|
* 垂直布局：V:[topField]-10-[bottomField]
* Flush Views：[maroonView][buleView]
* 权重：[button(100@20)]
* 等宽：[button(==button2)]
* Multiple Predicates：[flexibleButton(>=70,<=100)]

### 注意事项
创建这种字符串时需要注意一下几点：
* H:和V:每次都使用一个。
* 视图变量名出现在方括号中，例如[view]。
* 字符串中顺序是按照从顶到底，从左到右
* 视图间隔以数字常量出现，例如-10-。
* |表示父视图

# 使用Auto Layout时需要注意的点
* 注意禁用Autoresizing Masks。对于每个需要使用Auto Layout的视图需要调用setTranslatesAutoresizingMaskIntoConstraints:NO
* VFL语句里不能包含空格和>，<这样的约束
* 布局原理是由外向里布局，最先屏幕尺寸，再一层一层往里决定各个元素大小。
* 删除视图时直接使用removeConstraint和removeConstraints时需要注意这样删除是没法删除视图不支持的约束导致view中还包含着那个约束（使用第三方库时需要特别注意下）。解决这个的办法就是添加约束时用一个局部变量保存下，删除时进行比较删掉和先前那个，还有个办法就是设置标记，constraint.identifier = @“What you want to call”。

# 布局约束规则
表达布局约束的规则可以使用一些简单的数学术语，如下表

| 类型 | 描述 | 值 |
| :------------ |:---------------| :-----|
| 属性 | 视图位置 | NSLayoutAttributeLeft, NSLayoutAttributeRight, NSLayoutAttributeTop, NSLayoutAttributeBottom |
| 属性 | 视图前面后面 | NSLayoutAttributeLeading, NSLayoutAttributeTrailing |
| 属性 | 视图的宽度和高度 | NSLayoutAttributeWidth, NSLayoutAttributeHeight |
| 属性 | 视图中心 | NSLayoutAttributeCenterX, NSLayoutAttributeCenterY |
| 属性 | 视图的基线，在视图底部上方放置文字的地方 | NSLayoutAttributeBaseline |
| 属性 | 占位符，在与另一个约束的关系中没有用到某个属性时可以使用占位符 | NSLayoutAttributeNotAnAttribute |
| 关系 | 允许将属性通过等式和不等式相互关联 | NSLayoutRelationLessThanOrEqual, NSLayoutRelationEqual, NSLayoutRelationGreaterThanOrEqual |
| 数学运算 | 每个约束的乘数和相加性常数 | CGFloat值 |

# 约束层级
约束引用两视图时，这两个视图需要属于同一个视图层次结构，对于引用两个视图的约束只有两个情况是允许的。第一种是一个视图是另一个视图的父视图，第二个情况是两个视图在一个窗口下有一个非nil的共同父视图。

# 优先级
哪个约束优先级高会先满足其约束，系统内置优先级枚举值UILayoutPriority
```objectivec
enum {
    UILayoutPriorityRequired = 1000, //默认的优先级，意味着默认约束一旦冲突就会crash
    UILayoutPriorityDefaultHigh = 750,
    UILayoutPriorityDefaultLow = 250,
    UILayoutPriorityFittingSizeLevel = 50,
};
typedef float UILayoutPriority;
```

# IntrinsicContentSize / Compression Resistance Priority / Hugging Priority
具有instrinsic content size的控件，比如UILabel，UIButton，选择控件，进度条和分段等等，可以自己计算自己的大小，比如label设置text和font后大小是可以计算得到的。这时可以通过设置Hugging priority让这些控件不要大于某个设定的值,默认优先级为250。设置Content Compression Resistance就是让控件不要小于某个设定的值，默认优先级为750。加这些值可以当作是加了个额外的约束值来约束宽。

# 布局过程
updateConstraints -> layoutSubViews -> drawRect

## viewDidLayoutSubviews，-layoutSubviews
使用Auto Layout的view会在viewDidLayoutSubviews或－layoutSubview调用super转换成具有正确显示的frame值。

## View的改变会调用哪些方法
* 改变frame.origin不会掉用layoutSubviews
* 改变frame.size会使 superVIew的layoutSubviews调用
* 改变bounds.origin和bounds.size都会调用superView和自己view的layoutSubviews方法

# Auto Layout的Debug
Auto Layout以下几种情况会出错
* Unsatisfiable Layouts：约束冲突，同一时刻约束没法同时满足。系统发现时会先检测那些冲突的约束，然后会一直拆掉冲突的约束再检查布局直到找到合适的布局，最后日志会将冲突的约束和拆掉的约束打印在控制台上。
* Ambiguous Layouts：约束有缺失，比如说位置或者大小没有全指定到。还有种情况就是两个冲突的约束的权重是一样的就会崩。
* Logical Errors：布局中的逻辑错误。
* 不含视图项的约束不合法，每个约束至少需要引用一个视图，不然会崩。在删除视图时一定要注意。
## Debugger
* po [[UIWindow keyWindow] _autolayoutTrace]
## 参考
参考官方文档：<https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/AutolayoutPG/TypesofErrors.html>

# 容易出问题的Bug Case
* 无共同父视图的视图之间相互添加约束会有问题。
* 调用了setNeedsLayout后不能通过frame改变视图和控件
* 为了让在设置了setTranslatesAutoresizingMaskIntoConstraints:NO视图里更改的frame立刻生效而执行了没有标记立刻刷新的layoutIfNeeded的方式是不可取的。

# 实践中碰到的非必现低配置机器崩溃bug分析
## 案例一
一个视图缺少高宽约束，在设置完了约束后执行layoutIfNeeded，然后设置宽高，这种情况在低配机器上可能会出现崩问题。原因在于layoutIfNeeded需要有标记才会立刻调用layoutSubview得到宽高，不然是不会马上调用的。页面第一次显示是会自动标记上需要刷新这个标记的，所以第一次看显示都是看不出问题的，但页面再次调用layoutIfNeeded时是不会立刻执行layoutSubview的（但之前加上setNeedsLayout就会立刻执行），这时改变的宽高值会在上文生命周期中提到的Auto Layout Cycle中的Engine里的Deferred Layout Pass里执行layoutSubview，手动设置的layoutIfNeeded也会执行一遍layoutSubview，但是这个如果发生在Deferred Layout Pass之后就会出现崩的问题，因为当视图设置为setTranslatesAutoresizingMaskIntoConstraints:NO时会严格按照约束->Engine->显示这种流程，如在Deferred Layout Pass之前设置好是没有问题的，之后强制执行LayoutSubview会产生一个权重和先前一样的约束在类似动画block里更新布局让Engine执行导致Ambiguous Layouts这种权重相同冲突崩溃的情况发生。

## 案例二
将多个有相互约束关系视图removeFromSuperView后更新布局在低配机器上出现崩的问题。这个原因主要是根据不含视图项的约束不合法这个原则来的，同时会抛出野指针的错误。在内存吃紧机器上，当应用占内存较多系统会抓住任何可以释放heap区内存的机会视图被移除后会立刻被清空，这时约束如果还没有被释就满足不含视图项的约束会崩的情况了。

# 推荐Auto Layout第三方库
## Masonry
Github地址：<https://github.com/SnapKit/Masonry>

## Cartography
Github地址：<https://github.com/robb/Cartography>

# Masonry
可以参看我上篇文章《AutoLayout框架Masonry使用心得》:<http://www.starming.com/index.php?v=index&view=81>

# 各版本iOS中AutoLayout的区别
完整记录可以到官方网站进行核对和查找：What’s New in iOS <https://developer.apple.com/library/ios/releasenotes/General/WhatsNewIniOS/Introduction/Introduction.html>
## iOS6
苹果在这个版本引入Auto Layout，具备了所有核心功能。

## iOS7
* NavigationBar,TabBar和ToolBar的translucent属性默认为YES，当前ViewController的高度是整个屏幕的高度，为了确保不被这些Bar覆盖可以在布局中使用topLayoutGuide和bottomLayoutGuide属性。

```objectivec
[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-[view1]" options:0 metrics:nil views:view2];
```

## iOS8
* Self Sizing Cells http://www.appcoda.com/self-sizing-cells/
* UIViewController新增两个方法，用来处理UITraitEnvironment协议，UIKit里有UIScreen，UIViewController，UIView和UIPresentationController支持这个协议，当视图traitCollection改变时UIViewController时可以捕获到这个消息进行处理的。

```objectivec
- (void)setOverrideTraitCollection:(UITraitCollection *)collection forChildViewController:(UIViewController *)childViewController NS_AVAILABLE_IOS(8_0);
- (UITraitCollection *)overrideTraitCollectionForChildViewController:(UIViewController *)childViewController NS_AVAILABLE_IOS(8_0);
```

* Size Class的出现UIViewController提供了一组新协议来支持UIContentContainer

```objectivec
- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(id )container NS_AVAILABLE_IOS(8_0);
- (CGSize)sizeForChildContentContainer:(id )container withParentContainerSize:(CGSize)parentSize NS_AVAILABLE_IOS(8_0);
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id )coordinator NS_AVAILABLE_IOS(8_0);
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id )coordinator NS_AVAILABLE_IOS(8_0);
```

* UIView的Margin新增了3个API，NSLayoutMargins可以定义view之间的距离，这个只对Auto Layout有效，并且默认值为{8,8,8,8}。NSLayoutAttribute的枚举值也有相应的更新

```objectivec
//UIView的3个Margin相关API
@property (nonatomic) UIEdgeInsets layoutMargins NS_AVAILABLE_IOS(8_0);
@property (nonatomic) BOOL preservesSuperviewLayoutMargins NS_AVAILABLE_IOS(8_0);
- (void)layoutMarginsDidChange NS_AVAILABLE_IOS(8_0);
//NSLayoutAttribute的枚举值更新
NSLayoutAttributeLeftMargin NS_ENUM_AVAILABLE_IOS(8_0),
NSLayoutAttributeRightMargin NS_ENUM_AVAILABLE_IOS(8_0),
NSLayoutAttributeTopMargin NS_ENUM_AVAILABLE_IOS(8_0),
NSLayoutAttributeBottomMargin NS_ENUM_AVAILABLE_IOS(8_0),
NSLayoutAttributeLeadingMargin NS_ENUM_AVAILABLE_IOS(8_0),
NSLayoutAttributeTrailingMargin NS_ENUM_AVAILABLE_IOS(8_0),
NSLayoutAttributeCenterXWithinMargins NS_ENUM_AVAILABLE_IOS(8_0),
NSLayoutAttributeCenterYWithinMargins NS_ENUM_AVAILABLE_IOS(8_0),
```

## iOS9
### UIStackView
苹果一直希望能够让更多的人来用Auto Layout，除了弄出一个VFL现在又弄出一个不需要约束的方法，使用Stack view使大家使用Auto Layout时不用触碰到约束，官方口号是“Start with Stack View, use constraints as needed”。 更多细节可以查看官方介绍：UIKit Framework Reference  UIStackView Class Reference<https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/AutolayoutPG/AutoLayoutWithoutConstraints.html>

Stack Views ：<https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/AutolayoutPG/LayoutUsingStackViews.html>

Stack View提供了更加简便的自动布局方法比如Alignment的Fill，Leading，Center，Trailing。Distribution的Fill，Fill Equally，Fill Proportionally，Equal Spacing。

如果希望在iOS9之前的系统也能够使用Stack view可以用sunnyxx的FDStackView<https://github.com/forkingdog/FDStackView>，利用运行时替换元素的方法来支持iOS6+系统。

### NSLayoutAnchorAPI
新增这个API能够让约束的声明更加清晰，还能够通过静态类型检查确保约束的正常工作。具体可以查看官方文档<https://developer.apple.com/library/ios/documentation/AppKit/Reference/NSLayoutAnchor_ClassReference/>
```objectivec
NSLayoutConstraint *constraint = [view1.leadingAnchor constraintEqualToAnchor:view2.topAnchor];
```

# 参考
## 官方文档
* Auto Layout Guide <https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/AutolayoutPG/index.html>
* UIScrollView And Autolayout <https://developer.apple.com/library/ios/technotes/tn2154/_index.html>
* IB中使用Auto Layout：Auto Layout Help <https://developer.apple.com/library/ios/recipes/xcode_help-IB_auto_layout/_index.html>
* What’s New in iOS <https://developer.apple.com/library/ios/releasenotes/General/WhatsNewIniOS/Introduction/Introduction.html>

## WWDC视频
* WWDC 2012: Introduction to Auto Layout for iOS and OS X <https://developer.apple.com/videos/wwdc/2012/?id=202>
* WWDC 2012: Introducing Collection Views <https://developer.apple.com/videos/play/wwdc2012-205/>
* WWDC 2012: Advanced Collection Views and Building Custom Layouts <https://developer.apple.com/videos/play/wwdc2012-219>
* WWDC 2012: Best Practices for Mastering Auto Layout <https://developer.apple.com/videos/wwdc/2012/?id=228>
* WWDC 2012: Auto Layout by Example <https://developer.apple.com/videos/wwdc/2012/?id=232>
* WWDC 2013: Interface Builder Core Concepts <https://developer.apple.com/videos/play/wwdc2013-405>
* WWDC 2013: Taking Control of Auto Layout in Xcode 5 <https://developer.apple.com/videos/wwdc/2013/?id=406>
* WWDC 2015: Mysteries of Auto Layout, Part 1 内容包含了Auto Layout更高封装stack view的介绍 <https://developer.apple.com/videos/play/wwdc2015-218/>
* WWDC 2015: Mysteries of Auto Layout, Part 2 包含Auto Layout生命周期和调试Auto Layout的一些方法介绍<https://developer.apple.com/videos/play/wwdc2015-219/>