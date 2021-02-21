---
title: 使用Swift3开发了个macOS的程序可以检测出objc项目中无用方法，然后一键全部清理
date: 2016-11-17 21:51:58
tags: [Swift, macOS, iOS]
categories: Programming
---
当项目越来越大，引入第三方库越来越多，上架的APP体积也会越来越大，对于用户来说体验必定是不好的。在清理资源，编译选项优化，清理无用类等完成后，能够做而且效果会比较明显的就只有清理无用函数了。现有一种方案是根据Linkmap文件取到objc的所有类方法和实例方法。再用工具逆向可执行文件里引用到的方法名，求个差集列出无用方法。这个方案有些比较麻烦的地方，因为检索出的无用方法没法确定能够直接删除，还需要挨个检索人工判断是否可以删除，这样每次要清理时都需要这样人工排查一遍是非常耗时耗力的。

这样就只有模拟编译过程对代码进行深入分析才能够找出确定能够删除的方法。具体效果可以先试试看，程序代码在：<https://github.com/ming1016/SMCheckProject> 选择工程目录后程序就开始检索无用方法然后将其注释掉。

## 设置结构体 😚
首先确定结构，类似先把 *OC* 文件根据语法画出整体结构。先看看 *OC Runtime* 里是如何设计的结构体。
```c
struct objc_object {  
    Class isa  OBJC_ISA_AVAILABILITY;
};

/*类*/
struct objc_class {  
    Class isa  OBJC_ISA_AVAILABILITY;
#if !__OBJC2__
    Class super_class;
    const char *name;
    long version;
    long info;
    long instance_size;
    struct objc_ivar_list *ivars;
    struct objc_method_list **methodLists;
    struct objc_cache *cache;
    struct objc_protocol_list *protocols;
#endif
};

/*成员变量列表*/
struct objc_ivar_list {
    int ivar_count               
#ifdef __LP64__
    int space                    
#endif
    /* variable length structure */
    struct objc_ivar ivar_list[1]
}      

/*成员变量结构体*/
struct objc_ivar {
    char *ivar_name
    char *ivar_type
    int ivar_offset
#ifdef __LP64__
    int space      
#endif
}    

/*方法列表*/
struct objc_method_list {  
    struct objc_method_list *obsolete;
    int method_count;

#ifdef __LP64__
    int space;
#endif
    /* variable length structure */
    struct objc_method method_list[1];
};

/*方法结构体*/
struct objc_method {  
    SEL method_name;
    char *method_types;    /* a string representing argument/return types */
    IMP method_imp;
};
```
一个 class 只有少量函数会被调用，为了减少较大的遍历所以创建一个 *objc_cache* ，在找到一个方法后将 *method_name* 作为 key，将 *method_imp* 做值，再次发起时就可以直接在 cache 里找。

使用 swift 创建类似的结构体，做些修改
```swift
//文件
class File: NSObject {
    //文件
    public var type = FileType.FileH
    public var name = ""
    public var content = ""
    public var methods = [Method]() //所有方法
    public var imports = [Import]() //引入类
}

//引入
struct Import {
    public var fileName = ""
}

//对象
class Object {
    public var name = ""
    public var superObject = ""
    public var properties = [Property]()
    public var methods = [Method]()
}

//成员变量
struct Property {
    public var name = ""
    public var type = ""
}

struct Method {
    public var classMethodTf = false //+ or -
    public var returnType = ""
    public var returnTypePointTf = false
    public var returnTypeBlockTf = false
    public var params = [MethodParam]()
    public var usedMethod = [Method]()
    public var filePath = "" //定义方法的文件路径，方便修改文件使用
    public var pnameId = ""  //唯一标识，便于快速比较
}

class MethodParam: NSObject {
    public var name = ""
    public var type = ""
    public var typePointTf = false
    public var iName = ""
}

class Type: NSObject {
    //todo:更多类型
    public var name = ""
    public var type = 0 //0是值类型 1是指针
}
```swift

## 开始语法解析 😈
首先遍历目录下所有的文件。
```swift
let fileFolderPath = self.selectFolder()
let fileFolderStringPath = fileFolderPath.replacingOccurrences(of: "file://", with: "")
let fileManager = FileManager.default;
//深度遍历
let enumeratorAtPath = fileManager.enumerator(atPath: fileFolderStringPath)
//过滤文件后缀
let filterPath = NSArray(array: (enumeratorAtPath?.allObjects)!).pathsMatchingExtensions(["h","m"])
```

然后将注释排除在分析之外，这样做能够有效避免无用的解析。

