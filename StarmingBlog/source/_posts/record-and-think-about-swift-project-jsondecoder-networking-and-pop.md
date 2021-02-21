---
title: Swift 项目中涉及到 JSONDecoder，网络请求，泛型协议式编程的一些记录和想法
date: 2018-04-02 19:12:28
tags: [Swift, iOS]
categories: Programming
---
# 前言
最近项目开发一直在使用 swift，因为 HTN 项目最近会有另外一位同事加入，所以打算对最近涉及到的一些技术和自己的一些想法做个记录，同时也能够方便同事熟悉代码。

# JSON 数据的处理
做项目只要是涉及到服务器端接口都没法避免和 JSON 数据打交道。对于来自网络的 JSON 结构化数据的处理，可以使用 JSONDecoder 这个苹果自己提供的字符串转模型类，这个类是在 Swift 4 的 Fundation 模块里提供的，可以在Swift 源码目录 swift/stdlib/public/SDK/Fundation/JSONEncoder.swift 看到苹果对这个类实现。

其它对 JSON 处理的库还有 SwiftyJSON [GitHub - SwiftyJSON/SwiftyJSON: The better way to deal with JSON data in Swift](https://github.com/SwiftyJSON/SwiftyJSON)

## 使用 JSONDecoder
下面苹果使用 JSONDecoder 的一个例子来看看如何使用 JSONDecoder
```swift
struct GroceryProduct: Codable {
    var name: String
    var points: Int
    var description: String?
}

let json = """
{
    "name": "Durian",
    "points": 600,
    "description": "A fruit with a distinctive scent."
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
let product = try decoder.decode(GroceryProduct.self, from: json)

print(product.name) // Prints "Durian"
```

这里要注意 GroceryProduct 结构体需要遵循 Codable，因为 JSONDecoder 的实例对象的 decode 方法需要遵循 Decodable 协议的结构体。Codable 是 Encodable 和 Decodable 两个协议的组合，写法如下：
```swift
public typealias Codable = Decodable & Encodable
```

当然 JSON 数据的结构不会都是这么简单，如果遇到嵌套情况如下：
```swift
let json = """
{
    "name": "Durian",
    "points": 600,
    "ability": {
        "mathematics": "excellent",
        "physics": "bad",
        "chemistry": "fine"
    },
    "description": "A fruit with a distinctive scent."
}
""".data(using: .utf8)!
```

这时可以通过在 struct 里再套一个 struct 来做，修改过的 struct 如下：
```swift
struct GroceryProduct: Codable {
    var name: String
    var points: Int
    var ability: Ability
    var description: String?
    
    struct Ability: Codable {
        var mathematics: String
        var physics: String
        var chemistry: String
    }
}
```
这里可以观察到 ability 里数学物理化学的评价都是那几个，无非是优良差，所以很适合用枚举表示，swift 的枚举对于字符串关联类型枚举也有很好的支持，只要声明关联值类型是 String 就行了，改后的代码如下：
```swift
struct GroceryProduct: Codable {
    var name: String
    var points: Int
    var ability: Ability
    var description: String?
    
    struct Ability: Codable {
        var mathematics: Appraise
        var physics: Appraise
        var chemistry: Appraise
    }
    
    enum Appraise: String, Codable {
        case excellent, fine, bad
    }
}
```

API 返回的结果会有一个不可控的因素，是什么呢？那就是有的键值有时会返回有时不会返回，那么这个 struct 怎么兼容呢？

好在swift 原生就支持了 optional，只需要在属性后加个问号就行了。比如 points 有时会返回有时不会，那么就可以这么写：
```swift
struct GroceryProduct: Codable {
    var name: String
    var points: Int? //可能会用不到
}
```

## CodingKey 协议
接口还会有一些其它不可控因素，比如会产生出 snake case 的命名风格，要求风格统一固然是很好，但是现实环境总会有些不可抗拒的因素，比如不同团队，不同公司或者不同风格洁癖的 coder 之间。还好 JSONDecoder 已经做好了。下面我们看看如何用：
```swift
let json = """
{
    "nick_name": "Tom",
    "points": 600,
}
""".data(using: .utf8)!
```
这里 nick_name 我们希望处理成 swift 的风格，那么我们可以使用一个遵循 CodingKey 协议的枚举来做映射。
```swift
struct GroceryProduct: Codable {
    var nickName: String
    var points: Int
    
    enum CodingKeys : String, CodingKey{
        case nickName = "nick_name"
        case points
    }
}
```
当然这个方法是个通用方法，不光能够处理 snake case 还能够起自己喜欢的命名，比如你喜欢简写，nick name 写成 nName，那么也可以用这个方法。Codable 协议默认的实现实际上已经能够 cover 掉现实环境的大部分问题了，如果有些自定义的东西要处理的话可以通过覆盖默认 Codable 的方式来做。关键点就是 encoder 的 container，通过获取 container 对象进行自定义操作。

## JSONDecoder 的 keyDecodingStrategy 属性

JSONDecoder 里还有专门的一个属性 keyDecodingStrategy，这个值是个布尔值，有个 case 是 convertFromSnakeCase，这样就会按照这个 strategy 来转换 snake case，这个是核心功能内置的，就不需要我们额外写代码处理了。上面加上的枚举 CodingKeys 也可以去掉了，只需要在 JSONDecoder 这个实例设置这个属性就行。
```swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
```

keyDecodingStrategy 这个属性是在 swift 4.1 加上的，所以这个版本之前的还是用 CodingKey 这个协议来处理吧。

那么苹果是如何通过这个 keyDecodingStrategy 属性的设置来做到的呢？

感谢苹果使用 Swift 写了 Swift 的核心功能，以后想要了解更多功能背后原理可以不用啃 C++ 了，一边学习原理还能一边学习苹果内部是如何使用 Swift 的，所谓一举两得。

实现这个功能代码就在上文提到的 Swift 源码目录 swift/stdlib/public/SDK/Fundation/ 下的 JSONEncoder.swift  文件，如果不想把源码下下来也可以在 GitHub 上在线看，地址：[https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/JSONEncoder.swift](https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/JSONEncoder.swift)

先看看这个属性的定义：
```swift
/// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
open var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys
```
这个属性是一个 keyDecodingStrategy 枚举，默认是 .userDefaultKeys。这个枚举是这样定义的：
```swift
public enum KeyDecodingStrategy {
    /// Use the keys specified by each type. This is the default strategy.
    case useDefaultKeys
    
    /// Convert from "snake_case_keys" to "camelCaseKeys" before attempting to match a key with the one specified by each type.
    ///
    /// The conversion to upper case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
    ///
    /// Converting from snake case to camel case:
    /// 1. Capitalizes the word starting after each `_`
    /// 2. Removes all `_`
    /// 3. Preserves starting and ending `_` (as these are often used to indicate private variables or other metadata).
    /// For example, `one_two_three` becomes `oneTwoThree`. `_one_two_three_` becomes `_oneTwoThree_`.
    ///
    /// - Note: Using a key decoding strategy has a nominal performance cost, as each string key has to be inspected for the `_` character.
    case convertFromSnakeCase
    
    /// Provide a custom conversion from the key in the encoded JSON to the keys specified by the decoded types.
    /// The full path to the current decoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before decoding.
    /// If the result of the conversion is a duplicate key, then only one value will be present in the container for the type to decode from.
    case custom((_ codingPath: [CodingKey]) -> CodingKey)
    
    fileprivate static func _convertFromSnakeCase(_ stringKey: String) -> String {
        ...
    }
}
```
case convertFromSnakeCase 就是我们使用的，注释部分描述了整个过程，首先会把 ‘_’ 符号后面的字母转成大写的，然后移除掉所有的 ‘_’ 符号，保留最前面和最后的 ‘_’ 符号。比如 __nick_name_ 就会转换成 __nickName_ 而这些都是在枚举里定义的静态方法 _convertFromSnakeCase 里完成的。
```swift
fileprivate static func _convertFromSnakeCase(_ stringKey: String) -> String {
    guard !stringKey.isEmpty else { return stringKey }
    
    // Find the first non-underscore character
    guard let firstNonUnderscore = stringKey.index(where: { $0 != "_" }) else {
        // Reached the end without finding an _
        return stringKey
    }
    
    // Find the last non-underscore character
    var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
    while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
        stringKey.formIndex(before: &lastNonUnderscore);
    }
    
    let keyRange = firstNonUnderscore...lastNonUnderscore
    let leadingUnderscoreRange = stringKey.startIndex..<firstNonUnderscore
    let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore)..<stringKey.endIndex
    
    var components = stringKey[keyRange].split(separator: "_")
    let joinedString : String
    if components.count == 1 {
        // No underscores in key, leave the word as is - maybe already camel cased
        joinedString = String(stringKey[keyRange])
    } else {
        joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
    }
    
    // Do a cheap isEmpty check before creating and appending potentially empty strings
    let result : String
    if (leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty) {
        result = joinedString
    } else if (!leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty) {
        // Both leading and trailing underscores
        result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
    } else if (!leadingUnderscoreRange.isEmpty) {
        // Just leading
        result = String(stringKey[leadingUnderscoreRange]) + joinedString
    } else {
        // Just trailing
        result = joinedString + String(stringKey[trailingUnderscoreRange])
    }
    return result
}
```
这段代码处理的逻辑不算复杂，功能也不多，但是还是有很多值得学习的地方，首先可以看看是如何处理边界条件的。可以看到两个边界条件都是用 guard 语法来处理的。
```swift
guard !stringKey.isEmpty else { return stringKey }

// Find the first non-underscore character
guard let firstNonUnderscore = stringKey.index(where: { $0 != "_" }) else {
    // Reached the end without finding an _
    return stringKey
}
```
第一个是判断空，第二个是通过 String 的 public func index(where predicate: (Character) throws -> Bool) rethrows -> String.Index?  这个函数来看字符串里是否包含了 ‘_’ 符号，如果没有包含就直接返回原 String 值。这个函数的参数就是一个自定义返回布尔值的 block，返回 true 即刻返回不再继续遍历了，可见苹果对于性能一点也不浪费。

然后这个返回的 index 值还有个作用就是可以得到 ‘_’ 符号在最前面后第一个非 ‘_’ 符号的字符。因为需求如此，不需要把最前面和最后面的 ‘_’ 转驼峰，但是前面和后面的 ‘_’ 符号个数又不一定，所以需要得到前面 ‘_’ 符号和后面的范围。

那么得到前面的范围后，后面的苹果是怎么做的呢？
```swift
// Find the last non-underscore character
var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
    stringKey.formIndex(before: &lastNonUnderscore);
}
```
这里正好可以看到对 String 的 public func formIndex(before i: inout String.Index) 函数的应用，这里的参数定义为 inout 的作用是能够在函数里对这个参数不用通过返回的方式直接修改生效。这个函数的作用就是移动字符的 index，before 是往前移动，after 是往后移动。

上面的代码就是先找到整个字符串的最后的 index 然后开始从后往前找，找到不是 ‘_’ 符号时跳出这个 while，同时还要满足不超过 lastNonUnderscore 的范围。

在接下内容之前可以考虑这样一个问题，为什么在做前面的判断时为什么不用 public func formIndex(after i: inout String.Index) 这个方法，after 不是代表从开始往后移动遍历么，也可以达到找到第一个不是 ‘_’ 的字符就停止的效果。

苹果真是双枪老太婆，一击两发，既解决了边界问题又能解决一个需求，代码有了优化，代码量还减少了。其实面试过程中通常都会有些算法题的环节，很多人都以为只要有了解决思路或者写出简单的处理代码就可以了，我碰到了一些的面试人甚至用中文一条条写出思路以为就完事了。其实算法题的考察是分为两种的，一种是考智商的，就是解决办法很多或者解决办法很难，能够想到解法或者最优解是比较困难的，这样的题适合那些在面谈过程中能觉得实力和深度不错的人，通过这些题同时还能更多为判断面试人是否更具创造力，属于拔尖的考法。还有种是考严谨和实际项目能力的，这种更多是考察边界条件的处理，逻辑的严谨还有对代码优化的处理，这种题的解法和逻辑会比较简单。

_convertFromSnakeCase 这个枚举的静态函数会在创建 container 的时候调用，具体使用的函数是 _JSONKeyedDecodingContainer，在它的初始化方法里会判断  decoder.options.keyDecodingStrategy  这个枚举值，满足 convertFromSnakeCase 就会调用那个静态函数了。调用的时候还要注意一个处理就是转换成驼峰后的 key 可能会和已有命名重名，那么就需要选择进行一个选择，苹果的选择是第一个。实现方式如下：
```swift
self.container = Dictionary(container.map {
    key, value in (JSONDecoder.KeyDecodingStrategy._convertFromSnakeCase(key), value)
}, uniquingKeysWith: { (first, _) in first })
```
这里遇到一个 Dictionary 的初始化函数 
```swift
public init<S>(_ keysAndValues: S, uniquingKeysWith combine: (Dictionary.Value, Dictionary.Value) throws -> Dictionary.Value) rethrows where S : Sequence, S.Element == (Key, Value)
```
这个函数就是专门用来处理上面的重复 key 的问题。如果要选择最后一个 key 的值用这个函数也会很容易。
```swift
let pairsWithDuplicateKeys = [("a", 1), ("b", 2), ("a", 3), ("b", 4)]

let firstValues = Dictionary(pairsWithDuplicateKeys,
                             uniquingKeysWith: { (first, _) in first })
// ["b": 2, "a": 1]
let lastValues = Dictionary(pairsWithDuplicateKeys,
                            uniquingKeysWith: { (_, last) in last })
// ["b": 4, "a": 3]
```

## 枚举定义 block
KeyEncodingStrategy 还可以自定义 codingKey
```swift
case custom((_ codingPath: [CodingKey]) -> CodingKey)
```
在 container 初始化时会调用这个 block 来进行 key 的转换，同样如果转换后出现重复 key 也会和 convertFromSnakeCase 一样选择第一个。这里可以看到 Swift 里的枚举还能够定义一个 block 方便自定义处理自己特定规则，这样就可以完全抛弃以前的那种覆盖 Codable 协议默认实现的方式了。

## inout
上面提到了 public func formIndex(before i: inout Index) 这个函数，那么跟着这个函数在源码里看看它的实现，这个函数是在这个文件里实现的 [swift/IndexSet.swift at master · apple/swift · GitHub](https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/IndexSet.swift)

找到这个方法时发现没有 inout 定义的同名函数也还在那里
```swift
public func index(before i: Index) -> Index {
    if i.value == i.extent.lowerBound {
        // Move to the next range
        if i.rangeIndex == 0 {
            // We have no more to go
            return Index(value: i.value, extent: i.extent, rangeIndex: i.rangeIndex, rangeCount: i.rangeCount)
        } else {
            let rangeIndex = i.rangeIndex - 1
            let rangeCount = i.rangeCount
            let extent = _range(at: rangeIndex)
            let value = extent.upperBound - 1
            return Index(value: value, extent: extent, rangeIndex: rangeIndex, rangeCount: rangeCount)
        }
    } else {
        // Move to the previous value in this range
        return Index(value: i.value - 1, extent: i.extent, rangeIndex: i.rangeIndex, rangeCount: i.rangeCount)
    }
}

public func formIndex(before i: inout Index) {
    if i.value == i.extent.lowerBound {
        // Move to the next range
        if i.rangeIndex == 0 {
            // We have no more to go
        } else {
            i.rangeIndex -= 1
            i.extent = _range(at: i.rangeIndex)
            i.value = i.extent.upperBound - 1
        }
    } else {
        // Move to the previous value in this range
        i.value -= 1
    }
}
```
这两个函数的实现最直观的感受就是 inout 的少了三个 return。还有一个好处就是值类型参数 i 可以以引用方式传递，不需要 var 和 let 来修饰

当然 inout 还有一个好处在上面的函数里没有体现出来，那就是可以方便对多个值类型数据进行修改而不需要一一指明返回。


# 网络请求
说到网络请求，在 Objective-C 世界里基本都是用的 AFNetworking [GitHub - AFNetworking/AFNetworking: A delightful networking framework for iOS, macOS, watchOS, and tvOS.](https://github.com/AFNetworking/AFNetworking) 在 Swift 里就是 Alamofire [GitHub - Alamofire/Alamofire: Elegant HTTP Networking in Swift](https://github.com/Alamofire/Alamofire) 。我在 Swift 1.0 之前 beta 版本时就注意到 Alamofire 库里，那时还是 Mattt Thompson 一个人在写，文件也只有一个。如今功能已经多了很多，但代码量依然不算太大。我在做 HTN 项目时对于网络请求的需求不是那么大，但是也有，于是开始的时候就是简单的使用 URLSession 来实现了一下网路请求，就是想直接拉下接口下发的 JSON 数据。

开始结合着前面解析 JSON 的方法，我这么写了个网络请求：
```swift
struct WebJSON:Codable {
    var name:String
    var node:String
    var version: Int?
}
let session = URLSession.shared
let request:URLRequest = NSURLRequest.init(url: URL(string: "http://www.starming.com/api.php?get=testjson")!) as URLRequest
let task = session.dataTask(with: request) { (data, res, error) in
    if (error == nil) {
        let decoder = JSONDecoder()
        do {
            print("解析 JSON 成功")
            let jsonModel = try decoder.decode(WebJSON.self, from: data!)
            print(jsonModel)
        } catch {
            print("解析 JSON 失败")
        }
    }
}
```
这么写是 ok 的，能够成功请求得到 JSON 数据然后转换成对应的结构数据。不过如果还有另外几处也要进行网络请求，拿这一坨代码不是要到处写了。那么先看看 Alamofire 干这个活是什么样子的？
```swift
Alamofire.request("https://httpbin.org/get").responseData { response in
    if let data = response.data {
        let decoder = JSONDecoder()
        do {
            print("解析 JSON 成功")
            let jsonModel = try decoder.decode(H5Editor.self, from: data)
        } catch {
            print("解析 JSON 失败")
        }
    }
}
```
Alamofire 有 responseJSON 的方法，不过解完是个字典，用的时候需要做很多容错判断很不方便，所以还是要使用 JSONDecoder 或者其它第三方库。不过 Alamofire 的写法已经做了一些简化，当然里面还实现了更多的功能，我待会再说，现在我的主要任务是简化调用。于是动手改改先前的实现，学习 Alamofire 的做法，首先创建一个类，然后简化掉 request 写法，再建个 block 方便请求完成后的数据返回处理，最后使用泛型支持不同 struct 的数据统一返回。写完后，我给这个网络类起个名字叫 SMNetWorking 这个类实现如下：
```swift
open class SMNetWorking<T:Codable> {
    open let session:URLSession
    
    typealias CompletionJSONClosure = (_ data:T) -> Void
    var completionJSONClosure:CompletionJSONClosure =  {_ in }
    
    public init() {
        self.session = URLSession.shared
    }
    
    //JSON的请求
    func requestJSON(_ url: SMURLNetWorking,
                     doneClosure:@escaping CompletionJSONClosure
                    ) {
        self.completionJSONClosure = doneClosure
        let request:URLRequest = NSURLRequest.init(url: url.asURL()) as URLRequest
        let task = self.session.dataTask(with: request) { (data, res, error) in
            if (error == nil) {
                let decoder = JSONDecoder()
                do {
                    print("解析 JSON 成功")
                    let jsonModel = try decoder.decode(T.self, from: data!)
                    self.completionJSONClosure(jsonModel)
                } catch {
                    print("解析 JSON 失败")
                }
                
            }
        }
        task.resume()
    }
    
}

/*----------Protocol----------*/
protocol SMURLNetWorking {
    func asURL() -> URL
}

/*----------Extension---------*/
extension String: SMURLNetWorking {
    public func asURL() -> URL {
        guard let url = URL(string:self) else {
            return URL(string:"http:www.starming.com")!
        }
        return url
    }
}
```
这样调用起来就简单得多了，看起来如下：
```swift
SMNetWorking<WModel>().requestJSON("https://httpbin.org/get") { (jsonModel) in
    print(jsonModel)
}
```
当然这样写起来是简单多了，特别是请求不同的接口返回不同结构时，本地定义了很多的 model 结构体，那么请求时只需要指明不同的 model 类型，block 里就能够直接返回对应的值。

默认都按照 GET 方法请求，在实际项目中会用到其它比如 POST 等方法，Alamofire 的做法是这样的：
```swift
/// HTTP method definitions.
///
/// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}
```
会先定义一个枚举，依据的标准也列在了注释里。使用起来是这样的：
```swift
Alamofire.request("https://httpbin.org/get") // method defaults to `.get`

Alamofire.request("https://httpbin.org/post", method: .post)
Alamofire.request("https://httpbin.org/put", method: .put)
Alamofire.request("https://httpbin.org/delete", method: .delete)
```
可以看出在 request 方法里有个可选参数，设置完会给 NSURLRequest 的 httpMethod 的这个可选属性附上设置的值。
```swift
public init(url: URLConvertible, method: HTTPMethod, headers: HTTPHeaders? = nil) throws {
    let url = try url.asURL()
    
    self.init(url: url)
    
    httpMethod = method.rawValue
    
    if let headers = headers {
        for (headerField, headerValue) in headers {
            setValue(headerValue, forHTTPHeaderField: headerField)
        }
    }
}
```

那么接下来我在 SMNetWorking 类里也加上这个功能，先定义一个枚举：
```swift
enum HTTPMethod: String {
    case GET,OPTIONS,HEAD,POST,PUT,PATCH,DELETE,TRACE,CONNECT
}
```
利用枚举的字符串协议特性，可以将枚举名直接转值的字符串，可以通过这种方式简化枚举定义。

翻下 NSURLRequest 提供的那些可选设置项还不少，如果把这些设置都做成一个个可配参数那么后期维护会非常麻烦。所以我打算使用链式来弄。先 fix HTTPMethod 这个。
```swift
//链式方法
//HTTPMethod 的设置
func httpMethod(_ md:HTTPMethod) -> SMNetWorking {
    self.op.httpMethod = md
    return self
}
```
这里的 op 是个结构体，专门用来存放这些可选项的值的。完整的代码可以在这里看到 [HTN/SMNetWorking.swift at master · ming1016/HTN · GitHub](https://github.com/ming1016/HTN/blob/master/HTNSwift/HTNSwift/Core/HTNFundation/SMNetWorking.swift)

使用起来也很方便：
```swift
SMNetWorking<WModel>().method(.POST).requestJSON("https://httpbin.org/get")
```
有了这样一个结构的设计后面扩展起来会非常方便，不过目前的功能是能够满足基本需求的，所以需要完善的比如对于 POST 请求需要的 HTTTP Body，还有 HTTP Headers 的自定义设置，Authentication 里的 HTTP Basic Authentication，Authentication with URLCredential 等，这些也可以先提供一个接口到外部去设置。所以可以先建个 block 把 URLRequest 提供出去由外围设置。

弄完后的使用效果如下：
```swift
SMNetWorking<WModel>().method(.POST).configRequest { (request) in
    //设置 request
}.requestJSON("https://httpbin.org/get")
```

就刚才提到的请求参数来说，Alamofire 是定义了一个 ParameterEncoding 协议，协议里规定一个统一处理的方法 func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest 这样就可以对多种情况做一样的返回处理了。从遵循这个协议的结构体可以看到 URL，JSON 和 PropertyList 都遵循了，那么从实现这个协议的 encode 函数的实现里可以看到他们都是殊途同归到 request 的 httpBody 里。可以拿 URLEncoding 看看具体实现：
```swift
public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
    var urlRequest = try urlRequest.asURLRequest()
    
    guard let parameters = parameters else { return urlRequest }
    
    if let method = HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET"), encodesParametersInURL(with: method) {
        guard let url = urlRequest.url else {
            throw AFError.parameterEncodingFailed(reason: .missingURL)
        }
        
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
            urlComponents.percentEncodedQuery = percentEncodedQuery
            urlRequest.url = urlComponents.url
        }
    } else {
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpBody = query(parameters).data(using: .utf8, allowLossyConversion: false)
    }
    
    return urlRequest
}
```


# 泛型协议式编程
对于目前 HTN 项目来说，请求到了数据，将 JSON 解析生成了对应的 Struct，那么下一步就是要把这个结构化的数据生成不同平台的代码，比如首先是 Objective-C 代码，然后是 Swift 代码，再然后会有 Java 代码。为了能够更好的合并多语言里重复的东西，我打算将处理生成不同语言的实现遵循相同的协议，这样就可以更规范更减少重复的实现这样的功能了。最终的效果如下：
```swift
SMNetWorking<H5Editor>().requestJSON("https://httpbin.org/get") { (jsonModel) in
        let reStr = H5EditorToFrame<H5EditorObjc>(H5EditorObjc()).convert(jsonModel)
        print(reStr)
}
```
如果是转成 Swift 的话就把 H5EditorObjc 改成 H5EditorSwift 就好了，他们遵循的都是 HTNMultilingualismSpecification 协议，其它语言依此类推。如果遇到统一的实现，可以建个协议的扩展，然后用统一函数去实现就好了。
```swift
extension HTNMultilingualismSpecification {
    //统一处理函数放这里
}
```

这种设计很类似类簇，比如我们熟悉的 NSString 就是这么设计的，根据初始化的不同，比如 initWith 什么的实例出来的对象是不同的，不过他们都遵循了相同的协议，所以我们在使用的时候没有感觉到差别。

HTNMultilingualismSpecification 这个协议里具体的定义在这里：[https://github.com/ming1016/HTN/blob/master/HTNSwift/HTNSwift/Core/HTNFundation/HTNMultilingualism.swift](https://github.com/ming1016/HTN/blob/master/HTNSwift/HTNSwift/Core/HTNFundation/HTNMultilingualism.swift)

回头看看 JSONDecoder 也是使用协议泛型式编程的一个典范。先看看 decode 函数的定义
```swift
open func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T
```
入参 type 是遵循了统一的 Decodable 协议的，那么就可以按照统一的方法去做处理，在内部实现时实际上 JSONDecoder 会代理给 _JSONDecoder 来实现具体逻辑的。所以在 decode 里的具体实现值类型转换的 unbox 函数都是在 _JSONDecoder 的扩展里实现的。unbox 会处理数字，字符串，布尔值这些基础数据类型，如果有其它层级的结构体也会一层层解下去， _JSONDecoder 的 _JSONDecodingStorage 通过保存最终得到完整的结构体。可以通过下面的代码看出支持这个过程的结构是怎么设计的。首先是 _JSONDecoder 的属性
```swift
/// The decoder's storage.
fileprivate var storage: _JSONDecodingStorage

/// Options set on the top-level decoder.
fileprivate let options: JSONDecoder._Options

/// The path to the current point in encoding.
fileprivate(set) public var codingPath: [CodingKey]

/// Contextual user-provided information for use during encoding.
public var userInfo: [CodingUserInfoKey : Any] {
    return self.options.userInfo
}
```
下面是初始化
```swift
/// Initializes `self` with the given top-level container and options.
fileprivate init(referencing container: Any, at codingPath: [CodingKey] = [], options: JSONDecoder._Options) {
    self.storage = _JSONDecodingStorage()
    self.storage.push(container: container)
    self.codingPath = codingPath
    self.options = options
}
```
这里可以看到 storage 在初始化时只 push 了顶层，push 的实现是：
```swift
fileprivate mutating func push(container: Any) {
    self.containers.append(container)
}
```
containers 在定义的时候是个 [Any] 数组，这样就允许 container 包含 container 也就是 struct 包含 struct 这样的结构。


# 函数式思想编程
在处理映射成表达式是设置布局属性最复杂的地方，需要考虑兼顾到各种表达式情况的处理，这样救需要设计一个类似 SnapKit 那样可链式调用设置值的结构，我先设计了一个结构体用来存一些可变的信息
```swift
struct PtEqual {
    var leftId = ""
    var left = WgPt.none
    var leftIdPrefix = "" //左前缀
    var rightType = PtEqualRightType.pt
    var rightId = ""
    var rightIdPrefix = ""
    var right = WgPt.none
    var rightFloat:Float = 0
    var rightInt:Int = 0
    var rightColor = ""
    var rightText = ""
    var rightString = ""
    var rightSuffix = ""
    
    var equalType = EqualType.normal
}
```

对于这些结构的设置会在 PtEqualC 这个类里去处理，把每个结构体属性的设置做成各个函数返回类本身即可实现。效果如下：
```swift
p.left(.width).leftId(id).leftIdPrefix("self.").rightType(.float).rightFloat(fl.viewPt.padding.left * 2).equalType(.decrease)
```
不过每次设置完后需要累加到最后返回的字符串里，这样一个过程其实也可以封装一个简单函数，比如 add()。这个怎么做能够更通用呢？比如希望支持不同的累加方法等。

那么可以先设计一个累加的 block 属性
```swift
typealias MutiClosure = (_ pe: PtEqual) -> String
var accumulatorLineClosure:MutiClosure = {_ in return ""}
```

添加累加字符串和换行标示
```swift
var mutiEqualStr = ""         //累加的字符串
var mutiEqualLineMark = "\n"  //换行标识
```

写个函数去设置这个 block 返回是类自己用于链式
```swift
//累计设置的 PtEqual 字符串
func accumulatorLine(_ closure:@escaping MutiClosure) -> PtEqualC {
    self.accumulatorLineClosure = closure
    return self
}
```
最后添加一个函数专门用来使用的
```swift
//执行累加动作
func add() {
    if filterBl {
        self.mutiEqualStr += accumulatorLineClosure(self.pe) + self.mutiEqualLineMark
    }
    _ = resetFilter()
}
```
我们看看用起来是什么效果：
```swift
 HTNMt.PtEqualC().accumulatorLine({ (pe) -> String in
    return self.ptEqualToStr(pe: pe)
}).filter({ () -> Bool in
    return vpt.isNormal
}).once({ (p) in
    p.left(.height).rightFloat(fl.viewPt.padding.top * 2).add()
})
```
细心的同学会注意到这里多了两个东西，一个是 filter， 一个是 once，这两个函数里的 block 会把一些通用逻辑进行封装。filter 的设置会根据返回决定是否处理后面的 block 或者结构体属性的设置，实现方式如下
```swift
//过滤条件
func filter(_ closure: FilterClosure) -> PtEqualC {
    filterBl = closure()
    return self
}
```
这里的 filterBl 是类的一个属性，后面会根据这个属性来决定动作是否继续执行。比如属性的设置会去判断
```swift
func left(_ wp:WgPt) -> PtEqualC {
    filterBl ? self.pe.left = wp : ()
    return self
}
```
once 这个函数也会判断
```swift
func once(_ closure:(_ pc: PtEqualC) -> Void) -> PtEqualC{
    if filterBl {
        closure(self)
    }
    _ = resetPe()
    _ = resetFilter()
    return self
}
```
同时 once 这个函数还会重置 filterBl 和重置设置的结构体，一箭三雕，相当于一个完整的设置周期。

有了这样一套函数，再复杂的设置过程以及逻辑处理都可以很清晰统一的表达出来，下面可以看一个复杂布局比如映射成原生表达式的代码效果：
```swift
//UIView *myViewContainer = [UIView new];
lyStr += newEqualStr(vType: .view, id: cId) + "\n"

//属性拼装
lyStr += HTNMt.PtEqualC().accumulatorLine({ (pe) -> String in
    return self.ptEqualToStr(pe: pe)
}).once({ (p) in
    p.left(.top).leftId(cId).end()
    if fl.isFirst {
        //myViewContainer.top = 0.0;
        p.rightType(.float).rightFloat(0).add()
    } else {
        //myViewContainer.top = lastView.bottom;
        p.rightId(fl.lastId + "Container").rightType(.pt).right(.bottom).add()
    }
}).once({ (p) in
    //myViewContainer.left = 0.0;
    p.leftId(cId).left(.left).rightType(.float).rightFloat(0).add()
}).once({ (p) in
    //myViewContainer.width = self.myView.width;
    p.leftId(cId).left(.width).rightType(.pt).rightIdPrefix("self.").rightId(id).right(.width).add()
    
    //myViewContainer.height = self.myView.height;
    p.left(.height).right(.height).add()
}).once({ (p) in
    //self.myView.width -= 16 * 2;
    p.left(.width).leftId(id).leftIdPrefix("self.").rightType(.float).rightFloat(fl.viewPt.padding.left * 2).equalType(.decrease).add()
    
    //self.myView.height -= 8 * 2;
    p.left(.height).rightFloat(fl.viewPt.padding.top * 2).add()
    
    //self.myView.top = 8;
    p.equalType(.normal).left(.top).rightType(.float).rightFloat(fl.viewPt.padding.top).add()
    
    //属性 verticalAlign 或 horizontalAlign 是 padding 和其它排列时的区别处理
    if fl.viewPt.horizontalAlign == .padding {
        //self.myView.left = 16;
        p.left(.left).rightFloat(fl.viewPt.padding.left).add()
    } else {
        //[self.myView sizeToFit];
        p.add(sizeToFit(elm: "self.\(id)"))
        p.left(.height).rightType(.pt).rightId(cId).right(.height).add()
        switch fl.viewPt.horizontalAlign {
        case .center:
            p.left(HTNMt.WgPt.center).right(.center).add()
        case .left:
            p.left(.left).right(.left).add()
        case .right:
            p.left(.right).right(.right).add()
        default:
            ()
        }
    }
}).mutiEqualStr
```

完整代码在这里：[https://github.com/ming1016/HTN/blob/master/HTNSwift/HTNSwift/H5Editor/H5EditorObjc.swift](https://github.com/ming1016/HTN/blob/master/HTNSwift/HTNSwift/H5Editor/H5EditorObjc.swift)

PS：最近在一个公司分享时有人希望推荐下 iOS 相关的博客，当时我推荐了孙源的博客，其实孙源也推荐过一个博客，当时由于地址没记住没有说出来，现在推荐给大家：[https://www.mikeash.com/](https://www.mikeash.com/) 他的twitter：[https://twitter.com/mikeash](https://twitter.com/mikeash?lang=en)


























































