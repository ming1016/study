---
title: 戴铭的 Swift 小册子
date: 2021-11-23 16:28:18
tags: [iOS, Apple, Swift]
categories: Programming
---

## 背景说明
越来越多同学打算开始用 Swift 来开发了，可很多人以前都没接触过 Swift。这篇和我以前文章不同的是，本篇只是面向 Swift 零基础的同学，内容主要是一些直接可用的小例子，例子可以直接在工程中用或自己调试着看。

记得以前 PHP 有个 chm 的手册，写的很简单，但很全，每个知识点都有例子，社区版每个知识点下面还有留言互动。因此，我弄了个 Swift 的手册，是个 macOS 程序。建议使用我开发的这个 macOS 程序来浏览，使用方法是：
* 从  [GitHub - ming1016/SwiftPamphletApp: 戴铭的 Swift 小册子，一本活的 Swift 手册](https://github.com/ming1016/SwiftPamphletApp)  仓库拉代码。
* 然后在 SwiftPamphletAppConfig.swift 里 gitHubAccessToken 加入你的 GitHub Access Token。GitHub Access Token 在  [Personal Access Tokens](https://github.com/settings/tokens)  这里获取，scope 勾上 repo 和 user。
* 使用Xcode编译生成这个手册程序。Xcode 和 macOS 都需要升到最新版，如果遇到 swift package 下载不下来的情况，参看这个议题来解决：[请问markdownui一直更新不下来是什么原因 · Issue #88 · ming1016/SwiftPamphletApp · GitHub](https://github.com/ming1016/SwiftPamphletApp/issues/88)

截图如下：
![](/uploads/daiming-swift-pamphlet/01.png)
![](/uploads/daiming-swift-pamphlet/02.png)
![](/uploads/daiming-swift-pamphlet/03.png)
![](/uploads/daiming-swift-pamphlet/04.png)
![](/uploads/daiming-swift-pamphlet/05.png)
![](/uploads/daiming-swift-pamphlet/06.png)
![](/uploads/daiming-swift-pamphlet/07.png)

这个程序是Swift写的，按照声明式UI，响应式编程范式开发的，源码也可以看看。与其讲一堆，不如调着试。

下面是文本内容。注：代码中简化变量名是为了能更快速关注到语言用法。

## 语法
### 基础
#### 变量 let, var
变量是可变的，使用var修饰，常量是不可变的，使用let修饰。类、结构体和枚举里的变量是属性。
```swift
var v1:String = "hi" // 标注类型
var v2 = "类型推导"
let l1 = "标题" // 常量
class a {
    let p1 = 3
    var p2: Int {
        p1 * 3
    }
}
```

属性没有set可以省略get，如果有set需加get。变量设置前通过willSet访问到，变量设置后通过didSet访问。

#### 打印 print("")
控制台打印值
```swift
print("hi")
let i = 14
print(i)
print("9月\(i)是小柠檬的生日")
```


#### 注释 //
```swift
// 单行注释
/*
多行注释第一行。
多行注释第二行。
*/ 
// MARK: 会在minimap上展示
// TODO: 待做
// FIXME: 待修复
```

#### 可选 ?, !
可能会是 nil 的变量就是可选变量。当变量为 nil 通过??操作符可以提供一个默认值。
```swift
var o: Int? = nil
let i = o ?? 0
```


#### 闭包
闭包也可以叫做 lambda，是匿名函数，对应 OC 的 block。
```swift
let a1 = [1,3,2].sorted(by: { (l: Int, r: Int) -> Bool in
    return l < r
})
// 如果闭包是唯一的参数并在表达式最后可以使用结尾闭包语法，写法简化为
let a2 = [1,3,2].sorted { (l: Int, r: Int) -> Bool in
    return l < r
}
// 已知类型可以省略
let a3 = [1,3,2].sorted { l, r in
    return l < r
}
// 通过位置来使用闭包的参数，最后简化如下：
let a4 = [1,3,2].sorted { $0 < $1 }
print(a)
```

函数也是闭包的一种，函数的参数也可以是闭包。@escaping 表示逃逸闭包，逃逸闭包是可以在函数返回之后继续调用的。@autoclosure 表示自动闭包，可以用来省略花括号。

#### 函数 func
函数可以作为另一个函数的参数，也可以作为另一个函数的返回。函数是特殊的闭包，在类、结构体和枚举中是方法。
```swift
// 为参数设置默认值
func f1(p: String = "p") -> String {
    "p is \(p)"
}
// 函数作为参数
func f2(fn: (String) -> String, p: String) -> String {
    return fn(p)
}
print(f2(fn:f1, p: "d")) // p is d
// 函数作为返回值
func f3(p: String) -> (String) -> String {
    return f1
}
print(f3(p: "yes")("no")) // p is no
```

函数可以返回多个值，函数是可以嵌套的，也就是函数里内可以定义函数，函数内定义的函数可以访问自己作用域外函数内的变量。inout 表示的是输入输出参数，函数可以在函数内改变输入输出参数。defer 标识的代码块会在函数返回之前执行。

#### 访问控制
在 Xcode 里的 target 就是模块，使用 import 可导入模块。模块内包含源文件，每个源文件里可以有多个类、结构体、枚举和函数等多种类型。访问级别可以通过一些关键字描述，分为如下几种：
* open：在模块外可以调用和继承。
* public：在模块外可调用不可继承，open 只适用类和类成员。
* internal：默认级别，模块内可跨源文件调用，模块外不可调用。
* fileprivate：只能在源文件内访问。
* private：只能在所在的作用域内访问。
重写继承类的成员，可以设置成员比父类的这个成员更高的访问级别。Setter 的级别可以低于对应的 Getter 的级别，比如设置 Setter 访问级别为 private，可以在属性使用 private(set) 来修饰。

### 类型
#### 数字 Int, Float
数字的类型有Int、Float和Double
```swift
// Int
let i1 = 100
let i2 = 22
print(i1 / i2) //四舍五入得4
// Float
let f1: Float = 100.0
let f2: Float = 22.0
print(f1 / f2) // 4.5454545
// Double
let d1: Double = 100.0
let d2: Double = 22.0
print(d1 / d2) // 4.545454545454546
// 字面量
print(Int(0b10101)) // 0b开头是二进制 
print(Int(0x00afff)) // 0x开头是十六进制
print(2.5e4) // 2.5x10^2
print(2_000_000) // 2000000
```

#### 布尔数 Bool
布尔数有 true 和 false 两种值，还有一个能够切换这两个值的 toggle 方法。
```swift
var b = false
b.toggle() // true
b.toggle() // false
```


#### 元组 (a, b, c)
元组里的值类型可以是不同的。元组可以看成是匿名结构体。
```swift
let t1 = (p1: 1, p2: "two", p3: [1,2,3])
print(t1.p1)
print(t1.p3)
// 类型推导
let t2 = (1, "two", [1,2,3])
// 通过下标访问
print(t2.1) // two
// 分解元组
let (dp1, dp2, _) = t2
print(dp1)
print(dp2)
```


#### 字符串
```swift
let s1 = "Hi! This is a string. Cool?"
/// 转义父\n表示换行。
/// 其它转义字符有 \0 空字符)、\t 水平制表符 、\n 换行符、\r 回车符
let s2 = "Hi!\nThis is a string. Cool?"
// 多行
let s3 = """
Hi!
This is a string.
Cool?
"""
// 长度
print(s3.count)
print(s3.isEmpty)
// 拼接
print(s3 + "\nSure!")
// 字符串中插入变量
let i = 1
print("Today is good day, double \(i)\(i)!")
/// 遍历字符串
/// 输出：
/// o
/// n
/// e
for c in "one" {
    print(c)
}
// 查找
print(s3.lowercased().contains("cool")) // true
// 替换
let s4 = "one is two"
let newS4 = s4.replacingOccurrences(of: "two", with: "one")
print(newS4)
// 删除空格和换行
let s5 = " Simple line. \n\n  "
print(s5.trimmingCharacters(in: .whitespacesAndNewlines))
```

Unicode、Character 和 SubString 等内容参见官方字符串文档： [Strings and Characters — The Swift Programming Language (Swift 5.1)](https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html) 

#### 枚举
Swift的枚举有类的一些特性，比如计算属性、实例方法、扩展、遵循协议等等。
```swift
enum E1:String, CaseIterable {
    case e1, e2
}
// 关联值
enum E2 {
    case e1([String])
    case e2(Int)
}
let e1 = E2.e1(["one","two"])
let e2 = E2.e2(3)
switch e1 {
case .e1(let array):
    print(array)
case .e2(let int):
    print(int)
}
print(e2)
// 原始值
print(E1.e1.rawValue)
// 遵循 CaseIterable 协议可迭代
for ie in E1.allCases {
    print("show \(ie)")
}
// 递归枚举
enum RE {
    case v(String)
    indirect case node(l:RE, r:RE)
}
let lNode = RE.v("left")
let rNode = RE.v("right")
let pNode = RE.node(l: lNode, r: rNode)
switch pNode {
case .v(let string):
    print(string)
case .node(let l, let r):
    print(l,r)
    switch l {
    case .v(let string):
        print(string)
    case .node(let l, let r):
        print(l, r)
    }
    switch r {
    case .v(let string):
        print(string)
    case .node(let l, let r):
        print(l, r)
    }
}
```


#### 泛型
泛型可以减少重复代码，是一种抽象的表达方式。where 关键字可以对泛型做约束。
```swift
func fn<T>(p: T) -> [T] {
    var r = [T]()
    r.append(p)
    return r
}
print(fn(p: "one"))
// 结构体
struct S1<T> {
    var arr = [T]()
    mutating func add(_ p: T) {
        arr.append(p)
    }
}
var s = S1(arr: ["zero"])
s.add("one")
s.add("two")
print(s.arr) // ["zero", "one", "two"]
```

关联类型
```swift
protocol pc {
    associatedtype T
    mutating func add(_ p: T)
}
struct S2: pc {
    typealias T = String // 类型推导，可省略
    var strs = [String]()
    mutating func add(_ p: String) {
        strs.append(p)
    }
}
```


#### 不透明类型
不透明类型会隐藏类型，让使用者更关注功能。不透明类型和协议很类似，不同的是不透明比协议限定的要多，协议能够对应更多类型。
```swift
protocol P {
    func f() -> String
}
struct S1: P {
    func f() -> String {
        return "one\n"
    }
}
struct S2<T: P>: P {
    var p: T
    func f() -> String {
        return p.f() + "two\n"
    }
}
struct S3<T1: P, T2: P>: P {
    var p1: T1
    var p2: T2
    func f() -> String {
        return p1.f() + p2.f() + "three\n"
    }
}
func someP() -> some P {
    return S3(p1: S1(), p2: S2(p: S1()))
}
let r = someP()
print(r.f())
```


#### 类型转换
使用 is 关键字进行类型判断， 使用 as 关键字来转换成子类。
```swift
class S0 {}
class S1: S0 {}
class S2: S0 {}
var a = [S0]()
a.append(S1())
a.append(S2())
for e in a {
    // 类型判断
    if e is S1 {
        print("Type is S1")
    } else if e is S2 {
        print("Type is S2")
    }
    // 使用 as 关键字转换成子类
    if let s1 = e as? S1 {
        print("As S1 \(s1)")
    } else if let s2 = e as? S2 {
        print("As S2 \(s2)")
    }
}
```


### 类和结构体
#### 类
类可以定义属性、方法、构造器、下标操作。类使用扩展来扩展功能，遵循协议。类还以继承，运行时检查实例类型。
```swift
class C {
     var p: String
     init(_ p: String) {
         self.p = p
     }
     // 下标操作
     subscript(s: String) -> String {
         get {
             return p + s
         }
         set {
             p = s + newValue
         }
     }
 }
 let c = C("hi")
 print(c.p)
 print(c[" ming"])
 c["k"] = "v"
 print(c.p)
```

#### 结构体
结构体是值类型，可以定义属性、方法、构造器、下标操作。结构体使用扩展来扩展功能，遵循协议。
```swift
struct S {
    var p1: String = ""
    var p2: Int
}
extension S {
    func f() -> String {
        return p1 + String(p2)
    }
}
var s = S(p2: 1)
s.p1 = "1"
print(s.f()) // 11
```


#### 属性
类、结构体或枚举里的变量常量就是他们的属性。
```swift
struct S {
    static let sp = "类型属性" // 类型属性通过类型本身访问，非实例访问
    var p1: String = ""
    var p2: Int = 1
    // cp 是计算属性
    var cp: Int {
        get {
            return p2 * 2
        }
        set {
            p2 = newValue + 2
        }
    }
    // 只有 getter 的是只读计算属性
    var rcp: Int {
        p2 * 4
    }
}
print(S.sp)
print(S().cp) // 2
var s = S()
s.cp = 3
print(s.p2) // 5
print(S().rcp) // 4
```

willSet 和 didSet 是属性观察器，可以在属性值设置前后插入自己的逻辑处理。

#### 方法
```swift
enum E: String {
    case one, two, three
    func showRawValue() {
        print(rawValue)
    }
}
let e = E.three
e.showRawValue() // three
// 可变的实例方法，使用 mutating 标记
struct S {
    var p: String
    mutating func addFullStopForP() {
        p += "."
    }
}
var s = S(p: "hi")
s.addFullStopForP()
print(s.p)
// 类方法
class C {
    class func cf() {
        print("类方法")
    }
}
```

static和class关键字修饰的方法类似 OC 的类方法。static 可以修饰存储属性，而 class 不能；class 修饰的方法可以继承，而 static 不能。在协议中需用 static 来修饰。

#### 继承
类能继承另一个类，继承它的方法、属性等。
```swift
// 类继承
class C1 {
    var p1: String
    var cp1: String {
        get {
            return p1 + " like ATM"
        }
        set {
            p1 = p1 + newValue
        }
    }
    init(p1: String) {
        self.p1 = p1
    }
    func sayHi() {
        print("Hi! \(p1)")
    }
}
class C2: C1 {
    var p2: String
    init(p2: String) {
        self.p2 = p2
        super.init(p1: p2 + "'s father")
    }
}
C2(p2: "Lemon").sayHi() // Hi! Lemon's father
// 重写父类方法
class C3: C2 {
    override func sayHi() {
        print("Hi! \(p2)")
    }
}
C3(p2: "Lemon").sayHi() // Hi! Lemon
// 重写计算属性
class C4: C1 {
    override var cp1: String {
        get {
            return p1 + " like Out of the blade"
        }
        set {
            p1 = p1 + newValue
        }
    }
}
print(C1(p1: "Lemon").cp1)### // Lemon like ATM
print(C4(p1: "Lemon").cp1)### // Lemon like
Out of the blade
```

通过 final 关键字可以防止类被继承，final 还可以用于属性和方法。使用 super 关键字指代父类。

### 函数式
#### map
map 可以依次处理数组中元素，并返回一个处理后的新数组。
```swift
let a1 = ["a", "b", "c"]
let a2 = a1.map {
    "\($0)2"
}
print(a2) // ["a2", "b2", "c2"]
```

使用 compactMap 可以过滤 nil 的元素。flatMap 会将多个数组合成一个数组返回。

#### filter
根据指定条件返回
```swift
let a1 = ["a", "b", "c", "call my name"]
let a2 = a1.filter {
    $0.prefix(1) == "c"
}
print(a2) // ["c", "call my name"]
```

#### reduce
reduce 可以将迭代中返回的结果用于下个迭代中，并，还能让你设个初始值。
```swift
let a1 = ["a", "b", "c", "call my name.", "get it?"]
let a2 = a1.reduce("Hey u,", { partialResult, s in
    // partialResult 是前面返回的值，s 是遍历到当前的值
    partialResult + " \(s)"
})
print(a2) // Hey u, a b c call my name. get it?
```

#### sorted
排序
```swift
// 类型遵循 Comparable
let a1 = ["a", "b", "c", "call my name.", "get it?"]
let a2 = a1.sorted()
let a3 = a1.sorted(by: >)
let a4 = a1.sorted(by: <)
print(a2) // a b c call my name. get it?
print(a3) // ["get it?", "call my name.", "c", "b", "a"]
print(a4) // ["a", "b", "c", "call my name.", "get it?"]
// 类型不遵循 Comparable
struct S {
    var s: String
    var i: Int
}
let a5 = [S(s: "a", i: 0), S(s: "b", i: 1), S(s: "c", i: 2)]
let a6 = a5
    .sorted { l, r in
        l.i > r.i
    }
    .map {
        $0.i
    }
print(a6) // [2, 1, 0]
```


### 控制流

#### If * If let * If case let
```swift
// if
let s = "hi"
if s.isEmpty {
    print("String is Empty")
} else {
    print("String is \(s)")
}
// 三元条件
s.isEmpty ? print("String is Empty again") : print("String is \(s) again")
// if let-else
func f(s: String?) {
    if let s1 = s {
        print("s1 is \(s1)")
    } else {
        print("s1 is nothing")
    }
    // nil-coalescing
    let s2 = s ?? "nothing"
    print("s2 is \(s2)")
}
f(s: "something")
f(s: nil)
// if case let
enum E {
    case c1(String)
    case c2([String])
    func des() {
        switch self {
        case .c1(let string):
            print(string)
        case .c2(let array):
            print(array)
        }
    }
}
E.c1("enum c1").des()
E.c2(["one", "two", "three"]).des()
```


#### Guard guard, guard let
更好地处理异常情况
```swift
// guard
func f1(p: String) -> String {
    guard p.isEmpty != true else {
        return "Empty string."
    }
    return "String \(p) is not empty."
}
print(f1(p: "")) // Empty string.
print(f1(p: "lemon")) // String lemon is not empty.
// guard let
func f2(p1: String?) -> String {
    guard let p2 = p1 else {
        return "Nil."
    }
    return "String \(p2) is not nil."
}
print(f2(p1: nil)) // Nil.
print(f2(p1: "lemon")) // String lemon is not nil.
```


#### For-in
```swift
let a = ["one", "two", "three"]
for str in a {
    print(str)
}
// 使用下标范围
for i in 0..<10 {
    print(i)
}
// 使用 enumerated
for (i, str) in a.enumerated() {
    print("第\(i + 1)个是:\(str)")
}
// for in where
for str in a where str.prefix(1) == "t" {
    print(str)
}
// 字典 for in，遍历是无序的
et dic = [
    "one": 1,
    "two": 2,
    "three": 3
]
for (k, v) in dic {
    print("key is \(k), value is \(v)")
}
// stride
for i in stride(from: 10, through: 0, by: -2) {
    print(i)
}
/*
 10
 8
 6
 4
 2
 0
 */
```


#### While while, repeat-while
```swift
// while
var i1 = 10
while i1 > 0 {
    print("positive even number \(i1)")
    i1 -= 2
}
// repeat while
var i2 = 10
repeat {
    print("positive even number \(i2)")
    i2 -= 2
} while i2 > 0
```

使用 break 结束遍历，使用 continue 跳过当前作用域，继续下个循环

#### Switch
```swift
func f1(pa: String, t:(String, Int)) {
    var p1 = 0
    var p2 = 10
    switch pa {
    case "one":
        p1 = 1
    case "two":
        p1 = 2
        fallthrough // 继续到下个 case 中
    default:
        p2 = 0
    }
    print("p1 is \(p1)")
    print("p2 is \(p2)")
    // 元组
    switch t {
    case ("0", 0):
        print("zero")
    case ("1", 1):
        print("one")
    default:
        print("no")
    }
}
f1(pa: "two", t:("1", 1))
/*
 p1 is 2
 p2 is 0
 one
 */
// 枚举
enum E {
    case one, two, three, unknown(String)
}
func f2(pa: E) {
    var p: String
    switch pa {
    case .one:
        p = "1"
    case .two:
        p = "2"
    case .three:
        p = "3"
    case let .unknown(u) where Int(u) ?? 0 > 0 : // 枚举关联值，使用 where 增加条件
        p = u
    case .unknown(_):
        p = "negative number"
    }
    print(p)
}
f2(pa: E.one) // 1
f2(pa: E.unknown("10")) // 10
f2(pa: E.unknown("-10")) // negative number
```


### 集合
#### 数组 [1, 2, 3]
数组是有序集合
```swift
var a0: [Int] = [1, 10]
a0.append(2)
a0.remove(at: 0)
print(a0) // [10, 2]
let a1 = ["one", "two", "three"]
let a2 = ["three", "four"]
// 找两个集合的不同
let dif = a1.difference(from: a2) // swift的 diffing 算法在这 http://www.xmailserver.org/diff2.pdf swift实现在  swift/stdlib/public/core/Diffing.swift
for c in dif {
    switch c {
    case .remove(let o, let e, let a):
        print("offset:\(o), element:\(e), associatedWith:\(String(describing: a))")
    case .insert(let o, let e, let a):
        print("offset:\(o), element:\(e), associatedWith:\(String(describing: a))")
    }
}
/*
 remove offset:1, element:four, associatedWith:nil
 insert offset:0, element:one, associatedWith:nil
 insert offset:1, element:two, associatedWith:nil
 */
let a3 = a2.applying(dif) ?? [] // 可以用于添加删除动画
print(a3) // ["one", "two", "three"]
```


#### Sets Set<Int>
Set 是无序集合，元素唯一
```swift
let s0: Set<Int> = [2, 4]
let s1: Set = [2, 10, 6, 4, 8]
let s2: Set = [7, 3, 5, 1, 9, 10]
let s3 = s1.union(s2) // 合集
let s4 = s1.intersection(s2) // 交集
let s5 = s1.subtracting(s2) // 非交集部分
let s6 = s1.symmetricDifference(s2) // 非交集的合集
print(s3) // [4, 2, 1, 7, 3, 10, 8, 9, 6, 5]
print(s4) // [10]
print(s5) // [8, 4, 2, 6]
print(s6) // [9, 1, 3, 4, 5, 2, 6, 8, 7]
// s0 是否被 s1 包含
print(s0.isSubset(of: s1)) // true
// s1 是否包含了 s0
print(s1.isSuperset(of: s0)) // true
let s7: Set = [3, 5]
// s0 和 s7 是否有交集
print(s0.isDisjoint(with: s7)) // true
// 可变 Set
var s8: Set = ["one", "two"]
s8.insert("three")
s8.remove("one")
print(s8) // ["two", "three"]
```


#### 字典 [:]
字典是无序集合，键值对应。
```swift
var d = [
    "k1": "v1",
    "k2": "v2"
]
d["k3"] = "v3"
d["k4"] = nil
print(d) // ["k2": "v2", "k3": "v3", "k1": "v1"]
for (k, v) in d {
    print("key is \(k), value is \(v)")
}
/*
 key is k1, value is v1
 key is k2, value is v2
 key is k3, value is v3
 */
if d.isEmpty == false {
    print(d.count) // 3
}
```


### 操作符

#### 赋值 =, +=. -=, *=, /=
```swift
let i1 = 1
var i2 = i1
i2 = 2
print(i2) // 2
i2 += 1
print(i2) // 3
i2 -= 2
print(i2) // 1
i2 *= 10
print(i2) // 10
i2 /= 2
print(i2) // 5
```


#### 计算符 +, -, *, /, %
```swift
let i1 = 1
let i2 = i1
print((i1 + i2 - 1) * 10 / 2 % 3) // 2
print("i" + "1") // i1
// 一元运算符
print(-i1) // -1
```


#### 比较运算符 ==, >
遵循 Equatable 协议可以使用 == 和 != 来判断是否相等
```swift
print(1 > 2) // false
struct S: Equatable {
    var p1: String
    var p2: Int
}
let s1 = S(p1: "one", p2: 1)
let s2 = S(p1: "two", p2: 2)
let s3 = S(p1: "one", p2: 2)
let s4 = S(p1: "one", p2: 1)
print(s1 == s2) // false
print(s1 == s3) // false
print(s1 == s4) // true

```
类需要实现 == 函数
```swift
class C: Equatable {
    var p1: String
    var p2: Int
    init(p1: String, p2: Int) {
        self.p1 = p1
        self.p2 = p2
    }
    static func == (l: C, r: C) -> Bool {
        return l.p1 == r.p1 && l.p2 == r.p2
    }
}
let c1 = C(p1: "one", p2: 1)
let c2 = C(p1: "one", p2: 1)
print(c1 == c2)
```


#### 三元 _ ? _ : _
简化 if else 写法
```swift
// if else
func f1(p: Int) {
    if p > 0 {
        print("positive number")
    } else {
        print("negative number")
    }
}
// 三元
func f2(p: Int) {
    p > 0 ? print("positive number") : print("negative number")
}
f1(p: 1)
f2(p: 1)
```


#### Nil-coalescing ??
简化 if let else 写法
```swift
// if else
func f1(p: Int?) {
    if let i = p {
        print("p have value is \(i)")
    } else {
        print("p is nil, use defalut value")
    }
}
// 使用 ??
func f2(p: Int?) {
    let i = p ?? 0
    print("p is \(i)")
}
```


#### 范围 a…b
简化的值范围表达方式。
```swift
// 封闭范围
for i in 0...10 {
    print(i)
}
// 半开范围
for i in 0..<10 {
    print(i)
}
```


#### 逻辑 !, &&, !!
```swift
let i1 = -1
let i2 = 2
if i1 != i2 && (i1 < 0 || i2 < 0) {
    print("i1 and i2 not equal, and one of them is negative number.")
}
```


#### 恒等 ===, !==
恒等返回是否引用了相同实例。
```swift
class C {
    var p: String
    init(p: String) {
        self.p = p
    }
}
let c1 = C(p: "one")let c2 = C(p: "one")let c3 = c1
print(c1 === c2) // false
print(c1 === c3) // true
print(c1 !== c2) // true
```


#### 运算符
位运算符
```swift
let i1: UInt8 = 0b00001111
let i2 = ~i1 // Bitwise NOT Operator（按位取反运算符），取反

let i3: UInt8 = 0b00111111
let i4 = i1 & i3 // Bitwise AND Operator（按位与运算符），都为1才是1
let i5 = i1 | i3 // Bitwise OR Operator（按位或运算符），有一个1就是1
let i6 = i1 ^ i3 // Bitwise XOR Operator（按位异或运算符），不同为1，相同为0

print(i1,i2,i3,i4,i5,i6)
// << 按位左移，>> 按位右移
let i7 = i1 << 1
let i8 = i1 >> 2
print(i7,i8)
```

溢出运算符，有 &+、&- 和 &*

```swift
var i1 = Int.max
print(i1) // 9223372036854775807
i1 = i1 &+ 1
print(i1) // -9223372036854775808
i1 = i1 &+ 10
print(i1) // -9223372036854775798

var i2 = UInt.max
i2 = i2 &+ 1
print(i2) // 0
```


运算符函数包括前缀运算符、后缀运算符、复合赋值运算符以及等价运算符。另，还可以自定义运算符，新的运算符要用 operator 关键字进行定义，同时要指定 prefix、infix 或者 postfix 修饰符。


## 特性

### 模式
#### 单例模式
```swift
struct S {
    static let shared = S()
    private init() {
        // 防止实例初始化
    }
}
```


### 系统
#### 版本兼容
```swift
// 版本
@available(iOS 15, *)
func f() {
}
// 版本检查
if #available(iOS 15, macOS 12, *) {
    f()
} else {
    // nothing happen
}
```


### Codable

#### JSON 没有 id 字段
如果SwiftUI要求数据Model都是遵循Identifiable协议的，而有的json没有id这个字段，可以使用扩展struct的方式解决：
```swift
struct
CommitModel: Decodable, Hashable {
	var sha: String
	var author: AuthorModel
	var commit: CommitModel
}
extension CommitModel: Identifiable {
	var id: String {
		return sha
  }
}
```



## 编程范式
### Combine响应式编程范式
#### 介绍
WWDC 2019苹果推出Combine，Combine是一种响应式编程范式，采用声明式的Swift API。官方文档链接  [Combine | Apple Developer Documentation](https://developer.apple.com/documentation/combine) 。还有  [Using Combine](https://heckj.github.io/swiftui-notes/)  这里有大量使用示例，内容较全。官方讨论Combine的论坛  [Topics tagged combine](https://forums.swift.org/tag/combine) 。StackOverflow上相关问题  [Newest 'combine' Questions](https://stackoverflow.com/questions/tagged/combine) 。

WWDC上关于Combine的Session如下：
*  [Introducing Combine](https://developer.apple.com/videos/play/wwdc2019/722/) 
*  [Combine in Practice](https://developer.apple.com/videos/play/wwdc2019/721/) 

和Combine相关的Session：
*  [Modern Swift API Design](https://developer.apple.com/videos/play/wwdc2019/415/) 
*  [Data Flow Through SwiftUI](https://developer.apple.com/videos/play/wwdc2019/226) 
*  [Introducing Combine and Advances in Foundation](https://developer.apple.com/videos/play/wwdc2019/711) 
*  [Advances in Networking, Part 1](https://developer.apple.com/videos/play/wwdc2019/712/) 
*  [Building Collaborative AR Experiences](https://developer.apple.com/videos/play/wwdc2019/610/) 
*  [Expanding the Sensory Experience with Core Haptics](https://developer.apple.com/videos/play/wwdc2019/223/) 

也就是你写代码不同于以往命令式的描述如何处理数据，而是要去描述好数据会经过哪些逻辑运算处理。这样代码更好维护，可以有效的减少嵌套闭包以及分散的回调等使得代码维护麻烦的苦恼。

声明式和过程时区别可见如下代码：
```swift
// 所有数相加
// 命令式思维
func sum1(arr: [Int]) -> Int {
  var sum: Int = 0
  for v in arr {
    sum += v
  }
  return sum
}

// 声明式思维
func sum2(arr: [Int]) -> Int {
  return arr.reduce(0, +)
}
```

Combine主要用来处理异步的事件和值。苹果UI框架都是在主线程上进行UI更新，Combine通过Publisher的receive设置回主线程更新UI会非常的简单。

已有的RxSwift和ReactiveSwift框架和Combine的思路和用法类似。

Combine 的三个核心概念
* 发布者
* 订阅者
* 操作符

简单举个发布数据和类属性绑定的例子：
```swift
let pA = Just(0)
let _ = pA.sink { v in
    print("pA is: \(v)")
}

let pB = [7,90,16,11].publisher
let _ = pB
    .sink { v in
        print("pB: \(v)")
    }

class AClass {
    var p: Int = 0 {
        didSet {
            print("property update to \(p)")
        }
    }
}
let o = AClass()
let _ = pB.assign(to: \.p, on: o)
```


#### 使用场景
##### 网络请求
网络URLSession.dataTaskPublisher使用例子如下：
```swift
let req = URLRequest(url: URL(string: "http://www.starming.com")!)
let dpPublisher = URLSession.shared.dataTaskPublisher(for: req)
```


一个请求Github接口并展示结果的例子
```swift
//
// CombineSearchAPI.swift
// SwiftOnly (iOS)
//
// Created by Ming Dai on 2021/11/4.
//

import SwiftUI
import Combine

struct CombineSearchAPI: View {
  var body: some View {
    GithubSearchView()
  }
}

// MARK: Github View
struct GithubSearchView: View {
  @State var str: String = "Swift"
  @StateObject var ss: SearchStore = SearchStore()
  @State var repos: [GithubRepo] = []
  var body: some View {
    NavigationView {
      List {
        TextField("输入：", text: $str, onCommit: fetch)
        ForEach(self.ss.repos) { repo -> GithubRepoCell in
          GithubRepoCell(repo: repo)
        }
      }
      .navigationTitle("搜索")
    }
    .onAppear(perform: fetch)
  }
   
  private func fetch() {
    self.ss.search(str: self.str)
  }
}

struct GithubRepoCell: View {
  let repo: GithubRepo
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(self.repo.name)
      Text(self.repo.description)
    }
  }
}

// MARK: Github Service
struct GithubRepo: Decodable, Identifiable {
  let id: Int
  let name: String
  let description: String
}

struct GithubResp: Decodable {
  let items: [GithubRepo]
}

final class GithubSearchManager {
  func search(str: String) -> AnyPublisher<GithubResp, Never> {
    guard var urlComponents = URLComponents(string: "https://api.github.com/search/repositories") else {
      preconditionFailure("链接无效")
    }
    urlComponents.queryItems = [URLQueryItem(name: "q", value: str)]
     
    guard let url = urlComponents.url else {
      preconditionFailure("链接无效")
    }
    let sch = DispatchQueue(label: "API", qos: .default, attributes: .concurrent)
     
    return URLSession.shared
      .dataTaskPublisher(for: url)
      .receive(on: sch)
      .tryMap({ element -> Data in
        print(String(decoding: element.data, as: UTF8.self))
        return element.data
      })
      .decode(type: GithubResp.self, decoder: JSONDecoder())
      .catch { _ in
        Empty().eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}

final class SearchStore: ObservableObject {
  @Published var query: String = ""
  @Published var repos: [GithubRepo] = []
  private let searchManager: GithubSearchManager
  private var cancellable = Set<AnyCancellable>()
   
  init(searchManager: GithubSearchManager = GithubSearchManager()) {
    self.searchManager = searchManager
    $query
      .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
      .flatMap { query -> AnyPublisher<[GithubRepo], Never> in
        return searchManager.search(str: query)
          .map {
            $0.items
          }
          .eraseToAnyPublisher()
      }
      .receive(on: DispatchQueue.main)
      .assign(to: \.repos, on: self)
      .store(in: &cancellable)
  }
  func search(str: String) {
    self.query = str
  }
}
```

抽象基础网络能力，方便扩展，代码如下：
```swift
//
// CombineAPI.swift
// SwiftOnly (iOS)
//
// Created by Ming Dai on 2021/11/4.
//

import SwiftUI
import Combine

struct CombineAPI: View {
  var body: some View {
    RepListView(vm: .init())
  }
}

struct RepListView: View {
  @ObservedObject var vm: RepListVM
   
  var body: some View {
    NavigationView {
      List(vm.repos) { rep in
        RepListCell(rep: rep)
      }
      .alert(isPresented: $vm.isErrorShow) { () -> Alert in
        Alert(title: Text("出错了"), message: Text(vm.errorMessage))
      }
      .navigationBarTitle(Text("仓库"))
    }
    .onAppear {
      vm.apply(.onAppear)
    }
  }
}

struct RepListCell: View {
  @State var rep: RepoModel
  var body: some View {
    HStack() {
      VStack() {
        AsyncImage(url: URL(string: rep.owner.avatarUrl ?? ""), content: { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
        },
        placeholder: {
          ProgressView()
            .frame(width: 100, height: 100)
        })
        Text("\(rep.owner.login)")
          .font(.system(size: 10))
      }
      VStack(alignment: .leading, spacing: 10) {
        Text("\(rep.name)")
          .font(.title)
        Text("\(rep.stargazersCount)")
          .font(.title3)
        Text("\(String(describing: rep.description ?? ""))")
        Text("\(String(describing: rep.language ?? ""))")
          .font(.title3)
      }
      .font(.system(size: 14))
    }
     
  }
}


// MARK: Repo View Model
final class RepListVM: ObservableObject, UnidirectionalDataFlowType {
  typealias InputType = Input
  private var cancellables: [AnyCancellable] = []
   
  // Input
  enum Input {
    case onAppear
  }
  func apply(_ input: Input) {
    switch input {
    case .onAppear:
      onAppearSubject.send(())
    }
  }
  private let onAppearSubject = PassthroughSubject<Void, Never>()
   
  // Output
  @Published private(set) var repos: [RepoModel] = []
  @Published var isErrorShow = false
  @Published var errorMessage = ""
  @Published private(set) var shouldShowIcon = false
   
  private let resSubject = PassthroughSubject<SearchRepoModel, Never>()
  private let errSubject = PassthroughSubject<APISevError, Never>()
   
  private let apiSev: APISev
   
  init(apiSev: APISev = APISev()) {
    self.apiSev = apiSev
    bindInputs()
    bindOutputs()
  }
   
  private func bindInputs() {
    let req = SearchRepoRequest()
    let resPublisher = onAppearSubject
      .flatMap { [apiSev] in
        apiSev.response(from: req)
          .catch { [weak self] error -> Empty<SearchRepoModel, Never> in
            self?.errSubject.send(error)
            return .init()
          }
      }
    let resStream = resPublisher
      .share()
      .subscribe(resSubject)
     
    // 其它异步事件，比如日志等操作都可以做成Stream加到下面数组内。
    cancellables += [resStream]
  }
   
  private func bindOutputs() {
    let repStream = resSubject
      .map {
        $0.items
      }
      .assign(to: \.repos, on: self)
    let errMsgStream = errSubject
      .map { error -> String in
        switch error {
        case .resError: return "network error"
        case .parseError: return "parse error"
        }
      }
      .assign(to: \.errorMessage, on: self)
    let errStream = errSubject
      .map { _ in
        true
      }
      .assign(to: \.isErrorShow, on: self)
    cancellables += [repStream,errStream,errMsgStream]
  }
   
}


protocol UnidirectionalDataFlowType {
  associatedtype InputType
  func apply(_ input: InputType)
}

// MARK: Repo Request and Models

struct SearchRepoRequest: APIReqType {
  typealias Res = SearchRepoModel
   
  var path: String {
    return "/search/repositories"
  }
  var qItems: [URLQueryItem]? {
    return [
      .init(name: "q", value: "Combine"),
      .init(name: "order", value: "desc")
    ]
  }
}

struct SearchRepoModel: Decodable {
  var items: [RepoModel]
}

struct RepoModel: Decodable, Hashable, Identifiable {
  var id: Int64
  var name: String
  var fullName: String
  var description: String?
  var stargazersCount: Int = 0
  var language: String?
  var owner: OwnerModel
}

struct OwnerModel: Decodable, Hashable, Identifiable {
  var id: Int64
  var login: String
  var avatarUrl: String?
}


// MARK: API Request Fundation

protocol APIReqType {
  associatedtype Res: Decodable
  var path: String { get }
  var qItems: [URLQueryItem]? { get }
}

protocol APISevType {
  func response<Request>(from req: Request) -> AnyPublisher<Request.Res, APISevError> where Request: APIReqType
}

final class APISev: APISevType {
  private let rootUrl: URL
  init(rootUrl: URL = URL(string: "https://api.github.com")!) {
    self.rootUrl = rootUrl
  }
   
  func response<Request>(from req: Request) -> AnyPublisher<Request.Res, APISevError> where Request : APIReqType {
    let path = URL(string: req.path, relativeTo: rootUrl)!
    var comp = URLComponents(url: path, resolvingAgainstBaseURL: true)!
    comp.queryItems = req.qItems
    print(comp.url?.description ?? "url wrong")
    var req = URLRequest(url: comp.url!)
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
     
    let de = JSONDecoder()
    de.keyDecodingStrategy = .convertFromSnakeCase
    return URLSession.shared.dataTaskPublisher(for: req)
      .map { data, res in
        print(String(decoding: data, as: UTF8.self))
        return data
      }
      .mapError { _ in
        APISevError.resError
      }
      .decode(type: Request.Res.self, decoder: de)
      .mapError(APISevError.parseError)
      .receive(on: RunLoop.main)
      .eraseToAnyPublisher()
  }
}

enum APISevError: Error {
  case resError
  case parseError(Error)
}
```



##### KVO
例子如下：
```swift
private final class KVOObject: NSObject {
  @objc dynamic var intV: Int = 0
  @objc dynamic var boolV: Bool = false
}

let o = KVOObject()
let _ = o.publisher(for: \.intV)
  .sink { v in
    print("value : \(v)")
  }

```

##### 通知
使用例子如下：
```swift
extension Notification.Name {
    static let noti = Notification.Name("nameofnoti")
}

let notiPb = NotificationCenter.default.publisher(for: .noti, object: nil)
        .sink {
            print($0)
        }
```

退到后台接受通知的例子如下：
```swift
class A {
  var storage = Set<AnyCancellable>()
   
  init() {
    NotificationCenter.default.publisher(for: UIWindowScene.didEnterBackgroundNotification)
      .sink { _ in
        print("enter background")
      }
      .store(in: &self.storage)
  }
}
```

##### Timer
使用方式如下：
```swift
let timePb = Timer.publish(every: 1.0, on: RunLoop.main, in: .default)
let timeSk = timePb.sink { r in
    print("r is \(r)")
}
let cPb = timePb.connect()
```

##### SwiftUI
使用方式如下：
```swift
struct aView: View {
  @State private var currentVl = "vl"
  var body: some View {
    Text("string is \(currentVl)")
      .onReceive(currentPublisher) { newVl in
        self.currentVl = newVl
      }
  }
}
```

## 库的选择与使用说明

### 数据库
 [GitHub - stephencelis/SQLite.swift: A type-safe, Swift-language layer over SQLite3.](https://github.com/stephencelis/SQLite.swift) 
 [GitHub - groue/GRDB.swift: A toolkit for SQLite databases, with a focus on application development](https://github.com/groue/GRDB.swift) 

## 代码规范
参考：
*  [Swift Style Guide](https://google.github.io/swift/) 

多用静态特性。swift 在编译期间所做的优化比 OC 要多，这是由于他的静态派发、泛型特化、写时复制这些静态特性决定的。另外通过 final  和 private 这样的表示可将动态特性转化为静态方式，编译开启 WMO 可以自动推导出哪些动态派发可转化为静态派发。

如何避免崩溃？
* 字典：用结构体替代
* Any：可用泛型或关联关联类型替代
* as? ：少用 AnyObject，多用泛型或不透明类型
* !：要少用

好的实践？
* 少用继承，多用 protocol
* 多用 extension 对自己代码进行管理

## 最佳实践

### 开源例子
*  [GitHub - adamayoung/Movies: Movies and TV Shows App for iOS, iPadOS, watchOS and macOS](https://github.com/adamayoung/Movies)  使用了SwiftUI和Combine，电影数据使用的是 [The Movie Database (TMDB)](https://www.themoviedb.org/) 的API

## macoOS
官方提供的两个例子， [Creating a macOS App](https://developer.apple.com/tutorials/swiftui/creating-a-macos-app) ， [Building a Great Mac App with SwiftUI](https://developer.apple.com/documentation/swiftui/building_a_great_mac_app_with_swiftui)  （有table和
LazyVGrid的用法）。

三栏结构架子搭建，代码如下：
```swift
import SwiftUI

struct SwiftPamphletApp: View {
    
    var body: some View {
        NavigationView {
            SPSidebar()
            Text("第二栏")
            Text("第三栏")
        }
        .navigationTitle("Swift 小册子")
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigation) {
                
                Button {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                } label: {
                    Label("Sidebar", systemImage: "sidebar.left")
                }
            }
        }
    }
}

struct SPSidebar: View {
    var body: some View {
        List {
            Section("第一组") {
                NavigationLink("第一项", destination: SPList(title: "列表1"))
                    .badge(3)
                NavigationLink("第二项", destination: SPList(title: "列表2"))
            }
            Section("第二组") {
                NavigationLink("第三项", destination: SPList(title: "列表3"))
                NavigationLink("第四项", destination: SPList(title: "列表4"))
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 160)
        .toolbar {
            ToolbarItem {
                Menu {
                    Text("1")
                    Text("2")
                } label: {
                    Label("Label", systemImage: "slider.horizontal.3")
                }
            }
        }
    }
}

struct SPList: View {
    var title: String
    @State var searchText: String = ""
    
    var body: some View {
        List(0..<3) { i in
            Text("内容\(i)")
        }
        .toolbar(content: {
            Button {
                //
            } label: {
                Label("Add", systemImage: "plus")
            }

        })
        .navigationTitle(title)
        .navigationSubtitle("副标题")
        .searchable(text: $searchText)
    }
}
```

显示效果如下：
![](/uploads/daiming-swift-pamphlet/08.png)

打开浏览器显示指定网页的代码
```swift
NSWorkspace.shared.open(URL(string: "https://github.com/ming1016")!)
```



