分析是否需要按照行来切割，在 *@interface* ， *@end* 和 *@ implementation* ， *@end* 里面不需要换行，按照;符号，外部需要按行来。所以两种切割都需要。

先定义语法标识符
```swift
class Sb: NSObject {
    public static let add = "+"
    public static let minus = "-"
    public static let rBktL = "("
    public static let rBktR = ")"
    public static let asterisk = "*"
    public static let colon = ":"
    public static let semicolon = ";"
    public static let divide = "/"
    public static let agBktL = "<"
    public static let agBktR = ">"
    public static let quotM = "\""
    public static let pSign = "#"
    public static let braceL = "{"
    public static let braceR = "}"
    public static let bktL = "["
    public static let bktR = "]"
    public static let qM = "?"
    public static let upArrow = "^"

    public static let inteface = "@interface"
    public static let implementation = "@implementation"
    public static let end = "@end"
    public static let selector = "@selector"

    public static let space = " "
    public static let newLine = "\n"
}
```

接下来就要开始根据标记符号来进行切割分组了，使用 *Scanner* ，具体方式如下
```swift
//根据代码文件解析出一个根据标记符切分的数组
class func createOCTokens(conent:String) -> [String] {
    var str = conent

    str = self.dislodgeAnnotaion(content: str)

    //开始扫描切割
    let scanner = Scanner(string: str)
    var tokens = [String]()
    //Todo:待处理符号,.
    let operaters = [Sb.add,Sb.minus,Sb.rBktL,Sb.rBktR,Sb.asterisk,Sb.colon,Sb.semicolon,Sb.divide,Sb.agBktL,Sb.agBktR,Sb.quotM,Sb.pSign,Sb.braceL,Sb.braceR,Sb.bktL,Sb.bktR,Sb.qM]
    var operatersString = ""
    for op in operaters {
        operatersString = operatersString.appending(op)
    }

    var set = CharacterSet()
    set.insert(charactersIn: operatersString)
    set.formUnion(CharacterSet.whitespacesAndNewlines)

    while !scanner.isAtEnd {
        for operater in operaters {
            if (scanner.scanString(operater, into: nil)) {
                tokens.append(operater)
            }
        }

        var result:NSString?
        result = nil;
        if scanner.scanUpToCharacters(from: set, into: &result) {
            tokens.append(result as! String)
        }
    }
    tokens = tokens.filter {
        $0 != Sb.space
    }
    return tokens;
}
```

行解析的方法
```swift
//根据代码文件解析出一个根据行切分的数组
class func createOCLines(content:String) -> [String] {
    var str = content
    str = self.dislodgeAnnotaion(content: str)
    let strArr = str.components(separatedBy: CharacterSet.newlines)
    return strArr
}
```

## 根据结构将定义的方法取出 🤖
```objectivec
- (id)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path cacheTime:(NSInteger)cacheTime subDirectory:(NSString*)subDirectory;
```
这里按照语法规则顺序取出即可，将方法名，返回类型，参数名，参数类型记录。这里需要注意 *Block* 类型的参数
```objectivec
- (STMPartMaker *(^)(STMPartColorType))colorTypeIs;
```
这种类型中还带有括号的语法的解析，这里用到的方法是对括号进行计数，左括号加一右括号减一的方式取得完整方法。

获得这些数据后就可以开始检索定义的方法了。我写了一个类专门用来获得所有定义的方法
```swift
class func parsingWithArray(arr:Array<String>) -> Method {
    var mtd = Method()
    var returnTypeTf = false //是否取得返回类型
    var parsingTf = false //解析中
    var bracketCount = 0 //括弧计数
    var step = 0 //1获取参数名，2获取参数类型，3获取iName
    var types = [String]()
    var methodParam = MethodParam()
    //print("\(arr)")
    for var tk in arr {
        tk = tk.replacingOccurrences(of: Sb.newLine, with: "")
        if (tk == Sb.semicolon || tk == Sb.braceL) && step != 1 {
            var shouldAdd = false

            if mtd.params.count > 1 {
                //处理这种- (void)initWithC:(type)m m2:(type2)i, ... NS_REQUIRES_NIL_TERMINATION;入参为多参数情况
                if methodParam.type.characters.count > 0 {
                    shouldAdd = true
                }
            } else {
                shouldAdd = true
            }
            if shouldAdd {
                mtd.params.append(methodParam)
                mtd.pnameId = mtd.pnameId.appending("\(methodParam.name):")
            }

        } else if tk == Sb.rBktL {
            bracketCount += 1
            parsingTf = true
        } else if tk == Sb.rBktR {
            bracketCount -= 1
            if bracketCount == 0 {
                var typeString = ""
                for typeTk in types {
                    typeString = typeString.appending(typeTk)
                }
                if !returnTypeTf {
                    //完成获取返回
                    mtd.returnType = typeString
                    step = 1
                    returnTypeTf = true
                } else {
                    if step == 2 {
                        methodParam.type = typeString
                        step = 3
                    }

                }
                //括弧结束后的重置工作
                parsingTf = false
                types = []
            }
        } else if parsingTf {
            types.append(tk)
            //todo:返回block类型会使用.设置值的方式，目前获取用过方法方式没有.这种的解析，暂时作为
            if tk == Sb.upArrow {
                mtd.returnTypeBlockTf = true
            }
        } else if tk == Sb.colon {
            step = 2
        } else if step == 1 {
            if tk == "initWithCoordinate" {
                //
            }
            methodParam.name = tk
            step = 0
        } else if step == 3 {
            methodParam.iName = tk
            step = 1
            mtd.params.append(methodParam)
            mtd.pnameId = mtd.pnameId.appending("\(methodParam.name):")
            methodParam = MethodParam()
        } else if tk != Sb.minus && tk != Sb.add {
            methodParam.name = tk
        }

    }//遍历

    return mtd
}
```
这个方法大概的思路就是根据标记符设置不同的状态，然后将获取的信息放入定义的结构中。

