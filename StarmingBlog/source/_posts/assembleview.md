---
title: 制作一个类似苹果VFL(Visual Format Language)的格式化语言来描述类似UIStackView那种布局思路，并解析生成页面
date: 2016-07-21 21:38:01
tags: [AssembleView, iOS]
categories: Programming
banner_img: https://raw.githubusercontent.com/ming1016/STMAssembleView/master/STMAssembleView/as.png
---
在项目中总是希望页面上各处的文字，颜色，字体大小甚至各个视图控件布局都能够在发版之后能够修改以弥补一些前期考虑不周，或者根据统计数据能够随时进行调整，当然是各个版本都能够统一变化。看到这样的要求后，第一反应是这样的页面只能改成H5，或者尝试使用React Native来应对这种要求。

既然UIStackView已经提供了一种既先进又简洁的布局思路，为何不通过制作一个类似VFL这样的DSL语言来处理布局。这样不就能够通过下发一串DSL字符串的方式来进行内容样式甚至布局的更换，不用跟版，还能使多版本统一。同时在端内直接用这样的DSL语言来写界面不光能够减少代码量易于维护，还能够很直观方便的看出整个界面布局结构。

# AssembleView（组装视图）和PartView（零件视图）
在设计格式化语言之前需要对布局做个统一思想进行管理，在看了WWDC里关于UIStackView的介绍后感觉任何复杂的布局都能够通过这样一种组合排布再组合排布的思路特别适合用格式化语言来描述。于是我想出两个视图概念。

一个是AssembleView组合视图，专门用于对其PartView子视图进行排列，比如说是水平排列还是垂直排列，PartView是按照居中对齐还是居左等对齐方式，各个PartView之间间隔是多少。

PartView决定自己视图类型，内容，无固定大小的可以设置大小，同时AssembleView可以作为PartView被加入另一个AssembleView里进行排列，这样各种设计图都可以在初期通过拆解分成不同的AssembleView和PartView进行组合套组合布局出来。

# 格式化语言
接下来是如何通过格式化语言来描述AssembleView和PartView。“{}”符号里包含的是AssembleView的设置，“[]”符号里是PartView的设置，“()”里是他们的属性设置，“<>”可以将对象带入到设置里。下面举几个例子说明下。完整Demo放到了Github上：<https://github.com/ming1016/STMAssembleView>

## 三个星星水平对齐居中排列
h表示水平排列horizontal，c表示居中center，“[]”PartView会根据顺序依次添加排列，imageName属性能够指定本地图片
![三个星星水平对齐居中排列](https://github.com/ming1016/STMAssembleView/blob/master/STMAssembleView/center.png?raw=true
)
```
{
    hc(padding:30)
    [(imageName:starmingicon)]
    [(imageName:starmingicon)]
    [(imageName:starmingicon)]
}
```

## AssembleView里套作为PartView的AssembleView的复杂情况
color可以指定文字颜色，font指定文字大小
![AssembleView里套作为PartView的AssembleView的复杂情况](https://github.com/ming1016/STMAssembleView/blob/master/STMAssembleView/mid.png?raw=true
)
```
{
    ht(padding:10)
    [avatarImageView(imageName:avatar)]
    [
        {
            vl(padding:10)
            [(text:戴铭,color:AAA0A3)]
            [(text:Starming站长,color:E3DEE0,font:13)]
            [(text:喜欢画画编程和写小说,color:E3DEE0,font:13)]
        }
        (width:210,backColor:FAF8F9,backPaddingHorizontal:10,backPaddingVertical:10,radius:8)
    ]
}
```

## 给PartView设置背景色和按钮
设置背景色使用backColor，背景距离设置的PartView的内容间距通过backPaddingHorizontal属性设置水平间距，backPaddingVertical设置垂直间距，“<>”符号带入的button通过button属性设置。
![给PartView设置背景色和按钮](https://github.com/ming1016/STMAssembleView/blob/master/STMAssembleView/followBt.png?raw=true
)
```
[
    {
        hc(padding:4)
        [(imageName:starmingicon,width:14,height:10)]
        [(text:关注,font:16,color:FFFFFF)]
    }
    (height:36,backColor:AAA0A3,radius:8,backBorderWidth:1,backBorderColor:E3DEE0,backPaddingHorizontal:80,backPaddingVertical:10,button:<clickBt>)
]
```

## AssembleView设置忽略约束的方法
水平排列时，通过ignoreAlignment属性设置忽略left约束，如果是垂直排列设置top忽略。
![AssembleView设置忽略约束的方法](https://github.com/ming1016/STMAssembleView/blob/master/STMAssembleView/des.png?raw=true
)
```
{
    hc(padding:5)
    [(text:STMAssembleView演示,color:E3DEE0,font:13)]
    [(imageName:starmingicon,width:14,height:10,ignoreAlignment:left)]
    [(text:Starming星光社,color:E3DEE0,font:13)]
}
```

