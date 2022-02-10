---
title: 戴铭的 Swift 小册子 4.0
date: 2021-11-23 16:28:18
tags: [iOS, Apple, Swift]
categories: Programming
---

## 背景说明
越来越多同学打算开始用 Swift 来开发了，可很多人以前都没接触过 Swift。这篇和我以前文章不同的是，本篇只是面向 Swift 零基础的同学，内容主要是一些直接可用的小例子，例子可以直接在工程中用或自己调试着看。

记得以前 PHP 有个 chm 的手册，写的很简单，但很全，每个知识点都有例子，社区版每个知识点下面还有留言互动。因此，我弄了个 Swift 的手册，是个 macOS 程序。建议使用我开发的这个 macOS 程序来浏览。源码地址：[KwaiAppTeam/SwiftPamphletApp](https://github.com/KwaiAppTeam/SwiftPamphletApp)，直接下载 dmg 地址：[戴铭的Swift小册子4.1.dmg.zip](https://github.com/KwaiAppTeam/SwiftPamphletApp/files/8040117/Swift.4.1.dmg.zip)

![](https://user-images.githubusercontent.com/251980/152918704-9522eb27-9304-4788-b4ed-72ffb170e1bc.png)

这个程序是Swift写的，按照声明式UI，响应式编程范式开发的，源码也可以看看。与其讲一堆，不如调着试。

下面是文本内容。注：代码中简化变量名是为了能更快速关注到语言用法。

## 语法速查

### 基础

#### 变量 let, var

变量是可变的，使用 var 修饰，常量是不可变的，使用 let 修饰。类、结构体和枚举里的变量是属性。

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

属性没有 set 可以省略 get，如果有 set 需加 get。变量设置前通过 willSet 访问到，变量设置后通过 didSet 访问。


#### 打印 print("")

控制台打印值

```swift
print("hi")
let i = 14
print(i)
print("9月\(i)是小柠檬的生日")

for i in 1...3{
    print(i)
}
// output:
// 1
// 2
// 3

// 使用terminator使循环打印更整洁
for i in 1...3 {
    print("\(i) ", terminator: "")
}
// output:
// 1 2 3
```


#### 注释 //

```swift
// 单行注释
/*
多行注释第一行。
多行注释第二行。
*/ 
// MARK: 会在 minimap 上展示
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

函数在 Swift 5.4 时开始有了使用多个变量参数的能力，使用方法如下：

```swift
func f4(s: String..., i: Int...) {
    print(s)
    print(i)
}

f4(s: "one", "two", "three", i: 1, 2, 3)
/// ["one", "two", "three"]
/// [1, 2, 3]
```

嵌套函数可以重载，嵌套函数可以在声明函数之前调用他。

```swift
func f5() {
    nf5()
    func nf5() {
        print("this is nested function")
    }
}
f5() // this is nested function
```

#### 访问控制

在 Xcode 里的 target 就是模块，使用 import 可导入模块。模块内包含源文件，每个源文件里可以有多个类、结构体、枚举和函数等多种类型。访问级别可以通过一些关键字描述，分为如下几种：

* open：在模块外可以调用和继承。
* public：在模块外可调用不可继承，open 只适用类和类成员。
* internal：默认级别，模块内可跨源文件调用，模块外不可调用。
* fileprivate：只能在源文件内访问。
* private：只能在所在的作用域内访问。

重写继承类的成员，可以设置成员比父类的这个成员更高的访问级别。Setter 的级别可以低于对应的 Getter 的级别，比如设置 Setter 访问级别为 private，可以在属性使用 private(set) 来修饰。


### 基础类型

#### 数字 Int, Float

数字的类型有 Int、Float 和 Double

```swift
// Int
let i1 = 100
let i2 = 22
print(i1 / i2) // 向下取整得 4

// Float
let f1: Float = 100.0
let f2: Float = 22.0
print(f1 / f2) // 4.5454545

let f3: Float16 = 5.0 // macOS 还不能用
let f4: Float32 = 5.0
let f5: Float64 = 5.0
let f6: Float80 = 5.0
print(f4, f5, f6) // 5.0 5.0 5.0

// Double
let d1: Double = 100.0
let d2: Double = 22.0
print(d1 / d2) // 4.545454545454546

// 字面量
print(Int(0b10101)) // 0b 开头是二进制 
print(Int(0x00afff)) // 0x 开头是十六进制
print(2.5e4) // 2.5x10^4 十进制用 e
print(0xAp2) // 10*2^2  十六进制用 p
print(2_000_000) // 2000000

// isMultiple(of:) 方法检查一个数字是否是另一个数字的倍数
let i3 = 36
print(i3.isMultiple(of: 9)) // true
```

处理数字有 floor、ceil、round。floor 是向下取整，只取整数部分；cell 是向上取整，只要有不为零的小数，整数就加1;round 是四舍五入。       


#### 布尔数 Bool

布尔数有 true 和 false 两种值，还有一个能够切换这两个值的 toggle 方法。

```swift
var b = false
b.toggle() // true
b.toggle() // false
```


#### 元组 (a, b, c)

元组里的值类型可以是不同的。元组可以看成是匿名的结构体。

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

/// 转义符 \n 表示换行。
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

// 切割成数组
let s6 = "one/two/three"
let a1 = s6.components(separatedBy: "/") // 继承自 NSString 的接口
print(a1) // ["one", "two", "three"]

let a2 = s6.split(separator: "/")
print(a2) // ["one", "two", "three"] 属于切片，性能较 components 更好

// 判断是否是某种类型
let c1: Character = "🤔"
print(c1.isASCII) // false
print(c1.isSymbol) // true
print(c1.isLetter) // false
print(c1.isNumber) // false
print(c1.isUppercase) // false

// 字符串和 Data 互转
let data = Data("hi".utf8)
let s7 = String(decoding: data, as: UTF8.self)
print(s7) // hi

// 字符串可以当作集合来用。
let revered = s7.reversed()
print(String(revered))
```

Unicode、Character 和 SubString 等内容参见官方字符串文档：[Strings and Characters — The Swift Programming Language (Swift 5.1)](https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html)

字符串字面符号可以参看《[String literals in Swift](https://www.swiftbysundell.com/articles/string-literals-in-swift/)》。

原始字符串
```swift
// 原始字符串在字符串前加上一个或多个#符号。里面的双引号和转义符号将不再起作用了，如果想让转义符起作用，需要在转义符后面加上#符号。
let s8 = #"\(s7)\#(s7) "one" and "two"\n. \#nThe second line."#
print(s8)
/// \(s7)hi "one" and "two"\n.
/// The second line.

// 原始字符串在正则使用效果更佳，反斜杠更少了。
let s9 = "\\\\[A-Z]+[A-Za-z]+\\.[a-z]+"
let s10 = #"\\[A-Z]+[A-Za-z]+\.[a-z]+"#
print(s9) // \\[A-Z]+[A-Za-z]+\.[a-z]+
print(s10) // \\[A-Z]+[A-Za-z]+\.[a-z]+
```

#### 枚举

Swift的枚举有类的一些特性，比如计算属性、实例方法、扩展、遵循协议等等。

```swift
enum E1:String, CaseIterable {
    case e1, e2 = "12"
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

@unknown 用来区分固定的枚举和可能改变的枚举的能力。@unknown 用于防止未来新增枚举属性会进行提醒提示完善每个 case 的处理。

```swift
// @unknown
enum E3 {
    case e1, e2, e3
}

func fe1(e: E3) {
    switch e {
    case .e1:
        print("e1 ok")
    case .e2:
        print("e2 ok")
    case .e3:
        print("e3 ok")
    @unknown default:
        print("not ok")
    }
}
```

符合 Comparable 协议的枚举可以进行比较。

```swift
// Comparable 枚举比较
enum E4: Comparable {
    case e1, e2
    case e3(i: Int)
    case e4
}
let e3 = E4.e4
let e4 = E4.e3(i: 3)
let e5 = E4.e3(i: 2)
let e6 = E4.e1
print(e3 > e4) // true
let a1 = [e3, e4, e5, e6]
let a2 = a1.sorted()
for i in a2 {
    print(i.self)
}
/// e1
/// e3(i: 2)
/// e3(i: 3)
/// e4
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

var s1 = S1(arr: ["zero"])
s1.add("one")
s1.add("two")
print(s1.arr) // ["zero", "one", "two"]
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

泛型适用于嵌套类型
```swift
struct S3<T> {
    struct S4 {
        var p: T
    }
    
    var p1: T
    var p2: S4
}

let s2 = S3(p1: 1, p2: S3.S4(p: 3))
let s3 = S3(p1: "one", p2: S3.S4(p: "three"))
print(s2,s3)
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

函数调用者决定返回什么类型是泛型，函数自身决定返回什么类型使用不透明返回类型。

#### Result

Result 类型用来处理错误，特别适用异步接口的错误处理。

```swift
extension URLSession {
    func dataTaskWithResult(
        with url: URL,
        handler: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionDataTask {
        dataTask(with: url) { data, _, err in
            if let err = err {
                handler(.failure(err))
            } else {
                handler(.success(data ?? Data()))
            }
        }
    }
}

let url = URL(string: "https://ming1016.github.io/")!

// 以前网络请求
let t1 = URLSession.shared.dataTask(with: url) {
    data, _, error in
    if let err = error {
        print(err)
    } else if let data = data {
        print(String(decoding: data, as: UTF8.self))
    }
}
t1.resume()

// 使用 Result 网络请求
let t2 = URLSession.shared.dataTaskWithResult(with: url) { result in
    switch result {
    case .success(let data):
        print(String(decoding: data, as: UTF8.self))
    case .failure(let err):
        print(err)
    }
}
t2.resume()
```


#### 类型转换

使用 is 关键字进行类型判断， 使用as 关键字来转换成子类。

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

键路径表达式作为函数

```swift
struct S2 {
    let p1: String
    let p2: Int
}

let s2 = S2(p1: "one", p2: 1)
let s3 = S2(p1: "two", p2: 2)
let a1 = [s2, s3]
let a2 = a1.map(\.p1)
print(a2) // ["one", "two"]
```

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

静态下标方法

```swift
// 静态下标
struct S2 {
    static var sp = [String: Int]()
    
    static subscript(_ s: String, d: Int = 10) -> Int {
        get {
            return sp[s] ?? d
        }
        set {
            sp[s] = newValue
        }
    }
}

S2["key1"] = 1
S2["key2"] = 2
print(S2["key2"]) // 2
print(S2["key3"]) // 10

```

自定义类型中实现了 callAsFunction() 的话，该类型的值就可以直接调用。

```swift
// callAsFunction()
struct S3 {
    var p1: String
    
    func callAsFunction() -> String {
        return "show \(p1)"
    }
}
let s2 = S3(p1: "hi")
print(s2()) // show hi
```

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

print(C1(p1: "Lemon").cp1) // Lemon like ATM
print(C4(p1: "Lemon").cp1) // Lemon like Out of the blade
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

print(a2) // Hey u, a b c call my name. get it?
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

#### If • If let • If case let

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


#### 遍历 For-in

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
let dic = [
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

dif 有第三个 case 值 .insert(let offset, let element, let associatedWith) 可以跟踪成对的变化，用于高级动画。

从数组中随机取一个元素
```swift
print(a0.randomElement() ?? 0)
```

数组排序

```swift
// 排序
struct S1 {
    let n: Int
    var b = true
}

let a4 = [
    S1(n: 1),
    S1(n: 10),
    S1(n: 3),
    S1(n: 2)
]
let a5 = a4.sorted { i1, i2 in
    i1.n < i2.n
}
for n in a5 {
    print(n)
}
/// S1(n: 1)
/// S1(n: 2)
/// S1(n: 3)
/// S1(n: 10)

let a6 = [1,10,4,7,2]
print(a6.sorted(by: >)) // [10, 7, 4, 2, 1]
```

可以加到数组扩展中，通过扩展约束能够指定特定元素类型的排序，代码如下：

```swift
extension Array where Element == Int {
    // 升序
    func intSortedASC() -> [Int] {
        return self.sorted(by: <)
    }
    // 降序
    func intSortedDESC() -> [Int] {
        return self.sorted(by: <)
    }
}

print(a6.intSortedASC()) // 使用扩展增加自定义排序能力
```

在数组中检索满足条件的元素，代码如下：

```swift
// 第一个满足条件了就返回
let a7 = a4.first {
    $0.n == 10
}
print(a7?.n ?? 0)

// 是否都满足了条件
print(a4.allSatisfy { $0.n == 1 }) // false
print(a4.allSatisfy(\.b)) // true

// 找出最大的那个
print(a4.max(by: { e1, e2 in
    e1.n < e2.n
}) ?? S1(n: 0))
// S1(n: 10, b: true)

// 看看是否包含某个元素
print(a4.contains(where: {
    $0.n == 7
}))
// false
```

一些切割数组的方法。

```swift
// 切片
// 取前3个，并不是直接复制，对于大的数组有性能优势。
print(a6[..<3]) // [1, 10, 4] 需要做越界检查
print(a6.prefix(30)) // [1, 10, 4, 7, 2] 不需要做越界检查，也是切片，性能一样

// 去掉前3个
print(a6.dropFirst(3)) // [7, 2]
```

prefix(while:) 和 drop(while:) 方法，顺序遍历执行闭包里的逻辑判断，满足条件就返回，遇到不匹配就会停止遍历。prefix 返回满足条件的元素集合，drop 返回停止遍历之后那些元素集合。

```swift
let a8 = [8, 9, 20, 1, 35, 3]
let a9 = a8.prefix {
    $0 < 30
}
print(a9) // [8, 9, 20, 1]
let a10 = a8.drop {
    $0 < 30
}
print(a10) // [35, 3]
```

比 filter 更高效的删除元素的方法 removeAll

```swift
// 删除所有不满足条件的元素
var a11 = [1, 3, 5, 12, 25]
a11.removeAll { $0 < 10 }
print(a11) // [4, 3, 1, 3, 3] 随机

// 创建未初始化的数组
let a12 = (0...4).map { _ in
    Int.random(in: 0...5)
}
print(a12) // [0, 3, 3, 2, 5] 随机
```

#if 用于后缀表达式

```swift
// #if 用于后缀表达式
let a13 = a11
#if os(iOS)
    .count
#else
    .reduce(0, +)
#endif
print(a13) //37
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
var d1 = [
    "k1": "v1",
    "k2": "v2"
]
d1["k3"] = "v3"
d1["k4"] = nil

print(d1) // ["k2": "v2", "k3": "v3", "k1": "v1"]

for (k, v) in d1 {
    print("key is \(k), value is \(v)")
}
/*
 key is k1, value is v1
 key is k2, value is v2
 key is k3, value is v3
 */
 
if d1.isEmpty == false {
    print(d1.count) // 3
}

// mapValues
let d2 = d1.mapValues {
    $0 + "_new"
}
print(d2) // ["k2": "v2_new", "k3": "v3_new", "k1": "v1_new"]

// 对字典的值或键进行分组
let d3 = Dictionary(grouping: d1.values) {
    $0.count
}
print(d3) // [2: ["v1", "v2", "v3"]]

// 从字典中取值，如果键对应无值，则使用通过 default 指定的默认值
d1["k5", default: "whatever"] += "."
print(d1["k5"] ?? "") // whatever.
let v1 = d1["k3", default: "whatever"]
print(v1) // v3

// compactMapValues() 对字典值进行转换和解包。可以解可选类型，并去掉 nil 值
let d4 = [
    "k1": 1,
    "k2": 2,
    "k3": nil
]
let d5 = d4.mapValues { $0 }
let d6 = d4.compactMapValues{ $0 }
print(d5)
// ["k3": nil, "k1": Optional(1), "k2": Optional(2)]
print(d6)
// ["k1": 1, "k2": 2]
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

```swift
// 元组比较
// 会先比较第一个数，第一个无法比较才会比较第二个数
// 字符串比较和字母大小还有长度有关。先比较字母大小，在比较长度
("apple", 1) < ("apple", 2) // true
("applf", 1) < ("apple", 2) // false
("appl", 2) < ("apple", 1) // true
("appm", 2) < ("apple", 1) // false
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

```swift
// 单侧区间
let nums = [5,6,7,8]
print(nums[2...]) // 7 8
```


#### 逻辑 !, &&, ||

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

let c1 = C(p: "one")
let c2 = C(p: "one")
let c3 = c1

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


### 基础库

#### 时间

Date 的基本用法如下：
```swift
let now = Date()

// Date 转 时间戳
let interval = now.timeIntervalSince1970 // 时间戳
let df = DateFormatter()
df.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm:ss"
print("时间戳：\(Int(interval))") // 时间戳：1642399901
print("格式化的时间：" + df.string(from: now)) // 格式化的时间：2022 年 01 月 17 日 14:11:41
df.dateStyle = .short
print("short 样式时间：" + df.string(from: now)) // short 样式时间：2022/1/17
df.locale = Locale(identifier: "zh_Hans_CN")
df.dateStyle = .full
print("full 样式时间：" + df.string(from: now)) // full 样式时间：2022年1月17日 星期一

// 时间戳转 Date
let date = Date(timeIntervalSince1970: interval)
print(date) // 2022-01-17 06:11:41 +0000
```


复杂的时间操作，比如说 GitHub 接口使用的是 ISO 标准，RSS 输出的是 RSS 标准字符串，不同标准对应不同时区的时间计算处理，可以使用开源库  [SwiftDate](https://github.com/malcommac/SwiftDate)  来完成。示例代码如下：

```swift
import SwiftDate

// 使用 SwiftDate 库
let cn = Region(zone: Zones.asiaShanghai, locale: Locales.chineseChina)
SwiftDate.defaultRegion = cn
print("2008-02-14 23:12:14".toDate()?.year ?? "") // 2008

let d1 = "2022-01-17T23:20:35".toISODate(region: cn)
guard let d1 = d1 else {
    return
}
print(d1.minute) // 20
let d2 = d1 + 1.minutes
print(d2.minute)

// 两个 DateInRegion 相差时间 interval
let i1 = DateInRegion(Date(), region: cn) - d1
let s1 = i1.toString {
    $0.maximumUnitCount = 4
    $0.allowedUnits = [.day, .hour, .minute]
    $0.collapsesLargestUnit = true
    $0.unitsStyle = .abbreviated
    $0.locale = Locales.chineseChina
}
print(s1) // 9小时45分钟
```


#### 格式化

使用标准库的格式来描述不同场景的情况可以不用去考虑由于不同地区的区别，这些在标准库里就可以自动完成了。

描述两个时间之间相差多长时间
```swift
// 计算两个时间之间相差多少时间，支持多种语言字符串
let d1 = Date().timeIntervalSince1970 - 60 * 60 * 24
let f1 = RelativeDateTimeFormatter()
f1.dateTimeStyle = .named
f1.formattingContext = .beginningOfSentence
f1.locale = Locale(identifier: "zh_Hans_CN")
let str = f1.localizedString(for: Date(timeIntervalSince1970: d1), relativeTo: Date())
print(str) // 昨天

// 简写
let str2 = Date.now.addingTimeInterval(-(60 * 60 * 24))
    .formatted(.relative(presentation: .named))
print(str2) // yesterday
```


描述多个事物
```swift
// 描述多个事物
let s1 = ListFormatter.localizedString(byJoining: ["冬天","春天","夏天","秋天"])
print(s1)
```


描述名字
```swift
// 名字
let f2 = PersonNameComponentsFormatter()
var nc1 = PersonNameComponents()
nc1.familyName = "戴"
nc1.givenName = "铭"
nc1.nickname = "铭哥"
print(f2.string(from: nc1)) // 戴铭
f2.style = .short
print(f2.string(from: nc1)) // 铭哥
f2.style = .abbreviated
print(f2.string(from: nc1)) // 戴

var nc2 = PersonNameComponents()
nc2.familyName = "Dai"
nc2.givenName = "Ming"
nc2.nickname = "Starming"
f2.style = .default
print(f2.string(from: nc2)) // Ming Dai
f2.style = .short
print(f2.string(from: nc2)) // Starming
f2.style = .abbreviated
print(f2.string(from: nc2)) // MD

// 取出名
let componets = f2.personNameComponents(from: "戴铭")
print(componets?.givenName ?? "") // 铭
```


描述数字
```swift
// 数字
let f3 = NumberFormatter()
f3.locale = Locale(identifier: "zh_Hans_CN")
f3.numberStyle = .currency
print(f3.string(from: 123456) ?? "") // ¥123,456.00
f3.numberStyle = .percent
print(f3.string(from: 123456) ?? "") // 12,345,600%

let n1 = 1.23456
let n1Str = n1.formatted(.number.precision(.fractionLength(3)).rounded())
print(n1Str) // 1.235
```


描述地址
```swift
// 地址
import Contacts

let f4 = CNPostalAddressFormatter()
let address = CNMutablePostalAddress()
address.street = "海淀区王庄路XX号院X号楼X门XXX"
address.postalCode = "100083"
address.city = "北京"
address.country = "中国"
print(f4.string(from: address))
/// 海淀区王庄路XX号院X号楼X门XXX
/// 北京 100083
/// 中国
```


#### 度量值

标准库里的物理量，在这个文档里有详细列出，包括角度、平方米等。
```swift
// 参考：https://developer.apple.com/documentation/foundation/nsdimension
let m1 = Measurement(value: 1, unit: UnitLength.kilometers)
let m2 = m1.converted(to: .meters) // 千米转米
print(m2) // 1000.0 m
// 度量值转为本地化的值
let mf = MeasurementFormatter()
mf.locale = Locale(identifier: "zh_Hans_CN")
print(mf.string(from: m1)) // 1公里
```

一些物理公式供参考：
```
面积 = 长度 × 长度
体积 = 长度 × 长度 × 长度 = 面积 × 长度

速度=长度/时间
加速度=速度/时间

力 = 质量 × 加速度
扭矩 = 力 × 长度
压力 = 力 / 面积

密度=质量 / 体积
能量 = 功率 × 时间
电阻 = 电压 / 电流
```


#### Data

数据压缩和解压
```swift
// 对数据的压缩
let d1 = "看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？看看能够压缩多少？".data(using: .utf8)! as NSData
print("ori \(d1.count) bytes")
do {
    /// 压缩算法
    /// * lz4
    /// * lzma
    /// * zlib
    /// * lzfse
    let compressed = try d1.compressed(using: .zlib)
    print("comp \(compressed.count) bytes")
    
    // 对数据解压
    let decomressed = try compressed.decompressed(using: .zlib)
    let deStr = String(data: decomressed as Data, encoding: .utf8)
    print(deStr ?? "")
} catch {}
/// ori 297 bytes
/// comp 37 bytes
```



#### 文件

文件的一些基本操作的代码如下：
```swift
let path1 = "/Users/mingdai/Downloads/1.html"
let path2 = "/Users/mingdai/Documents/GitHub/"

let u1 = URL(string: path1)
do {
    // 写入
    let url1 = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: u1, create: true) // 保证原子性安全保存
    print(url1)

    // 读取
    let s1 = try String(contentsOfFile: path1, encoding: .utf8)
    print(s1)

} catch {}

// 检查路径是否可用
let u2 = URL(fileURLWithPath:path2)
do {
    let values = try u2.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    if let capacity = values.volumeAvailableCapacityForImportantUsage {
        print("可用: \(capacity)")
    } else {
        print("不可用")
    }
} catch {
    print("错误: \(error.localizedDescription)")
}
```

怎么遍历多级目录结构中的文件呢？看下面的代码的实现：
```swift
// 遍历路径下所有目录
let u3 = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fm = FileManager.default
fm.enumerator(atPath: u3.path)?.forEach({ path in
    guard let path = path as? String else {
        return
    }
    let url = URL(fileURLWithPath: path, relativeTo: u3)
    print(url.lastPathComponent)
})
```

可以使用 FileWrapper 来创建文件夹和文件。举个例子：
```swift
// FileWrapper 的使用
// 创建文件
let f1 = FileWrapper(regularFileWithContents: Data("# 第 n 个文件\n ## 标题".utf8))
f1.fileAttributes[FileAttributeKey.creationDate.rawValue] = Date()
f1.fileAttributes[FileAttributeKey.modificationDate.rawValue] = Date()
// 创建文件夹
let folder1 = FileWrapper(directoryWithFileWrappers: [
    "file1.md": f1
])
folder1.fileAttributes[FileAttributeKey.creationDate.rawValue] = Date()
folder1.fileAttributes[FileAttributeKey.modificationDate.rawValue] = Date()

do {
    try folder1.write(
        to: URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("NewFolder"),
        options: .atomic,
        originalContentsURL: nil
    )
} catch {}
print(FileManager.default.currentDirectoryPath)
```

上面代码写起来比较繁琐，对 FileWrapper 更好的封装可以参考这篇文章《 [A Type-Safe FileWrapper | Heberti Almeida](https://heberti.com/posts/filewrapper/) 》。

文件读写处理完整能力可以参看这个库  [GitHub - JohnSundell/Files: A nicer way to handle files & folders in Swift](https://github.com/JohnSundell/Files) 

本地或者网络上，比如网盘和FTP的文件发生变化时，怎样知道能够观察到呢？

通过 HTTPHeader 里的 If-Modified-Since、Last-Modified、If-None-Match 和 Etag 等字段来判断文件的变化，本地则是使用 DispatchSource.makeFileSystemObjectSource 来进行的文件变化监听。可以参考  [KZFileWatchers](https://github.com/krzysztofzablocki/KZFileWatchers)  库的做法。



#### Scanner

```swift
let s1 = """
one1,
two2,
three3.
"""
let sn1 = Scanner(string: s1)
while !sn1.isAtEnd {
    if let r1 = sn1.scanUpToCharacters(from: .newlines) {
        print(r1 as String)
    }
}
/// one1,
/// two2,
/// three3.

// 找出数字
let sn2 = Scanner(string: s1)
sn2.charactersToBeSkipped = CharacterSet.decimalDigits.inverted // 不是数字的就跳过
var p: Int = 0
while !sn2.isAtEnd {
    if sn2.scanInt(&p) {
        print(p)
    }
}
/// 1
/// 2
/// 3
```

上面的代码还不是那么 Swifty，可以通过用AnySequence和AnyIterator来包装下，将序列中的元素推迟到实际需要时再来处理，这样性能也会更好些。具体实现可以参看《 [String parsing in Swift](https://www.swiftbysundell.com/articles/string-parsing-in-swift/) 》这篇文章。


#### AttributeString

效果如下：

![](https://user-images.githubusercontent.com/251980/150132322-20c5c2d4-6452-4d06-9202-4b93cffd8133.png)

代码如下：
```swift
var aStrs = [AttributedString]()
var aStr1 = AttributedString("""
标题
正文内容，具体查看链接。
这里摘出第一个重点，还要强调的内容。
""")
// 标题
let title = aStr1.range(of: "标题")
guard let title = title else {
    return aStrs
}

var c1 = AttributeContainer() // 可复用容器
c1.inlinePresentationIntent = .stronglyEmphasized
c1.font = .largeTitle
aStr1[title].setAttributes(c1)

// 链接
let link = aStr1.range(of: "链接")
guard let link = link else {
    return aStrs
}

var c2 = AttributeContainer() // 链接
c2.strokeColor = .blue
c2.link = URL(string: "https://ming1016.github.io/")
aStr1[link].setAttributes(c2.merging(c1)) // 合并 AttributeContainer

// Runs
let i1 = aStr1.range(of: "重点")
let i2 = aStr1.range(of: "强调")
guard let i1 = i1, let i2 = i2 else {
    return aStrs
}

var c3 = AttributeContainer()
c3.foregroundColor = .yellow
c3.inlinePresentationIntent = .stronglyEmphasized
aStr1[i1].setAttributes(c3)
aStr1[i2].setAttributes(c3)

for r in aStr1.runs {
    print("-------------")
    print(r.attributes)
}

aStrs.append(aStr1)

// Markdown
do {
    let aStr2 = try AttributedString(markdown: """
    内容[链接](https://ming1016.github.io/)。需要**强调**的内容。
    """)
    
    aStrs.append(aStr2)
    
} catch {}
```


SwiftUI 的 Text 可以直接读取 AttributedString 来进行显示。


#### 随机

用法：
```swift
let ri = Int.random(in: 0..<10)
print(ri) // 0到10随机数
let a = [0, 1, 2, 3, 4, 5]
print(a.randomElement() ?? 0) // 数组中随机取个数
print(a.shuffled()) // 随机打乱数组顺序
```


#### UserDefaults

使用方法如下：

```swift
enum UDKey {
    static let k1 = "token"
}
let ud = UserDefaults.standard
ud.set("xxxxxx", forKey: UDKey.k1)
let tk = ud.string(forKey: UDKey.k1)
print(tk ?? "")
```


### 模式

#### 单例

```swift
struct S {
    static let shared = S()
    private init() {
        // 防止实例初始化
    }
}
```


### 系统及设备

#### 系统判断

```swift
#if os(tvOS)
     // do something in tvOS
#elseif os(iOS)
     // do somthing in iOS
#elseif os(macOS)
    // do somthing in macOS
#endif
```


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


#### canImport 判断库是否可使用

```swift
#if canImport(SpriteKit)
   // iOS 等苹果系统执行
#else
   // 非苹果系统
#endif
```


#### targetEnvironment 环境的判断

```swift
#if targetEnvironment(simulator)
   // 模拟器
#else
   // 真机
#endif
```


### 自带属性包装

#### @resultBuilder

结果生成器（Result builders），通过传递序列创建新值，SwiftUI就是使用的结果生成器将多个视图生成一个视图

```swift
@resultBuilder
struct RBS {
    // 基本闭包支持
    static func buildBlock(_ components: Int...) -> Int {
        components.reduce(0) { partialResult, i in
            partialResult + i
        }
    }
    // 支持条件判断
    static func buildEither(first component: Int) -> Int {
        component
    }
    static func buildEither(second component: Int) -> Int {
        component
    }
    // 支持循环
    static func buildArray(_ components: [Int]) -> Int {
        components.reduce(0) { partialResult, i in
            partialResult + i
        }
    }
}

let a = RBS.buildBlock(
    1,
    2,
    3
)
print(a) // 6

// 应用到函数中
@RBS func f1() -> Int {
    1
    2
    3
}
print(f1()) // 6

// 设置了 buildEither 就可以在闭包中进行条件判断。
@RBS func f2(stopAtThree: Bool) -> Int {
    1
    2
    3
    if stopAtThree == true {
        0
    } else {
        4
        5
        6
    }
}
print(f2(stopAtThree: false)) // 21

// 设置了 buildArray 就可以在闭包内使用循环了
@RBS func f3() -> Int {
    for i in 1...3 {
        i * 2
    }
}
print(f3()) // 12
```


#### @dynamicMemberLookup 动态成员查询

@dynamicMemberLookup 指示访问属性时调用一个已实现的处理动态查找的下标方法 subscript(dynamicMemeber:)，通过指定属性字符串名返回值。使用方法如下：

```swift
@dynamicMemberLookup
struct D {
    // 找字符串
    subscript(dynamicMember m: String) -> String {
        let p = ["one": "first", "two": "second"]
        return p[m, default: ""]
    }
    // 找整型
    subscript(dynamicMember m: String) -> Int {
        let p = ["one": 1, "two": 2]
        return p[m, default: 0]
    }
    // 找闭包
    subscript(dynamicMember m: String) -> (_ s: String) -> Void {
        return {
            print("show \($0)")
        }
    }
    // 静态数组成员
    var p = ["This is a member"]
    // 动态数组成员
    subscript(dynamicMember m: String) -> [String] {
        return ["This is a dynamic member"]
    }
}

let d = D()
let s1: String = d.one
print(s1) // first
let i1: Int = d.one
print(i1) // 1
d.show("something") // show something
print(d.p) // ["This is a member"]
let dynamicP:[String] = d.dp
print(dynamicP) // ["This is a dynamic member"]
```

类使用 @dynamicMemberLookup，继承的类也会自动加上 @dynamicMemberLookup。协议上定义 @dynamicMemberLookup，通过扩展可以默认实现 subscript(dynamicMember:) 方法。


#### @dynamicCallable 动态可调用类型

@dynamicCallable 动态可调用类型。通过实现 dynamicallyCall 方法来定义变参的处理。

```swift
@dynamicCallable
struct D {
    // 带参数说明
    func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, Int>) -> Int {
        let firstArg = args.first?.value ?? 0
        return firstArg * 2
    }
    
    // 无参数说明
    func dynamicallyCall(withArguments args: [String]) -> String {
        var firstArg = ""
        if args.count > 0 {
            firstArg = args[0]
        }
        return "show \(firstArg)"
    }
}

let d = D()
let i = d(numberIs: 2)
print(i) // 4
let s = d("hi")
print(s) // show hi
```


### 自带协议

#### Hashable

```swift
struct H: Hashable {
    var p1: String
    var p2: Int
    
    // 提供随机 seed
    func hash(into hasher: inout Hasher) {
        hasher.combine(p1)
    }
}

let h1 = H(p1: "one", p2: 1)
let h2 = H(p1: "two", p2: 2)

var hs1 = Hasher()
hs1.combine(h1)
hs1.combine(h2)
print(h1.hashValue) // 7417088153212460033 随机值
print(h2.hashValue) // -6972912482785541972 随机值
print(hs1.finalize()) // 7955861102637572758 随机值
print(h1.hashValue) // 7417088153212460033 和前面 h1 一样

let h3 = H(p1: "one", p2: 1)
print(h3.hashValue) // 7417088153212460033 和前面 h1 一样
var hs2 = Hasher()
hs2.combine(h3)
hs2.combine(h2)
print(hs2.finalize()) // 7955861102637572758 和前面 hs1 一样
```

应用生命周期内，调用 combine() 添加相同属性哈希值相同，由于 Hasher 每次都会使用随机的 seed，因此不同应用生命周期，也就是下次启动的哈希值，就会和上次的哈希值不同。


### Codable

#### JSON 没有 id 字段

如果SwiftUI要求数据Model都是遵循Identifiable协议的，而有的json没有id这个字段，可以使用扩展struct的方式解决：

```swift
struct CommitModel: Decodable, Hashable {
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


### 网络

#### 网络状态检查

通过 Network 库的 NWPathMonitor 来检查

```swift
import Combine
import Network

// 网络状态检查 network state check
final class Nsck: ObservableObject {
    static let shared = Nsck()
    private(set) lazy var pb = mkpb()
    @Published private(set) var pt: NWPath
    
    private let monitor: NWPathMonitor
    private lazy var sj = CurrentValueSubject<NWPath, Never>(monitor.currentPath)
    private var sb: AnyCancellable?
    
    init() {
        monitor = NWPathMonitor()
        pt = monitor.currentPath
        monitor.pathUpdateHandler = { [weak self] path in
            self?.pt = path
            self?.sj.send(path)
        }
        monitor.start(queue: DispatchQueue.global())
    }
    
    deinit {
        monitor.cancel()
        sj.send(completion: .finished)
    }
    
    private func mkpb() -> AnyPublisher<NWPath, Never> {
        return sj.eraseToAnyPublisher()
    }
}
```

使用方法

```swift
var sb = Set<AnyCancellable>()
var alertMsg = ""

Nsck.shared.pb
    .sink { _ in
        //
    } receiveValue: { path in
        alertMsg = path.debugDescription
        switch path.status {
        case .satisfied:
            alertMsg = ""
        case .unsatisfied:
            alertMsg = "😱"
        case .requiresConnection:
            alertMsg = "🥱"
        @unknown default:
            alertMsg = "🤔"
        }
        if path.status == .unsatisfied {
            switch path.unsatisfiedReason {
            case .notAvailable:
                alertMsg += "网络不可用"
            case .cellularDenied:
                alertMsg += "蜂窝网不可用"
            case .wifiDenied:
                alertMsg += "Wifi不可用"
            case .localNetworkDenied:
                alertMsg += "网线不可用"
            @unknown default:
                alertMsg += "网络不可用"
            }
        }
    }
    .store(in: &sb)
```


### 动画

#### 布局动画

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


### 安全

#### Keychain

使用方法：
```swift
let d1 = Data("keyChain github token".utf8)
let service = "access-token"
let account = "github"
let q1 = [
    kSecValueData: d1,
    kSecClass: kSecClassGenericPassword,
    kSecAttrService: service,
    kSecAttrAccount: account
] as CFDictionary

// 添加一个 keychain
let status = SecItemAdd(q1, nil)

// 如果已经添加过会抛出 -25299 错误代码，需要调用 SecItemUpdate 来进行更新
if status == errSecDuplicateItem {
    let q2 = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account
    ] as CFDictionary
    let q3 = [
        kSecValueData: d1
    ] as CFDictionary
    SecItemUpdate(q2, q3)
}

// 读取
let q4 = [
    kSecAttrService: service,
    kSecAttrAccount: account,
    kSecClass: kSecClassGenericPassword,
    kSecReturnData: true
] as CFDictionary

var re: AnyObject?
SecItemCopyMatching(q4, &re)
guard let reData = re as? Data else { return }
print(String(decoding: reData, as: UTF8.self)) // keyChain github token

// 删除
let q5 = [
    kSecAttrService: service,
    kSecAttrAccount: account,
    kSecClass: kSecClassGenericPassword,
] as CFDictionary

SecItemDelete(q5)
```



### 工程

#### 程序入口点

Swift 允许全局编写 Swift 代码，实际上 clang 会自动将代码包进一个模拟 C 的函数中。Swift 也能够指定入口点，比如 @UIApplicationMain 或 @NSApplicationMain，UIKit 启动后生命周期管理是 AppDelegate 和 SceneDelegate，《 [Understanding the iOS 13 Scene Delegate](https://www.donnywals.com/understanding-the-ios-13-scene-delegate/) 》这篇有详细介绍。

@UIApplicationMain 和 @NSApplicationMain 会自动生成入口点。这些入口点都是平台相关的，Swift 发展来看是多平台的，这样在 Swift 5.3 时引入了 @main，可以方便的指定入口点。代码如下：
```swift
@main // 要定义个静态的 main 函数
struct M {
  static func main() {
    print("let's begin")
  }
}
```

 [ArgumentParser](https://github.com/apple/swift-argument-parser)  库，Swift 官方开源的一个开发命令行工具的库，也支持 @main。使用方法如下：
```swift
import ArgumentParser

@main
struct C: ParsableCommand {
  @Argument(help: "Start")
  var phrase: String
   
  func run() throws {
    for _ in 1...5 {
      print(phrase)
    }
  }
}
```


## 专题

### Swift 那些事

#### Swift 各版本演进

*Swift 1.1*

* countElements() 改成了 count()。
* @NSApplicationMain 可以在 macOS 上使用。

*Swift 1.2*

* 引入 Set 类型。
* if let 可以放到一起，使用逗号分隔。
* 新增 zip() 和 flatMap()。
* 类增加静态方法和静态属性，使用 static 关键字描述。
* as! 用于类型强转，失败会崩溃。
* @noescape 用于描述作为参数闭包，用来告诉 Swift 闭包将在函数返回前使用。
* 常量可以延后初始化。

*Swift 2.0*

* 增加 guard 关键字，用于解可选项值。
* defer 关键字用来延迟执行，即使抛出错误了都会在最后执行。
* ErrorType 协议，以及 throws、do、try 和 catch 的引入用来处理错误。
* characters 加上 count，用来替代 count()。
* #available 用来检查系统版本。

*Swift 2.1*

* 字符串插值可以包含字符串字面符号。

*Swift 2.2*

* __FILE__, __LINE__ 和 __FUNCTION__ 换成 #file，#line 和 #function。
* 废弃 ++ 和 -- 操作符。
* C 语言风格 for 循环废弃。
* 废弃变量参数，因为变量参数容易和 inout 搞混。
* 废弃字符串化的选择器，选择器不再能写成字符串了。
* 元组可直接比较是否相等。

*Swift 3.0*

* 规范动词和名词来命名。
* 去掉 NS 前缀。
* 方法名描述参数部分变为参数名。
* 省略没必要的单词，命名做了简化呢。比如 stringByTrimmingCharactersInSet 就换成了 trimmingCharacters。
* 枚举的属性使用小写开头。
* 引入 C 函数的属性。

*Swift 3.1*

* 序列新增 prefix(while:) 和 drop(while:) 方法，顺序遍历执行闭包里的逻辑判断，满足条件就返回，遇到不匹配就会停止遍历。prefix 返回满足条件的元素集合，drop 返回停止遍历之后那些元素集合。
* 泛型适用于嵌套类型。
* 类型的扩展可以使用约束条件，比如扩展数组时，加上元素为整数的约束，这样的扩展就只会对元素为整数的数组有效。

*Swift 4.0*

* 加入 Codable 协议，更 Swifty 的编码和解码。提案 [SE-0167 Swift Encoders](https://github.com/apple/swift-evolution/blob/master/proposals/0167-swift-encoders.md)
* 字符串加入三个双引号的支持，让多行字符串编写更加直观。提案 [SE-0168 Multi-Line String Literals](https://github.com/apple/swift-evolution/blob/master/proposals/0168-multi-line-string-literals.md)
* 字符串变成集合，表示可以对字符串进行逐字遍历、map 和反转等操作。
* keypaths 语法提升。提案见 [SE-0161 Smart KeyPaths: Better Key-Value Coding for Swift](https://github.com/apple/swift-evolution/blob/master/proposals/0161-key-paths.md)
* 集合加入 ..<10 这样语法的单边切片。提案 [SE-0172 One-sided Ranges](https://github.com/apple/swift-evolution/blob/master/proposals/0172-one-sided-ranges.md)
* 字典新增 mapValues，可 map 字典的值。通过 grouping 可对字典进行分组生成新字典，键和值都可以。从字典中取值，如果键对应无值，则使用通过 default 指定的默认值。提案 [SE-0165 Dictionary & Set Enhancements](https://github.com/apple/swift-evolution/blob/master/proposals/0165-dict.md)

*Swift 4.1*


* Hashable 也不需要返回一个唯一的 hashValue 哈希值属性。
* Equatable 和 Hashable 自动合成的提案参见 [SE-0185 Synthesizing Equatable and Hashable conformance](https://github.com/apple/swift-evolution/blob/master/proposals/0185-synthesize-equatable-hashable.md)。
* 两个自定类型比较是否相等时，不再需要比较每个属性，Swift 会自动生成 == 方法，你只需要声明 Equatable 协议。
* 引入 KeyDecodingStrategy属性，其中 .convertFromSnakeCase 可以将下划线的命名转化成驼峰的命名。
* 引入条件符合性，只有满足一定条件才符合协议。比如扩展数组要求当里面元素满足某协议数组才符合这个协议。提案见 [SE-0143 Conditional conformances](https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md)。
* 引入 canImport 宏条件关键字，判断是否可以使用某库，以前只能通过判断操作系统平台来判断。提案见 [SE-0075 Adding a Build Configuration Import Test](https://github.com/apple/swift-evolution/blob/master/proposals/0075-import-test.md)。
* 新增能够去除为零项目的 compactMap()。提案 [SE-0187 Introduce Sequence.compactMap(_:)](https://github.com/apple/swift-evolution/blob/master/proposals/0187-introduce-filtermap.md)
* 关联类型可以创建递归约束，提案见 [SE-0157 Support recursive constraints on associated types](https://github.com/apple/swift-evolution/blob/master/proposals/0157-recursive-protocol-constraints.md)
* targetEnvironment 环境的判断，比如模拟器。提案见 [SE-0190 Target environment platform condition](https://github.com/apple/swift-evolution/blob/master/proposals/0190-target-environment-platform-condition.md) 。

*Swift 4.2*

* 新增动态成员查询，@dynamicMemberLookup 新属性，指示访问属性时调用一个已实现的处理动态查找的下标方法 subscript(dynamicMemeber:)，通过指定属性字符串名返回值。提案 [SE-0195 Introduce User-defined "Dynamic Member Lookup" Types](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md)
* 集合新加 removeAll(where:) 方法，过滤满足条件所有元素。比 filter 更高效。提案 [SE-0197 Adding in-place removeAll(where:) to the Standard Library](https://github.com/apple/swift-evolution/blob/master/proposals/0197-remove-where.md)
* 布尔值增加 toggle() 方法，用来切换布尔值。提案见 [SE-0199 Adding toggle to Bool](https://github.com/apple/swift-evolution/blob/master/proposals/0199-bool-toggle.md)
* 引入 CaseIterable 协议，可以将枚举中所有 case 生成 allCases 数组。提案 [SE-0194 Derived Collection of Enum Cases](https://github.com/apple/swift-evolution/blob/master/proposals/0194-derived-collection-of-enum-cases.md)
* 引入 #warning 和 #error 两个新的编译器指令。#warning 会产生一个警告，#error 会直接让编译出错。比如必须要填写 token 才能编译的话可以在设置 token 的代码前加上 #error 和说明。提案见 [SE-0196 Compiler Diagnostic Directives](https://github.com/apple/swift-evolution/blob/master/proposals/0196-diagnostic-directives.md)
* 新增加密安全的随机 API。直接在数字类型上调用 random() 方法生成随机数。shuffle() 方法可以对数组进行乱序重排。提案 [SE-0202 Random Unification](https://github.com/apple/swift-evolution/blob/master/proposals/0202-random-unification.md)
* 更简单更安全的哈希协议，引入新的 Hasher 结构，通过 combine() 方法为哈希值添加更多属性，调用 finalize() 方法生成最终哈希值。提案 [SE-0206 Hashable Enhancements](https://github.com/apple/swift-evolution/blob/master/proposals/0206-hashable-enhancements.md)
* 集合增加 allSatisfy() 用来判断集合中的元素是否都满足了一个条件。提案 [SE-0207 Add an allSatisfy algorithm to Sequence](https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md)

*Swift 5.0*

* @dynamicCallable 动态可调用类型。通过实现 dynamicallyCall 方法来定义变参的处理。提案 [SE-0216 Introduce user-defined dynamically "callable" types](https://github.com/apple/swift-evolution/blob/master/proposals/0216-dynamic-callable.md)
* 新加 Result 类型用来处理错误。提案 [SE-0235 Add Result to the Standard Library](https://github.com/apple/swift-evolution/blob/master/proposals/0235-add-result.md)
* 新增原始字符串能力，在字符串前加上一个或多个#符号。里面的双引号和转义符号将不再起作用了，如果想让转义符起作用，需要在转义符后面加上#符号。提案见 [SE-0200 Enhancing String Literals Delimiters to Support Raw Text](https://github.com/apple/swift-evolution/blob/master/proposals/0200-raw-string-escaping.md)
* 自定义字符串插值。提案 [SE-0228 Fix ExpressibleByStringInterpolation](https://github.com/apple/swift-evolution/blob/master/proposals/0228-fix-expressiblebystringinterpolation.md)
* 枚举新增 @unknown 用来区分固定的枚举和可能改变的枚举的能力。用于防止未来新增枚举属性会进行提醒提示完善每个 case 的处理。提案 [SE-0192 Handling Future Enum Cases](https://github.com/apple/swift-evolution/blob/master/proposals/0192-non-exhaustive-enums.md)
* compactMapValues() 对字典值进行转换和解包。可以解可选类型，并去掉 nil 值。提案 [SE-0218 Introduce compactMapValues to Dictionary](https://github.com/apple/swift-evolution/blob/master/proposals/0218-introduce-compact-map-values.md)
* 扁平化 try?。提案 [SE-0230 Flatten nested optionals resulting from 'try?'](https://github.com/apple/swift-evolution/blob/master/proposals/0230-flatten-optional-try.md)
* isMultiple(of:) 方法检查一个数字是否是另一个数字的倍数。提案见 [SE-0225 Adding isMultiple to BinaryInteger](https://github.com/apple/swift-evolution/blob/master/proposals/0225-binaryinteger-iseven-isodd-ismultiple.md)

*Swift 5.1*

* 有序集合的 diff，通过 difference(from:) 方法，可以返回要删除哪些和添加哪些项目能够让两个集合相等。提案 [SE-0240 Ordered Collection Diffing](https://github.com/apple/swift-evolution/blob/master/proposals/0240-ordered-collection-diffing.md)
* 属性包装。提案 [SE-0258 Property Wrappers](https://github.com/apple/swift-evolution/blob/main/proposals/0258-property-wrappers.md)
* 不透明返回类型。函数调用者决定返回什么类型是泛型，函数自身决定返回什么类型使用不透明返回类型。提案 [SE-0244 Opaque Result Types](https://github.com/apple/swift-evolution/blob/master/proposals/0244-opaque-result-types.md)
* 初始化有默认值的属性可不设置。提案 [SE-0242 Synthesize default values for the memberwise initializer](https://github.com/apple/swift-evolution/blob/master/proposals/0242-default-values-memberwise.md)
* 单行表达式函数隐式返回，返回一个单行表达式的函数可以不用 return 关键字。提案 [SE-0255 Implicit returns from single-expression functions](https://github.com/apple/swift-evolution/blob/master/proposals/0255-omit-return.md)
* 在类、结构体和枚举里使用 Self，Self 可以指代包含的类型。提案见 [SE-0068 Expanding Swift Self to class members and value types](https://github.com/apple/swift-evolution/blob/master/proposals/0068-universal-self.md)
* 静态下标。提案 [SE-0254 Static and class subscripts](https://github.com/apple/swift-evolution/blob/master/proposals/0254-static-subscripts.md)
* 枚举里有 none 的 case 编译器会提示换成 Optional.none。
* 引入未初始化数组。提案 [SE-0245 Add an Array Initializer with Access to Uninitialized Storage](https://github.com/apple/swift-evolution/blob/master/proposals/0245-array-uninitialized-initializer.md)

*Swift 5.2*

* 自定义类型中实现了 callAsFunction() 的话，该类型的值就可以直接调用。提案 [SE-0253 Callable values of user-defined nominal types](https://github.com/apple/swift-evolution/blob/master/proposals/0253-callable.md)
* 键路径表达式作为函数。提案 [SE-0249 Key Path Expressions as Functions](https://github.com/apple/swift-evolution/blob/master/proposals/0249-key-path-literal-function-expressions.md)

*Swift 5.3*

* SPM 包管理资源，SPM 可以包含资源文件，比如多媒体或文本等。通过 Bundle.module 访问这些资源。提案 [SE-0271 Package Manager Resources](https://github.com/apple/swift-evolution/blob/master/proposals/0271-package-manager-resources.md)
* SPM 包里资源本地化。提案 [SE-0278 Package Manager Localized Resources](https://github.com/apple/swift-evolution/blob/master/proposals/0278-package-manager-localized-resources.md)
* SPM 可以整合二进制包依赖。提案 [SE-0272 Package Manager Binary Dependencies](https://github.com/apple/swift-evolution/blob/master/proposals/0272-swiftpm-binary-dependencies.md)
* SPM 可以设置特定平台的依赖。提案 [SE-0273 Package Manager Conditional Target Dependencies](https://github.com/apple/swift-evolution/blob/master/proposals/0273-swiftpm-conditional-target-dependencies.md)
* 单个 catch 块中捕获多个 Error 的 case。提案 [SE-0276 Multi-Pattern Catch Clauses](https://github.com/apple/swift-evolution/blob/master/proposals/0276-multi-pattern-catch-clauses.md)
* 支持多个尾部闭包。提案见 [SE-0279 Multiple Trailing Closures](https://github.com/apple/swift-evolution/blob/master/proposals/0279-multiple-trailing-closures.md)
* 符合 Comparable 协议的枚举可以进行比较。提案 [SE-0266 Synthesized Comparable conformance for enum types](https://github.com/apple/swift-evolution/blob/master/proposals/0266-synthesized-comparable-for-enumerations.md)
* 很多地方可以不用加 self 来指代实例自己了。提案见 [SE-0269 Increase availability of implicit self in @escaping closures when reference cycles are unlikely to occur](https://github.com/apple/swift-evolution/blob/master/proposals/0269-implicit-self-explicit-capture.md)
* @main 可以方便指定程序入口点。提案 [SE-0281 @main: Type-Based Program Entry Points](https://github.com/apple/swift-evolution/blob/master/proposals/0281-main-attribute.md)
* where 子句可以用到泛型和扩展函数中。提案 [SE-0267 where clauses on contextually generic declarations](https://github.com/apple/swift-evolution/blob/master/proposals/0267-where-on-contextually-generic.md)
* 枚举的 case 也可以符合协议。提案 [SE-0280 Enum cases as protocol witnesses](https://github.com/apple/swift-evolution/blob/master/proposals/0280-enum-cases-as-protocol-witnesses.md)
* 完善 didSet，性能提升。提案 [SE-0268 Refine didSet Semantics](https://github.com/apple/swift-evolution/blob/master/proposals/0268-didset-semantics.md)
* 新增 Float16 类型，即半精度浮点类型。提案 [SE-0277 Float16](https://github.com/apple/swift-evolution/blob/master/proposals/0277-float16.md)


*Swift 5.4*

* SPM 支持 @main。提案见 [SE-0294 Declaring executable targets in Package Manifests](https://github.com/apple/swift-evolution/blob/main/proposals/0294-package-executable-targets.md)
* 结果生成器（Result builders），通过传递序列创建新值，SwiftUI就是使用的结果生成器将多个视图生成一个视图。提案 [SE-0289 Result builders](https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md)
* 增强隐式成员语法，即使用了隐式的成员可以进行链式处理。提案见 [SE-0287 Extend implicit member syntax to cover chains of member references](https://github.com/apple/swift-evolution/blob/main/proposals/0287-implicit-member-chains.md)
* 函数开始有了使用多个变量参数的能力。提案 [SE-0284 Allow Multiple Variadic Parameters in Functions, Subscripts, and Initializers](https://github.com/apple/swift-evolution/blob/main/proposals/0284-multiple-variadic-parameters.md)
* 嵌套函数可以重载，嵌套函数可以在声明函数之前调用他。
* 属性包装支持局部变量。

*Swift 5.5*

* Async await，用同步写法来处理异步。提案 [SE-0296 Async/await](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md)
* Async sequences，异步序列上的循环能力。符合 AsyncSequence 协议的序列可以通过 for await 来进行异步循环。提案见 [SE-0298 Async/Await: Sequences](https://github.com/apple/swift-evolution/blob/main/proposals/0298-asyncsequence.md) 
* 结构化的并发，使用 Task 和 TaskGroup 执行、取消和监听当前操作的方法。复杂的并发处理可以使用 withTaskGroup() 来创建一组 Task，addTask() 用来添加任务，cancelAll() 可以取消任务，addTask() 在取消任务后可以继续添加任务，如果使用了 addTaskUnlessCancelled() 方法就可以避免取消后会继续添加任务这种情况。提案见 [SE-0304 Structured concurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md)
* 只读属性支持 async 和 throws 关键字。提案 [SE-0310 Effectful Read-only Properties](https://github.com/apple/swift-evolution/blob/main/proposals/0310-effectful-readonly-properties.md)
* async let，可以创建 await 子任务。提案 [SE-0317 async let bindings](https://github.com/apple/swift-evolution/blob/main/proposals/0317-async-let.md)
* 以前异步代码的适配。比如 DispatchQueue.main.async，外部库可以通过 withCheckedContinuation() 函数来对以前异步代码进行封装。 提案见 [SE-0300 Continuations for interfacing async tasks with synchronous code](https://github.com/apple/swift-evolution/blob/main/proposals/0300-continuation.md)
* Actor，可以确保内部只能被一个线程访问，避免存储属性和方法出现竞争条件。提案在这 [SE-0306 Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)
* 全局 actors，通过 actor 将全局状态隔离出来，避免数据竞争。比如主线程 @MainActor 这个属性包装可以将属性和方法标记为只能在主线程上访问。提案 [SE-0316 Global actors](https://github.com/apple/swift-evolution/blob/main/proposals/0316-global-actors.md)
* Sendable 协议和 @Sendable 属性包装，目的是支持安全的将数据从一个线程传给另一个线程。Swift 的核心数据类型比如字符、集合等已符合 Sendable 协议。提案 [SE-0302 Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
* 局部变量可以使用 lazy。
* 属性包装可以用到函数和闭包参数上。提案[SE-0293 Extend Property Wrappers to Function and Closure Parameters](https://github.com/apple/swift-evolution/blob/main/proposals/0293-extend-property-wrappers-to-function-and-closure-parameters.md)
* 泛型支持静态成员查找。提案 [SE-0299 Extending Static Member Lookup in Generic Contexts](https://github.com/apple/swift-evolution/blob/main/proposals/0299-extend-generic-static-member-lookup.md)
* #if 用于后缀成员表达式。提案见 [SE-0308 #if for postfix member expressions](https://github.com/apple/swift-evolution/blob/main/proposals/0308-postfix-if-config-expressions.md)
* CGFloat 和 Double 之间可以隐式转换。提案 [SE-0307 Allow interchangeable use of CGFloat and Double types](https://github.com/apple/swift-evolution/blob/main/proposals/0307-allow-interchangeable-use-of-double-cgfloat-types.md)
* Codable 支持关联值枚举。提案 [SE-0295 Codable synthesis for enums with associated values](https://github.com/apple/swift-evolution/blob/main/proposals/0295-codable-synthesis-for-enums-with-associated-values.md)

### 规范

#### 注意事项

参考：

* [Swift Style Guide](https://google.github.io/swift/)

多用静态特性。swift 在编译期间所做的优化比 OC 要多，这是由于他的静态派发、泛型特化、写时复制这些静态特性决定的。另外通过 final  和 private 这样的表示可将动态特性转化为静态方式，编译开启 WMO 可以自动推导出哪些动态派发可转化为静态派发。

如何避免崩溃？

* 字典：用结构体替代
* Any：可用泛型或关联关联类型替代
* as? ：少用 AnyObject，多用泛型或不透明类型
* !：要少用

好的实践？

* 少用继承，多用 protocol
* 多用 extension 对自己代码进行管理


### 资料推荐

#### 书单

* 《Thinking in SwiftUI》
* 《Swift 进阶》
* 《函数式Swift》
* 《深入解析Mac OS X & iOS操作系统》
* 《LLVM Techniques, Tips, and Best Practices Clang and Middle-End Libraries》
* 《Learn LLVM 12》
* 《Crafting Interpreters》
* 《TCP/IP Illustrated》
* 《松本行弘的程序世界》
* 《现代操作系统》
* 《深入理解计算机系统》
* 《程序员的自我修养》
* 《Head First 设计模式》


### 三方库使用

#### SQLite.swift 的使用

下面是 SQLite.swift 库的使用介绍，包括了数据库创建，表创建，表的添加、更新、删除、查找等处理方法

```swift
import SQLite

struct DB {
    static let shared = DB()
    static let path = NSSearchPathForDirectoriesInDomains(
        .applicationSupportDirectory, .userDomainMask, true
    ).first!
    let BBDB: Connection?
    private init() {
        do {
            print(DB.path)
            BBDB = try Connection("\(DB.path)/github.sqlite3")
            
        } catch {
            BBDB = nil
        }
        /// Swift 类型和 SQLite 类型对标如下：
        /// Int64 = INTEGER
        /// Double = REAL
        /// String = TEXT
        /// nil = NULL
        /// SQLite.Blob = BLOB
        
    }
    
    // 创建表
    func cTbs() throws {
        do {
            try ReposNotiDataHelper.createTable()
            try DevsNotiDataHelper.createTable()
        } catch {
            throw DBError.connectionErr
        }
    }
    
}

enum DBError: Error {
    case connectionErr, insertErr, deleteErr, searchErr, updateErr, nilInData
}

protocol DataHelperProtocol {
    associatedtype T
    static func createTable() throws -> Void
    static func insert(i: T) throws -> Int64
    static func delete(i: T) throws -> Void
    static func findAll() throws -> [T]?
}

// MARK: 开发者更新提醒
typealias DBDevNoti = (
    login: String,
    lastReadId: String,
    unRead: Int
)

struct DevsNotiDataHelper: DataHelperProtocol {
    static let table = Table("devsNoti")
    static let login = Expression<String>("login")
    static let lastReadId = Expression<String>("lastReadId")
    static let unRead = Expression<Int>("unRead")
    typealias T = DBDevNoti
    
    static func createTable() throws {
        guard let db = DB.shared.BBDB else {
            throw DBError.connectionErr
        }
        do {
            let _ = try db.run(table.create(ifNotExists: true) { t in
                t.column(login, unique: true)
                t.column(lastReadId, defaultValue: "")
                t.column(unRead, defaultValue: 0)
            })
        } catch _ {
            throw DBError.connectionErr
        }
    } // end createTable
    
    static func insert(i: DBDevNoti) throws -> Int64 {
        guard let db = DB.shared.BBDB else {
            throw DBError.connectionErr
        }
        let insert = table.insert(login <- i.login, lastReadId <- i.lastReadId, unRead <- i.unRead)
        do {
            let rowId = try db.run(insert)
            guard rowId > 0 else {
                throw DBError.insertErr
            }
            return rowId
        } catch {
            throw DBError.insertErr
        }
    } // end insert
    
    static func delete(i: DBDevNoti) throws {
        guard let db = DB.shared.BBDB else {
            throw DBError.connectionErr
        }
        let query = table.filter(login == i.login)
        do {
            let tmp = try db.run(query.delete())
            guard tmp == 1 else {
                throw DBError.deleteErr
            }
        } catch {
            throw DBError.deleteErr
        }
    } // end delete
    
    static func find(sLogin: String) throws -> DBDevNoti? {
        guard let db = DB.shared.BBDB else {
            throw DBError.connectionErr
        }
        let query = table.filter(login == sLogin)
        let items = try db.prepare(query)
        for i in items {
            return DBDevNoti(login: i[login], lastReadId: i[lastReadId], unRead: i[unRead])
        }
        return nil
    } // end find
    
    static func update(i: DBDevNoti) throws {
        guard let db = DB.shared.BBDB else {
            throw DBError.connectionErr
        }
        let query = table.filter(login == i.login)
        do {
            if try db.run(query.update(lastReadId <- i.lastReadId, unRead <- i.unRead)) > 0 {
                
            } else {
                throw DBError.updateErr
            }
        } catch {
            throw DBError.updateErr
        }
    } // end update
    
    static func findAll() throws -> [DBDevNoti]? {
        guard let db = DB.shared.BBDB else {
            throw DBError.connectionErr
        }
        var arr = [DBDevNoti]()
        let items = try db.prepare(table)
        for i in items {
            arr.append(DBDevNoti(login: i[login], lastReadId: i[lastReadId], unRead: i[unRead]))
        }
        return arr
    } // end find all
    
}

```

使用时，可以在初始化时这么做：
```swift
// MARK: 初始化数据库
et db = DB.shared
do {
    try db.cTbs() // 创建表
} catch {
    
}
```

使用的操作示例如下：
```swift
do {
    if let fd = try ReposNotiDataHelper.find(sFullName: r.id) {
        reposDic[fd.fullName] = fd.unRead
    } else {
        do {
            let _ = try ReposNotiDataHelper.insert(i: DBRepoNoti(fullName: r.id, lastReadCommitSha: "", unRead: 0))
            reposDic[r.id] = 0
        } catch {
            return reposDic
        }
    }
} catch {
    return reposDic
}
```


### macOS

#### 范例

- 官方提供的两个例子，[Creating a macOS App](https://developer.apple.com/tutorials/swiftui/creating-a-macos-app)，[Building a Great Mac App with SwiftUI](https://developer.apple.com/documentation/swiftui/building_a_great_mac_app_with_swiftui) （有table和LazyVGrid的用法）。
- [GitHub - adamayoung/Movies: Movies and TV Shows App for iOS, iPadOS, watchOS and macOS](https://github.com/adamayoung/Movies) 使用了SwiftUI和Combine，电影数据使用的是[The Movie Database (TMDB)](https://www.themoviedb.org/)的API

#### 三栏结构

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
![](https://user-images.githubusercontent.com/251980/142977421-bed5b5ae-01fe-471f-a951-63dd4338c97a.png)



#### 共享菜单

```swift
struct ShareView: View {
    var s: String
    var body: some View {
        Menu {
            Button {
                let p = NSPasteboard.general
                p.declareTypes([.string], owner: nil)
                p.setString(s, forType: .string)
            } label: {
                Text("拷贝链接")
                Image(systemName: "doc.on.doc")
            }
            Divider()
            ForEach(NSSharingService.sharingServices(forItems: [""]), id: \.title) { item in
                Button {
                    item.perform(withItems: [s])
                } label: {
                    Text(item.title)
                    Image(nsImage: item.image)
                }
            }
        } label: {
            Text("分享")
            Image(systemName: "square.and.arrow.up")
        }
    }
}
```

#### 剪贴板

添加和读取剪贴板的方法如下：
```swift
// 读取剪贴板内容
let s = NSPasteboard.general.string(forType: .string)
guard let s = s else {
    return
}
print(s)

// 设置剪贴板内容
let p = NSPasteboard.general
p.declareTypes([.string], owner: nil)
p.setString(s, forType: .string)
```

## Combine

### 介绍

#### Combine 是什么？

WWDC 2019苹果推出Combine，Combine是一种响应式编程范式，采用声明式的Swift API。

Combine 写代码的思路是你写代码不同于以往命令式的描述如何处理数据，Combine 是要去描述好数据会经过哪些逻辑运算处理。这样代码更好维护，可以有效的减少嵌套闭包以及分散的回调等使得代码维护麻烦的苦恼。

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


Combine 主要用来处理异步的事件和值。苹果 UI 框架都是在主线程上进行 UI 更新，Combine 通过 Publisher 的 receive 设置回主线程更新UI会非常的简单。

已有的 RxSwift 和 ReactiveSwift 框架和 Combine 的思路和用法类似。

Combine 的三个核心概念
- 发布者
- 订阅者
- 操作符

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


#### Combine 资料

官方文档链接  [Combine | Apple Developer Documentation](https://developer.apple.com/documentation/combine) 。还有  [Using Combine](https://heckj.github.io/swiftui-notes/)  这里有大量使用示例，内容较全。官方讨论Combine的论坛  [Topics tagged combine](https://forums.swift.org/tag/combine) 。StackOverflow上相关问题  [Newest ‘combine’ Questions](https://stackoverflow.com/questions/tagged/combine) 。

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


### 使用说明

#### publisher

publisher 是发布者，sink 是订阅者

```swift
import Combine

var cc = Set<AnyCancellable>()
struct S {
    let p1: String
    let p2: String
}
[S(p1: "1", p2: "one"), S(p1: "2", p2: "two")]
    .publisher
    .print("array")
    .sink {
        print($0)
    }
    .store(in: &cc)
```

 输出
 ```
 array: receive subscription: ([戴铭的Swift小册子.AppDelegate.(unknown context at $10ac82d20).(unknown context at $10ac82da4).S(p1: "1", p2: "one"), 戴铭的Swift小册子.AppDelegate.(unknown context at $10ac82d20).(unknown context at $10ac82da4).S(p1: "2", p2: "two")])
array: request unlimited
array: receive value: (S(p1: "1", p2: "one"))
S(p1: "1", p2: "one")
array: receive value: (S(p1: "2", p2: "two"))
S(p1: "2", p2: "two")
array: receive finished
 ```


#### Just

Just 是发布者，发布的数据在初始化时完成

```swift
import Combine
var cc = Set<AnyCancellable>()
struct S {
    let p1: String
    let p2: String
}

let pb = Just(S(p1: "1", p2: "one"))
pb
    .print("pb")
    .sink {
        print($0)
    }
    .store(in: &cc)
```

输出
```
pb: receive subscription: (Just)
pb: request unlimited
pb: receive value: (S(p1: "1", p2: "one"))
S(p1: "1", p2: "one")
pb: receive finished
```


#### PassthroughSubject

PassthroughSubject 可以传递多值，订阅者可以是一个也可以是多个，send 指明 completion 后，订阅者就没法接收到新发送的值了。

```swift
import Combine

var cc = Set<AnyCancellable>()
struct S {
    let p1: String
    let p2: String
}

enum CError: Error {
    case aE, bE
}
let ps1 = PassthroughSubject<S, CError>()
ps1
    .print("ps1")
    .sink { c in
        print("completion:", c) // send 了 .finished 后会执行
    } receiveValue: { s in
        print("receive:", s)
        
    }
    .store(in: &cc)

ps1.send(S(p1: "1", p2: "one"))
ps1.send(completion: .failure(CError.aE)) // 和 .finished 一样后面就不会发送了
ps1.send(S(p1: "2", p2: "two"))
ps1.send(completion: .finished)
ps1.send(S(p1: "3", p2: "three"))

// 多个订阅者
let ps2 = PassthroughSubject<String, Never>()
ps2.send("one") // 订阅之前 send 的数据没有订阅者可以接收
ps2.send("two")

let sb1 = ps2
    .print("ps2 sb1")
    .sink { s in
    print(s)
    }

ps2.send("three") // 这个 send 的值会被 sb1

let sb2 = ps2
    .print("ps2 sb2")
    .sink { s in
        print(s)
    }

ps2.send("four") // 这个 send 的值会被 sb1 和 sb2 接受

sb1.store(in: &cc)
sb2.store(in: &cc)
ps2.send(completion: .finished)

```

输出
```
ps1: receive subscription: (PassthroughSubject)
ps1: request unlimited
ps1: receive value: (S(p1: "1", p2: "one"))
receive: S(p1: "1", p2: "one")
ps1: receive error: (aE)
completion: failure(戴铭的Swift小册子.AppDelegate.(unknown context at $10b15ce10).(unknown context at $10b15cf3c).CError.aE)
ps2 sb1: receive subscription: (PassthroughSubject)
ps2 sb1: request unlimited
ps2 sb1: receive value: (three)
three
ps2 sb2: receive subscription: (PassthroughSubject)
ps2 sb2: request unlimited
ps2 sb1: receive value: (four)
four
ps2 sb2: receive value: (four)
four
ps2 sb1: receive finished
ps2 sb2: receive finished
```


#### Empty

```swift
import Combine

var cc = Set<AnyCancellable>()
struct S {
    let p1: String
    let p2: String
}

let ept = Empty<S, Never>() // 加上 completeImmediately: false 后面即使用 replaceEmpty 也不会接受值
ept
    .print("ept")
    .sink { c in
        print("completion:", c)
    } receiveValue: { s in
        print("receive:", s)
    }
    .store(in: &cc)

ept.replaceEmpty(with: S(p1: "1", p2: "one"))
    .sink { c in
        print("completion:", c)
    } receiveValue: { s in
        print("receive:", s)
    }
    .store(in: &cc)
```

输出
```
ept: receive subscription: (Empty)
ept: request unlimited
ept: receive finished
completion: finished
receive: S(p1: "1", p2: "one")
completion: finished
```


#### CurrentValueSubject

CurrentValueSubject 的订阅者可以收到订阅时已发出的那条数据

```swift
import Combine

var cc = Set<AnyCancellable>()

let cs = CurrentValueSubject<String, Never>("one")
cs.send("two")
cs.send("three")
let sb1 = cs
    .print("cs sb1")
    .sink {
        print($0)
    }
    
cs.send("four")
cs.send("five")

let sb2 = cs
    .print("cs sb2")
    .sink {
        print($0)
    }

cs.send("six")

sb1.store(in: &cc)
sb2.store(in: &cc)
```

输出
```
cs sb1: receive subscription: (CurrentValueSubject)
cs sb1: request unlimited
cs sb1: receive value: (three)
three
cs sb1: receive value: (four)
four
cs sb1: receive value: (five)
five
cs sb2: receive subscription: (CurrentValueSubject)
cs sb2: request unlimited
cs sb2: receive value: (five)
five
cs sb1: receive value: (six)
six
cs sb2: receive value: (six)
six
cs sb1: receive cancel
cs sb2: receive cancel
```


#### removeDuplicates

使用 removeDuplicates，重复的值就不会发送了。

```swift
import Combine

var cc = Set<AnyCancellable>()

let pb = ["one","two","three","three","four"]
    .publisher

let sb = pb
    .print("sb")
    .removeDuplicates()
    .sink {
        print($0)
    }
    
sb.store(in: &cc)
```

输出
```
sb: receive subscription: (["one", "two", "three", "three", "four"])
sb: request unlimited
sb: receive value: (one)
one
sb: receive value: (two)
two
sb: receive value: (three)
three
sb: receive value: (three)
sb: request max: (1) (synchronous)
sb: receive value: (four)
four
sb: receive finished
```


#### flatMap

flatMap 能将多个发布者的值打平发送给订阅者

```swift
import Combine

var cc = Set<AnyCancellable>()

struct S {
    let p: AnyPublisher<String, Never>
}

let s1 = S(p: Just("one").eraseToAnyPublisher())
let s2 = S(p: Just("two").eraseToAnyPublisher())
let s3 = S(p: Just("three").eraseToAnyPublisher())

let pb = [s1, s2, s3].publisher
    
let sb = pb
    .print("sb")
    .flatMap {
        $0.p
    }
    .sink {
        print($0)
    }

sb.store(in: &cc)
```

输出
```
sb: receive subscription: ([戴铭的Swift小册子.AppDelegate.(unknown context at $101167070).(unknown context at $1011670f4).S(p: AnyPublisher), 戴铭的Swift小册子.AppDelegate.(unknown context at $101167070).(unknown context at $1011670f4).S(p: AnyPublisher), 戴铭的Swift小册子.AppDelegate.(unknown context at $101167070).(unknown context at $1011670f4).S(p: AnyPublisher)])
sb: request unlimited
sb: receive value: (S(p: AnyPublisher))
one
sb: receive value: (S(p: AnyPublisher))
two
sb: receive value: (S(p: AnyPublisher))
three
sb: receive finished
```


#### append

append 会在发布者发布结束后追加发送数据，发布者不结束，append 的数据不会发送。

```swift
import Combine

var cc = Set<AnyCancellable>()

let pb = PassthroughSubject<String, Never>()

let sb = pb
    .print("sb")
    .append("five", "six")
    .sink {
        print($0)
    }

sb.store(in: &cc)

pb.send("one")
pb.send("two")
pb.send("three")
pb.send(completion: .finished)
```

输出
```
sb: receive subscription: ([戴铭的Swift小册子.AppDelegate.(unknown context at $101167070).(unknown context at $1011670f4).S(p: AnyPublisher), 戴铭的Swift小册子.AppDelegate.(unknown context at $101167070).(unknown context at $1011670f4).S(p: AnyPublisher), 戴铭的Swift小册子.AppDelegate.(unknown context at $101167070).(unknown context at $1011670f4).S(p: AnyPublisher)])
sb: request unlimited
sb: receive value: (S(p: AnyPublisher))
one
sb: receive value: (S(p: AnyPublisher))
two
sb: receive value: (S(p: AnyPublisher))
three
sb: receive finished
```


#### prepend

prepend 会在发布者发布前先发送数据，发布者不结束也不会受影响。发布者和集合也可以被打平发布。

```swift
import Combine

var cc = Set<AnyCancellable>()

let pb1 = PassthroughSubject<String, Never>()
let pb2 = ["nine", "ten"].publisher

let sb = pb1
    .print("sb")
    .prepend(pb2)
    .prepend(["seven","eight"])
    .prepend("five", "six")
    .sink {
        print($0)
    }

sb.store(in: &cc)

pb1.send("one")
pb1.send("two")
pb1.send("three")
```

输出
```
five
six
seven
eight
nine
ten
sb: receive subscription: (PassthroughSubject)
sb: request unlimited
sb: receive value: (one)
one
sb: receive value: (two)
two
sb: receive value: (three)
three
sb: receive cancel
```


#### merge

订阅者可以通过 merge 合并多个发布者发布的数据

```swift
import Combine

var cc = Set<AnyCancellable>()

let ps1 = PassthroughSubject<String, Never>()
let ps2 = PassthroughSubject<String, Never>()

let sb1 = ps1.merge(with: ps2)
    .sink {
        print($0)
    }
    
ps1.send("one")
ps1.send("two")
ps2.send("1")
ps2.send("2")
ps1.send("three")

sb1.store(in: &cc)
```

输出
```
sb1: receive subscription: (Merge)
sb1: request unlimited
sb1: receive value: (one)
one
sb1: receive value: (two)
two
sb1: receive value: (1)
1
sb1: receive value: (2)
2
sb1: receive value: (three)
three
sb1: receive cancel
```


#### zip

zip 会合并多个发布者发布的数据，只有当多个发布者都发布了数据后才会组合成一个数据给订阅者。

```swift
import Combine

var cc = Set<AnyCancellable>()

let ps1 = PassthroughSubject<String, Never>()
let ps2 = PassthroughSubject<String, Never>()
let ps3 = PassthroughSubject<String, Never>()

let sb1 = ps1.zip(ps2, ps3)
    .print("sb1")
    .sink {
        print($0)
    }
    
ps1.send("one")
ps1.send("two")
ps1.send("three")
ps2.send("1")
ps2.send("2")
ps1.send("four")
ps2.send("3")
ps3.send("一")

sb1.store(in: &cc)
```

输出
```
sb1: receive subscription: (Zip)
sb1: request unlimited
sb1: receive value: (("one", "1", "一"))
("one", "1", "一")
sb1: receive cancel
```


#### combineLatest

combineLatest 会合并多个发布者发布的数据，只有当多个发布者都发布了数据后才会触发合并，合并每个发布者发布的最后一个数据。

```swift
import Combine

var cc = Set<AnyCancellable>()
        
let ps1 = PassthroughSubject<String, Never>()
let ps2 = PassthroughSubject<String, Never>()
let ps3 = PassthroughSubject<String, Never>()

let sb1 = ps1.combineLatest(ps2, ps3)
    .print("sb1")
    .sink {
        print($0)
    }
    
ps1.send("one")
ps1.send("two")
ps1.send("three")
ps2.send("1")
ps2.send("2")
ps1.send("four")
ps2.send("3")
ps3.send("一")
ps3.send("二")

sb1.store(in: &cc)
```

输出
```
sb1: receive subscription: (CombineLatest)
sb1: request unlimited
sb1: receive value: (("four", "3", "一"))
("four", "3", "一")
sb1: receive value: (("four", "3", "二"))
("four", "3", "二")
sb1: receive cancel
```


#### Scheduler

Scheduler 处理队列。

```swift
import Combine

var cc = Set<AnyCancellable>()
        
let sb1 = ["one","two","three"].publisher
    .print("sb1")
    .subscribe(on: DispatchQueue.global())
    .handleEvents(receiveOutput: {
        print("receiveOutput",$0)
    })
    .receive(on: DispatchQueue.main)
    .sink {
        print($0)
    }
sb1.store(in: &cc)
```

输出
```
sb1: receive subscription: ([1, 2, 3])
sb1: request unlimited
sb1: receive value: (1)
receiveOutput 1
sb1: receive value: (2)
receiveOutput 2
sb1: receive value: (3)
receiveOutput 3
sb1: receive finished
1
2
3
```


### 使用场景

#### 网络请求

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


#### KVO

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


#### 通知

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


#### Timer

使用方式如下：
```swift
let timePb = Timer.publish(every: 1.0, on: RunLoop.main, in: .default)
let timeSk = timePb.sink { r in
    print("r is \(r)")
}
let cPb = timePb.connect()
```


## Concurrency

### 介绍

#### Swift Concurrency 是什么？

ABI 稳定后，Swift 的核心团队可以开始关注 Swift 语言一直缺失的原生并发能力了。最初是由 [Chris Lattner](https://twitter.com/clattner_llvm) 在17年发的 [Swift并发宣言](https://gist.github.com/lattner/31ed37682ef1576b16bca1432ea9f782) ，从此开阔了大家的眼界。后来 Swift Evolution 社区讨论了十几个提案，几十个方案，以及几百页的设计文件，做了大量的改进，社区中用户积极的参与反馈，Chris 也一直在 Evolution 中积极的参与设计。

Swift Concurrency 的实现用了 [LLVM的协程](https://llvm.org/docs/Coroutines.html) 把 async/await 函数转换为基于回调的代码，这个过程发生在编译后期，这个阶段你的代码都没法辨识了。异步的函数被实现为 coroutines，在每次异步调用时，函数被分割成可调用的函数部分和后面恢复的部分。coroutine 拆分的过程发生在生成LLVM IR阶段。Swift使用了哪些带有自定义调用约定的函数保证尾部调用，并专门为Swift进行了调整。

Swift Concurrency 不是建立在 GCD 上，而是使用的一个全新的线程池。GCD 中启动队列工作会很快在提起线程，一个队列阻塞了线程，就会生成一个新线程。基于这种机制 GCD 线程数很容易比 CPU 核心数量多，线程多了，线程就会有大量的调度开销，大量的上下文切换，会使 CPU 运行效率降低。而 Swift Concurrency 的线程数量不会超过 CPU 内核，将上下文切换放到同一个线程中去做。为了实现线程不被阻塞，需要通过语言特性来做。做法是，每个线程都有一个堆栈记录函数调用情况，一个函数占一个帧。函数返回后，这个函数所占的帧就会从堆栈弹出。await 的 async 函数被作为异步帧保存在堆上等待恢复，而不阻碍其它函数入栈执行。在 await 后运行的代码叫 continuation，continuation 会在要恢复时放回到线程的堆栈里。异步帧会根据需要放回栈上。在一个异步函数中调用同步代码将添加帧到线程的堆栈中。这样线程就能够一直向前跑，而不用创建更多线程减少调度。

Douglas 在 Swift 论坛里发的 Swift Concurrency 下个版本的规划贴  [Concurrency in Swift 5 and 6](https://forums.swift.org/t/concurrency-in-swift-5-and-6/49337) ，论坛里还有一个帖子是专门用来 [征集Swift Concurrency意见](https://forums.swift.org/t/swift-concurrency-feedback-wanted/49336) 的，帖子本身列出了 Swift Concurrency 相关的所有提案，也提出欢迎有新提案发出来，除了这些提案可以看外，帖子回复目前已经过百，非常热闹，可以看出大家对 Swift Concurrency 的关注度相当的高。

非常多的人参与了 Swift Concurrency 才使其看起来和用起来那么简单。Doug Gregor 在参与 John Sundell 的播客后，发了很多条推聊 Swift Concurrency，可以看到参与的人非常多，可见背后付出的努力有多大。下面我汇总了 Doug Gregor 在推上发的一些信息，你通过这些信息也可以了解 Swift Concurrency 幕后信息，所做的事和负责的人。

 [@pathofshrines](https://twitter.com/pathofshrines) 是 Swift Concurrency 整体架构师，包括低级别运行时和编译器相关细节。 [@illian](https://twitter.com/illian) 是 async sequences、stream 和 Fundation 的负责人。 [@optshiftk](https://twitter.com/optshiftk) 对 UI 和并发交互的极好的洞察力带来了很棒的 async 接口， [@phausler](https://twitter.com/phausler) 带来了 async sequences。Arnold Schwaighofer、 [@neightchan](https://twitter.com/neightchan) 、 [@typesanitizer](https://twitter.com/typesanitizer) 还有 Tim Northover 实现了 async calling convention。

 [@ktosopl](https://twitter.com/ktosopl) 有很深厚的 actor、分布式计算和 Swift-on-Server 经验，带来了 actor 系统。Erik Eckstein 为 async 函数和actors建立了关键的优化和功能。

SwiftUI是 [@ricketson_](https://twitter.com/ricketson_) 和 [@luka_bernardi](https://twitter.com/luka_bernardi) 完成的async接口。async I/O的接口是 [@Catfish_Man](https://twitter.com/Catfish_Man) 完成的。 [@slava_pestov](https://twitter.com/slava_pestov) 处理了 Swift 泛型问题，还指导其他人编译器实现的细节。async 重构工具是Ben Barham 做的。大量代码移植到 async 是由 [@AirspeedSwift](https://twitter.com/AirspeedSwift) 领导，由 Angela Laar，Clack Cole，Nicole Jacques 和 [@mishaldshah](https://twitter.com/mishaldshah) 共同完成的。

 [@lorentey](https://twitter.com/lorentey) 负责 Swift 接口的改进。 [@jckarter](https://twitter.com/jckarter) 有着敏锐的语言设计洞察力，带来了语言设计经验和编译器及运行时实现技能。 [@mikeash](https://twitter.com/mikeash)  也参与了运行时开发中。操作系统的集成是 [@rokhinip](https://twitter.com/rokhinip) 完成的， [@chimz](https://twitter.com/chimz) 提供了关于 Dispatch 和 OS 很好的建议，Pavel Yaskevich 和
 [@hollyborla](https://ming1016.github.io/2021/07/24/my-little-idea-about-writing-technical-article/) 进行了并发所需要关键类型检查器的改进。 [@kastiglione](https://twitter.com/kastiglione) 、Adrian Prantl和 [@fred_riss](https://twitter.com/fred_riss) 实现了调试。 [@etcwilde](https://twitter.com/etcwilde) 和 [@call1cc](https://twitter.com/call1cc) 实现了语义模型中的重要部分。

 [@evonox](https://twitter.com/evonox) 负责了服务器Linux 的支持。 [@compnerd](https://twitter.com/compnerd) 将 Swift Concurrency 移植到了 Windows。

Swift Concurrency 模型简单，细节都被隐藏了，比 Kotlin 和 C++的 Coroutine 接口要简洁很多。比如 Task 接口形式就很简洁。Swift Concurrency 大体可分为 async/await、Async Sequences、结构化并发和 Actors。


#### async/await

通过类似 throws 语法的 async 来指定函数为异步函数，异步函数才能够使用 await，使用异步函数要用 await。await 修饰在 suspension point 时当前线程可以让给其它任务执行，而不用阻塞当前线程，等 await 后面的函数执行完成再回来继续执行，这里需要注意的是回来执行不一定是在离开时的线程上。async/await 提案是 [SE-0296](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md) 。如果想把现有的异步开发带到 async/await 世界，请使用 withCheckedThrowingContinuation。

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

使用这些接口可以一边接收数据一边进行显示，AsyncSequence 的提案是 [SE-0298](https://github.com/apple/swift-evolution/blob/main/proposals/0298-asyncsequence.md) （Swift 5.5可用）。AsyncStream 是创建自己异步序列的最简单的方法，处理迭代、取消和缓冲。AsyncStream 正在路上，提案是 [SE-0314](https://github.com/apple/swift-evolution/blob/main/proposals/0314-async-stream.md) 。

Task 为一组并发任务创建一个运行环境，async let 可以让任务并发执行，结构化并发（Structured concurrency，提案在路上 [SE-0304](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md) ）withTaskGroup 中 group.async 可以将并发任务进行分组。


#### Actors

我们写的程序会在进程中被拆成一个一个小指令，这些指令会在某刻会一个接一个同步的或者并发的执行。系统会用多个线程执行并行的任务，执行顺序是调度器来管理的，现代多核可以同时处理多个线程，当一个资源在多个线程上同时被更改时就会出问题。并发任务对数据资源操作容易造成数据竞争，以前需要手动放到串行队列、使用锁、调度屏障或 Atomics 的方式来避免。以前处理容易导致昂贵的上下文切换，过多线程容易导致线程爆炸，容易意外阻断线程导致后面代码没法执行，多任务相互的等待造成了死锁，block 和内存引用容易出错等等问题。

现在 Swift Concurrency 可以通过 actor 来创建一个区域，在这个区域会自动进行数据安全保护，保证一定时间只有一个线程访问里面数据，防止数据竞争。actor 内部对成员访问是同步的，成员默认是隔离的，actor 外部对 actor 内成员的访问只能是异步的，隐式同步以防止数据竞争。MainActor 继承自能确保全局唯一实例的 GlobalActor，保证任务在主线程执行，这样你就可以抛弃掉在你的 ViewModel 里写 DispatchQueue.main.async 了。

Actors 的概念通常被用于分布式计算，Actor 模型参看 [Wikipedia](https://en.wikipedia.org/wiki/Actor_model) 里的详细解释，Swift 中的实现效果也非常的理想。Actors 的提案 [SE-0306](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md) 已在 Swift 5.5落实。

很多语言都支持 actors 还有 async/await，实现的方式也类似，actor 使用的不是锁，而是用的 async/await 这样能够在一个线程中切换上下文来避免线程空闲的线程模型。actor 还利用编译器，提前做会引起并发问题的检查。

actor 是遵循 Sendable 协议的，只有结构体和 final 类才能够遵循 Sendable，继承于 Sendable 协议的 Excutor 协议表示方法本身，SerialExecutor 表示以串行方式执行。actor 使用 C++写的，源码在 [这里](https://github.com/apple/swift/blob/main/stdlib/public/Concurrency/Actor.cpp) ，可以看到 actor 主要是通过控制各个 job 执行的状态的管理器。job 执行优先级来自 Task 对象，排队时需要确保高优 job 先被执行。全局 Executor 用来为 job 排队，通知 actor 拥有或者放弃线程，实现在 [这里](https://github.com/apple/swift/blob/main/stdlib/public/Concurrency/GlobalExecutor.cpp) 。由于等待而放弃当前线程让其他 actor 执行的 actor，在收到全局 Executor 创建一个新的 job 的通知，使其可以进入一个可能不同线程，这个过程就是并发模型中描述的 Actor Reentrancy。


#### 相关提案

所有相关提案清单如下：

*  [SE-0296: Async/await](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md)   [【译】SE-0296 Async/await](https://kemchenj.github.io/2021-03-06/) 
*  [SE-0317: async let](https://github.com/apple/swift-evolution/blob/main/proposals/0317-async-let.md) 
*  [SE-0300: Continuations for interfacing async tasks with synchronous code](https://github.com/apple/swift-evolution/blob/main/proposals/0300-continuation.md)   [【译】SE-0300 Continuation – 执行同步代码的异步任务接口](https://kemchenj.github.io/2021-03-31/) 
*  [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md) 
*  [SE-0298: Async/Await: Sequences](https://github.com/apple/swift-evolution/blob/main/proposals/0298-asyncsequence.md)   [【译】SE-0298 Async/Await 序列](https://kemchenj.github.io/2021-03-10/) 
*  [SE-0304: Structured concurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md) 
*  [SE-0306: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)   [【译】SE-0306 Actors](https://kemchenj.github.io/2021-04-25/) 
*  [SE-0313: Improved control over actor isolation](https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md) 
*  [SE-0297: Concurrency Interoperability with Objective-C](https://github.com/apple/swift-evolution/blob/main/proposals/0297-concurrency-objc.md)   [【译】SE-0297 Concurrency 与 Objective-C 的交互](https://kemchenj.github.io/2021-03-07/) 
*  [SE-0314: AsyncStream and AsyncThrowingStream](https://github.com/apple/swift-evolution/blob/main/proposals/0314-async-stream.md) 
*  [SE-0316: Global actors](https://github.com/apple/swift-evolution/blob/main/proposals/0316-global-actors.md) 
*  [SE-0310: Effectful read-only properties](https://github.com/apple/swift-evolution/blob/main/proposals/0310-effectful-readonly-properties.md) 
*  [SE-0311: Task Local Values](https://github.com/apple/swift-evolution/blob/main/proposals/0311-task-locals.md) 
*  [Custom Executors](https://forums.swift.org/t/support-custom-executors-in-swift-concurrency/44425) 


#### 学习路径

如果打算尝试 Swift Concurrency 的话，按照先后顺序，可以先看官方手册介绍文章 [Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) 。再看 [Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/) 这个Session，了解背后原理看 [Explore structured concurrency in Swift](https://developer.apple.com/videos/play/wwdc2021/10134) 。动手照着试示例代码，看Paul的 [Swift Concurrency by Example](https://www.hackingwithswift.com/quick-start/concurrency) 这个系列。接着看 [Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133) 来了解 actors 怎么防止数据竞争。通过 [Discover concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10019) 看 concurrency 如何在 SwiftUI 中使用， [Use async/await with URLSession](https://developer.apple.com/videos/play/wwdc2021/10095) 来看怎么在 URLSession 中使用 async/await。最后听听负责 Swift Concurrency 的 Doug Gregor 参加的一个 [播客的访谈](https://www.swiftbysundell.com/podcast/99/) ，了解下 Swift Concurrency 背后的故事。


#### Swift Concurrency 和 Combine

由于 Swift Concurrency 的推出和大量的 Session 发布，特别是 [AsyncSequence](https://developer.apple.com/documentation/swift/asyncsequence/) 的出现，以及正在路上的 [AsyncStream、AsyncThrowingStream](https://github.com/apple/swift-evolution/blob/main/proposals/0314-async-stream.md) 和 [continuation](https://github.com/apple/swift-evolution/blob/main/proposals/0300-continuation.md) 提案（在Xcode 13.0 beta 3 AsyncStream 正式 [release](https://developer.apple.com/documentation/swift/asyncstream?changes=latest_beta) ），这些越来越多和 Combine 功能重叠的特性出现在 Swift Concurrency 蓝图里时，大家开始猜测是否 Combine 会被 Swift Concurrency 替代。关于未来是 Swift Concurrency 还是 Combine，我的感觉是，Combine 更侧重在响应式编程上，而响应式编程并不是所有开发人员都会接受的，而 Swift Concurrency 是所有人都愿意接受的开发方式，从 Swift Concurrency 推出后开发者使用的数量和社区反应火热程度来看都比 Combine 要大。在苹果对 Combine 有下一步动作之前，我还是更偏向 Swift Concurrency。


## SwiftUI

### 介绍

#### SwiftUI 是什么？

对于一个基于UIKit的项目是没有必要全部用SwiftUI重写的，在UIKit里使用SwiftUI的视图非常容易，UIHostingController是UIViewController的子类，可以直接用在UIKit里，因此直接将SwiftUI视图加到UIHostingController中，就可以在UIKit里使用SwiftUI视图了。

SwiftUI的布局核心是 GeometryReader、View Preferences和Anchor Preferences。如下图所示：

![](https://user-images.githubusercontent.com/251980/142988837-ab49c202-9779-4c7a-8dc2-5584900c0765.png)

SwiftUI的数据流更适合Redux结构，如下图所示：

![](https://user-images.githubusercontent.com/251980/142988879-af591aaf-161f-4f60-9891-d7b8d313f69f.png)

如上图，Redux结构是真正的单向单数据源结构，易于分割，能充分利用SwiftUI内置的数据流Property Wrapper。UI组件干净、体量小、可复用并且无业务逻辑，因此开发时可以聚焦于UI代码。业务逻辑放在一起，所有业务逻辑和数据Model都在Reducer里。 [ACHNBrowserUI](https://github.com/Dimillian/ACHNBrowserUI)  和  [MovieSwiftUI](https://github.com/Dimillian/MovieSwiftUI)  开源项目都是使用的Redux架构。最近比较瞩目的TCA（The Composable Architecture）也是类Redux/Elm的架构的框架， [项目地址见](https://github.com/pointfreeco/swift-composable-architecture) 。

提到数据流就不得不说下苹果公司新出的Combine，对标的是RxSwift，由于是苹果公司官方的库，所以应该优先选择。不过和SwiftUI一样，这两个新库对APP支持最低的系统版本都要求是iOS13及以上。那么怎么能够提前用上SwiftUI和Combine呢？或者说现在使用什么库可以以相同接口方式暂时替换它们，又能在以后改为SwiftUI和Combine时成本最小化呢？

对于SwiftUI，AcFun自研了声明式UI Ysera，类似SwiftUI的接口，并且重构了AcFun里收藏模块列表视图和交互逻辑，如下图所示：

![](https://user-images.githubusercontent.com/251980/142988909-e6626954-2c93-4c34-b10e-5345c8015cea.png)

通过上图可以看到，swift代码量相比较OC减少了65%以上，原先使用Objective-C实现的相同功能代码超过了1000行，而Swift重写只需要350行，对于AcFun的业务研发工程师而言，同样的需求实现代码比之前少了至少30%，面对单周迭代这样的节奏，团队也变得更从容。代码可读性增加了，后期功能迭代和维护更容易了，Swift让AcFun驶入了iOS开发生态的“快车道”。

SwiftUI全部都是基于Swift的各大可提高开发效率特性完成的，比如前面提到的，能够访问只给语言特性级别行为的Property Wrapper，通过Property Wrapper包装代码逻辑，来降低代码复杂度，除了SwiftUI和Combine里@开头的Property Wrapper外，Swift还自带类似 [@dynamicMemberLookup](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md)  和 [@dynamicCallable](https://github.com/apple/swift-evolution/blob/master/proposals/0216-dynamic-callable.md)  这样重量级的Property Wrapper。还有 [ResultBuilder](https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md) 这种能够简化语法的特性，有些如GraphQL、REST和Networking实际使用ResultBuilder的 [范例可以参考](https://github.com/carson-katri/awesome-result-builders) 。这些Swift的特性如果也能得到充分利用，即使不用SwiftUI也能使开发效率得到大幅提升。

网飞（Netflix）App已使用SwiftUI重构了登录界面，网飞增长团队移动负责人故胤道长记录了SwiftUI在网飞的落地过程，详细描述了 [SwiftUI的收益](https://mp.weixin.qq.com/s/oRPRCx78owLe3_gROYapCw) 。网飞能够直接使用SwiftUI得益于他们最低支持iOS 13系统。

不过如最低支持系统低于iOS 13，还有开源项目 [AltSwiftUI](https://github.com/rakutentech/AltSwiftUI) 也实现了SwiftUI的语法和特性，能够向前兼容到iOS 11。


### 视图组件使用

#### SwiftUI 对标的 UIKit 视图

如下：

| SwiftUI | UIKit |
| ----------- | ----------- |
| Text 和 Label | UILabel |
| TextField | UITextField |
| TextEditor | UITextView |
| Button 和 Link | UIButton |
| Image | UIImageView |
| NavigationView | UINavigationController 和 UISplitViewController |
| ToolbarItem | UINavigationItem |
| ScrollView | UIScrollView |
| List | UITableView |
| LazyVGrid 和 LazyHGrid | UICollectionView |
| HStack 和 LazyHStack | UIStack |
| VStack 和 LazyVStack | UIStack |
| TabView | UITabBarController 和 UIPageViewController |
| Toggle | UISwitch |
| Slider | UISlider |
| Stepper | UIStepper |
| ProgressView | UIProgressView 和 UIActivityIndicatorView |
| Picker | UISegmentedControl |
| DatePicker | UIDatePicker |
| Alert | UIAlertController |
| ActionSheet | UIAlertController |
| Map | MapKit |


#### Text

![](https://user-images.githubusercontent.com/251980/143826034-977a6d5e-f9f5-4ec3-90d0-f09281d64af6.png)


```swift
import SwiftUI

struct TextView: View {
    var body: some View {
        Group {
            Text("大标题").font(.largeTitle)
            Text("说点啥呢？")
                .tracking(30) // 字间距
                .kerning(30) // 尾部留白
            Text("划重点")
                .underline()
                .foregroundColor(.yellow)
            Text("可旋转的文字")
                .rotationEffect(.degrees(45))
                .fixedSize()
                .frame(width: 20, height: 80)
        }
        Group {
            Text("有阴影")
                .bold()
                .italic()
                .shadow(color: .primary, radius: 1, x: 0, y: 2)
            Text("Gradient Background")
                .font(.largeTitle)
                .padding()
                .foregroundColor(.white)
                .background(LinearGradient(gradient: Gradient(colors: [.white, .black, .red]), startPoint: .top, endPoint: .bottom))
                .cornerRadius(10)
            Text("Gradient Background")
                .padding(5)
                .foregroundColor(.white)
                .background(LinearGradient(gradient: Gradient(colors: [.white, .black, .purple]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(10)
            Text("Angular Gradient Background")
                .padding()
                .background(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center))
                .cornerRadius(20)
            Text("带背景图片的")
                .padding()
                .font(.largeTitle)
                .foregroundColor(.white)
                .background {
                    Rectangle()
                        .fill(Color(.black))
                        .cornerRadius(10)
                    Image("logo")
                        .resizable()
                        .frame(width: 100, height: 100)
                }
                .frame(width: 200, height: 100)
        }
            
        Group {
            Text("这是一段长文。总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么，总得说点什么吧。")
                .lineLimit(3) // 对行的限制，如果多余设定行数，尾部会显示...
                .lineSpacing(10) // 行间距
                .multilineTextAlignment(.leading) // 对齐
        }    
    }
}
```







