## 使用过的方法的解析 😱
进行使用过的方法解析前需要处理的事情
* @“…” 里面的数据，因为这里面是允许我们定义的标识符出现的。
* 递归出文件中 import 所有的类，根据对类的使用可以清除无用的 import
* 继承链的获取。
* 解析获取实例化了的成员变量列表。在解析时需要依赖列表里的成员变量名和变量的类进行方法的完整获取。

简单的方法
```objectivec
[view update:status animation:YES];
```
从左到右按照 : 符号获取

方法嵌套调用，下面这种情况如何解析出
```objectivec
@weakify(self);
[[[[[[SMNetManager shareInstance] fetchAllFeedWithModelArray:self.feeds] map:^id(NSNumber *value) {
    @strongify(self);
    NSUInteger index = [value integerValue];
    self.feeds[index] = [SMNetManager shareInstance].feeds[index];
    return self.feeds[index];
}] doCompleted:^{
    //抓完所有的feeds
    @strongify(self);
    NSLog(@"fetch complete");
    //完成置为默认状态
    self.tbHeaderLabel.text = @"";
    self.tableView.tableHeaderView = [[UIView alloc] init];
    self.fetchingCount = 0;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //下拉刷新关闭
    [self.tableView.mj_header endRefreshing];
    //更新列表
    [self.tableView reloadData];
    //检查是否需要增加源
    if ([SMFeedStore defaultFeeds].count > self.feeds.count) {
        self.feeds = [SMFeedStore defaultFeeds];
        [self fetchAllFeeds];
    }
}] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(SMFeedModel *feedModel) {
    //抓完一个
    @strongify(self);
    self.tableView.tableHeaderView = self.tbHeaderView;
    //显示抓取状态
    self.fetchingCount += 1;
    self.tbHeaderLabel.text = [NSString stringWithFormat:@"正在获取%@...(%lu/%lu)",feedModel.title,(unsigned long)self.fetchingCount,(unsigned long)self.feeds.count];
    [self.tableView reloadData];
}];
```

一开始会想到使用递归，以前我做 *STMAssembleView* 时就是使用的递归，这样时间复杂度就会是 O(nlogn) ，这次我换了个思路，将复杂度降低到了 n ，思路大概是 创建一个字典，键值就是深度，从左到右深度的增加根据 *[* 符号，减少根据 *]* 符号，值会在 *[* 时创建一个 *Method* 结构体，根据]来完成结构体，将其添加到 *methods* 数组中 。