## 将前面的视图组合成一个AssembleView
![将前面的视图组合成一个AssembleView](https://github.com/ming1016/STMAssembleView/blob/master/STMAssembleView/as.png?raw=true
)
```
ASS(@"{
    vc(padding:20)
    [%@(height:90)]
    [%@(height:36,backColor:AAA0A3,radius:8,backBorderWidth:1,backBorderColor:E3DEE0,backPaddingHorizontal:80,backPaddingVertical:10,button:<clickBt>)]
    [%@(height:25)]
    [%@(ignoreAlignment:top,isFill:1,height:16)]
}",midStr,followBtStr,centerStr,desStr)
```

## AssembleView的属性
* 当在“{}”里面第一个字母是v表示垂直排列vertical，是h表示水平排列horizontal
* 第二个字母是c表示所有PartView居中对齐center，l表示居左对齐left，r表示居右对齐right，t表示居上对齐top，b表示居下对齐bottom。
* padding：默认各个PartView的间距。

## PartView的属性
如果不希望通过属性生成视图，可以通过在[后直接填入带入对象对应的key，然后再在()里设置属性。

### PartView布局相关属性
* width：UILabel和UIImage这样有固定大小的可以不用设置，会按照固定大小的来。
* height：有固定大小的可以不用设置。
* isFill：垂直排列时会将宽设置为父AssembleView的宽，水平排列时会将高设置为父AssembleView的高。
* padding：设置后会忽略父AssembleView里设置的padding，达到自定义间距的效果。
* partAlignment：可以自定义对齐方向，设置后会忽略父AssembleView里设置的对齐。值可填center，left，right，top，bottom。
* ignoreAlignment：设置忽略的约束方向，在父AssembleView不需要由子PartView决定大小的情况下，可以通过打断某个方向约束来实现拆开排列的效果。值可填center，left，right，top，bottom。

### PartView权重相关属性
* crp：Compression Resistance Priority的设置，根据权重由低到高值可以设置为fit，low，high，required。对应的UILayoutPriority的分别是UILayoutPriorityFittingSizeLevel，UILayoutPriorityDefaultLow，UILayoutPriorityDefaultHigh，UILayoutPriorityRequired。
* minWidth：对应NSLayoutRelationGreaterThanOrEqual，设置一个最小的宽
* maxWidth：对应NSLayoutRelationLessThanOrEqual，设置一个最大的宽

### PartView视图控件相关设置
通过以下属性即可生成对应的UILabel，UIImageView或者UIButton等控件视图，而不用特别指出需要生成哪种控件视图
* text：设置文字内容
* font：设置字体，可以带入一个UIFont，也可以直接设置一个字体大小，解析时会判断类型。
* color：设置颜色，可以带入一个UIColor，也可以直接设置一个十六进制颜色，解析时会判断类型。
* imageName：设置本地图片，值是本地图片名称。
* image：带入一个UIImage。
* imageUrl：设置一个网络图片的url地址，ps:目前需要通过<>来带入一个字符串。

### PartView的通用设置
可以为PartView创建一个底部视图，并设置其样式。也可以添加一个UIButton设置UIControlStateHighlighted时的样式。
* backColor：设置底部视图的颜色，可以带入一个UIColor，也可以直接设置一个十六进制颜色，解析时会判断类型。
* backPaddingHorizontal：设置当前PartView视图距离底部视图top和bottom的间距。
* backPaddingVertical：设置当前PartView视图距离底部视图left和right的间距。
* backBorderColor：设置底部视图边框的颜色，可以带入一个UIColor，也可以直接设置一个十六进制颜色，解析时会判断类型。
* backBorderWidth：设置底部视图边框宽。
* radius：设置底部视图的圆角半径。
* button：带入一个button。
* buttonHighlightColor：设置button在UIControlStateHighlighted时的颜色，默认是透明度0.05的黑色。

# 解析格式化语言
解析过程的第一步采用扫描scanner程序将字符串按照分析符号表将字符流序列收集到有意义的单元中。

第二步将这些单元逐个归类到对应的类别中。比如解析到“()”里内容时就将其归类到对应的AssembleView的属性或者PartView的属性类别中。在归类过程中会出现PartView是AssembleView，这个Assemble里面又有这样作为PartView的AssembleView这样层层套的情况，所以需要采用类似引用计数方式保证在最后一个“}”符号结束时能将整个Assemble递归进行解析。

第三步将各个类别集合转换成对应原生代码从而生成对应的视图布局。

具体实现可以查看STMAssembleView.m文件。Github地址：<https://github.com/ming1016/STMAssembleView>

# 如何生成页面
生成页面需要实现格式化语言对应的原生代码，所有PartView的属性都会存放在STMPartMaker里，包括带入的自定义视图还有用于生成视图控件的属性等。PartView属性设置完成后会在STMPartView这个类中先决定对应的视图控件，并将STMPartMaker里的属性都设置上。实现代码可以查看STMPartView.m里的- (STMPartView *)buildPartView方法。

接下来STMAssembleView会在buildAssembleView时进行布局，具体实现代码可以查看STMAssembleView.m里的- (STMAssembleView *)buildAssembleView方法。