具体实现如下
```swift
class func parsing(contentArr:Array<String>, inMethod:Method) -> Method {
    var mtdIn = inMethod
    //处理用过的方法
    //todo:还要过滤@""这种情况
    var psBrcStep = 0
    var uMtdDic = [Int:Method]()
    var preTk = ""
    //处理?:这种条件判断简写方式
    var psCdtTf = false
    var psCdtStep = 0
    //判断selector
    var psSelectorTf = false
    var preSelectorTk = ""
    var selectorMtd = Method()
    var selectorMtdPar = MethodParam()

    uMtdDic[psBrcStep] = Method() //初始时就实例化一个method，避免在define里定义只定义]符号

    for var tk in contentArr {
        //selector处理
        if psSelectorTf {
            if tk == Sb.colon {
                selectorMtdPar.name = preSelectorTk
                selectorMtd.params.append(selectorMtdPar)
                selectorMtd.pnameId += "\(selectorMtdPar.name):"
            } else if tk == Sb.rBktR {
                mtdIn.usedMethod.append(selectorMtd)
                psSelectorTf = false
                selectorMtd = Method()
                selectorMtdPar = MethodParam()
            } else {
                preSelectorTk = tk
            }
            continue
        }
        if tk == Sb.selector {
            psSelectorTf = true
            selectorMtd = Method()
            selectorMtdPar = MethodParam()
            continue
        }
        //通常处理
        if tk == Sb.bktL {
            if psCdtTf {
                psCdtStep += 1
            }
            psBrcStep += 1
            uMtdDic[psBrcStep] = Method()
        } else if tk == Sb.bktR {
            if psCdtTf {
                psCdtStep -= 1
            }
            if (uMtdDic[psBrcStep]?.params.count)! > 0 {
                mtdIn.usedMethod.append(uMtdDic[psBrcStep]!)
            }
            psBrcStep -= 1
            //[]不配对的容错处理
            if psBrcStep < 0 {
                psBrcStep = 0
            }

        } else if tk == Sb.colon {
            //条件简写情况处理
            if psCdtTf && psCdtStep == 0 {
                psCdtTf = false
                continue
            }
            //dictionary情况处理@"key":@"value"
            if preTk == Sb.quotM || preTk == "respondsToSelector" {
                continue
            }
            let prm = MethodParam()
            prm.name = preTk
            if prm.name != "" {
                uMtdDic[psBrcStep]?.params.append(prm)
                uMtdDic[psBrcStep]?.pnameId = (uMtdDic[psBrcStep]?.pnameId.appending("\(prm.name):"))!
            }
        } else if tk == Sb.qM {
            psCdtTf = true
        } else {
            tk = tk.replacingOccurrences(of: Sb.newLine, with: "")
            preTk = tk
        }
    }

    return mtdIn
}
```
在设置 *Method* 结构体时将参数名拼接起来成为 *Method* 的识别符用于后面处理时的快速比对。

解析使用过的方法时有几个问题需要注意下
1.在方法内使用的方法，会有 *respondsToSelector* ， *@selector* 还有条件简写语法的情况需要单独处理下。
2.在 *#define* 里定义使用了方法
```objectivec
#define CLASS_VALUE(x)    [NSValue valueWithNonretainedObject:(x)]
```

## 找出无用方法 😄
获取到所有使用方法后进行去重，和定义方法进行匹对求出差集，即全部未使用的方法。

## 去除无用方法 😎
比对后获得无用方法后就要开始注释掉他们了。遍历未使用的方法，根据先前 *Method* 结构体中定义了方法所在文件路径，根据文件集结构和File的结构体，可以避免 IO ，直接获取方法对应的文件内容和路径。
对文件内容进行行切割，逐行检测方法名和参数，匹对时开始对行加上注释， h 文件已;符号为结束， m 文件会对大括号进行计数，逐行注释。实现的方法具体如下：
```swift
//删除指定的一组方法
class func delete(methods:[Method]) {
    print("无用方法")
    for aMethod in methods {
        print("\(File.desDefineMethodParams(paramArr: aMethod.params))")

        //开始删除
        //continue
        var hContent = ""
        var mContent = ""
        var mFilePath = aMethod.filePath
        if aMethod.filePath.hasSuffix(".h") {
            hContent = try! String(contentsOf: URL(string:aMethod.filePath)!, encoding: String.Encoding.utf8)
            //todo:因为先处理了h文件的情况
            mFilePath = aMethod.filePath.trimmingCharacters(in: CharacterSet(charactersIn: "h")) //去除头尾字符集
            mFilePath = mFilePath.appending("m")
        }
        if mFilePath.hasSuffix(".m") {
            do {
                mContent = try String(contentsOf: URL(string:mFilePath)!, encoding: String.Encoding.utf8)
            } catch {
                mContent = ""
            }

        }

        let hContentArr = hContent.components(separatedBy: CharacterSet.newlines)
        let mContentArr = mContent.components(separatedBy: CharacterSet.newlines)
        //print(mContentArr)
        //----------------h文件------------------
        var psHMtdTf = false
        var hMtds = [String]()
        var hMtdStr = ""
        var hMtdAnnoStr = ""
        var hContentCleaned = ""
        for hOneLine in hContentArr {
            var line = hOneLine.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            if line.hasPrefix(Sb.minus) || line.hasPrefix(Sb.add) {
                psHMtdTf = true
                hMtds += self.createOCTokens(conent: line)
                hMtdStr = hMtdStr.appending(hOneLine + Sb.newLine)
                hMtdAnnoStr += "//-----由SMCheckProject工具删除-----\n//"
                hMtdAnnoStr += hOneLine + Sb.newLine
                line = self.dislodgeAnnotaionInOneLine(content: line)
                line = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } else if psHMtdTf {
                hMtds += self.createOCTokens(conent: line)
                hMtdStr = hMtdStr.appending(hOneLine + Sb.newLine)
                hMtdAnnoStr += "//" + hOneLine + Sb.newLine
                line = self.dislodgeAnnotaionInOneLine(content: line)
                line = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } else {
                hContentCleaned += hOneLine + Sb.newLine
            }

            if line.hasSuffix(Sb.semicolon) && psHMtdTf{
                psHMtdTf = false

                let methodPnameId = ParsingMethod.parsingWithArray(arr: hMtds).pnameId
                if aMethod.pnameId == methodPnameId {
                    hContentCleaned += hMtdAnnoStr

                } else {
                    hContentCleaned += hMtdStr
                }
                hMtdAnnoStr = ""
                hMtdStr = ""
                hMtds = []
            }


        }
        //删除无用函数
        try! hContentCleaned.write(to: URL(string:aMethod.filePath)!, atomically: false, encoding: String.Encoding.utf8)

        //----------------m文件----------------
        var mDeletingTf = false
        var mBraceCount = 0
        var mContentCleaned = ""
        var mMtdStr = ""
        var mMtdAnnoStr = ""
        var mMtds = [String]()
        var psMMtdTf = false
        for mOneLine in mContentArr {
            let line = mOneLine.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            if mDeletingTf {
                let lTokens = self.createOCTokens(conent: line)
                mMtdAnnoStr += "//" + mOneLine + Sb.newLine
                for tk in lTokens {
                    if tk == Sb.braceL {
                        mBraceCount += 1
                    }
                    if tk == Sb.braceR {
                        mBraceCount -= 1
                        if mBraceCount == 0 {
                            mContentCleaned = mContentCleaned.appending(mMtdAnnoStr)
                            mMtdAnnoStr = ""
                            mDeletingTf = false
                        }
                    }
                }

                continue
            }


            if line.hasPrefix(Sb.minus) || line.hasPrefix(Sb.add) {
                psMMtdTf = true
                mMtds += self.createOCTokens(conent: line)
                mMtdStr = mMtdStr.appending(mOneLine + Sb.newLine)
                mMtdAnnoStr += "//-----由SMCheckProject工具删除-----\n//" + mOneLine + Sb.newLine
            } else if psMMtdTf {
                mMtdStr = mMtdStr.appending(mOneLine + Sb.newLine)
                mMtdAnnoStr += "//" + mOneLine + Sb.newLine
                mMtds += self.createOCTokens(conent: line)
            } else {
                mContentCleaned = mContentCleaned.appending(mOneLine + Sb.newLine)
            }

            if line.hasSuffix(Sb.braceL) && psMMtdTf {
                psMMtdTf = false
                let methodPnameId = ParsingMethod.parsingWithArray(arr: mMtds).pnameId
                if aMethod.pnameId == methodPnameId {
                    mDeletingTf = true
                    mBraceCount += 1
                    mContentCleaned = mContentCleaned.appending(mMtdAnnoStr)
                } else {
                    mContentCleaned = mContentCleaned.appending(mMtdStr)
                }
                mMtdStr = ""
                mMtdAnnoStr = ""
                mMtds = []
            }

        } //m文件

        //删除无用函数
        if mContent.characters.count > 0 {
            try! mContentCleaned.write(to: URL(string:mFilePath)!, atomically: false, encoding: String.Encoding.utf8)
        }

    }
}
```

完整代码在：<https://github.com/ming1016/SMCheckProject> 这里。

## 后记 🦁
有了这样的结构数据就可以模拟更多人工检测的方式来检测项目。

通过获取的方法结合获取类里面定义的局部变量和全局变量，在解析过程中模拟引用的计数来分析循环引用等等类似这样的检测。
通过获取的类的完整结构还能够将其转成JavaScriptCore能解析的js语法文件等等。

## 对于APP瘦身的一些想法 👽
瘦身应该从平时开发时就需要注意。除了功能和组件上的复用外还需要对堆栈逻辑进行封装以达到代码压缩的效果。

比如使用ReactiveCocoa和RxSwift这样的函数响应式编程库提供的方法和编程模式进行

对于UI的视图逻辑可以使用一套统一逻辑压缩代码使用DSL来简化写法等。





