---
title: 从 ReactiveCocoa 中能学到什么？不用此库也能学以致用
date: 2016-05-30 21:32:02
tags: [ReactiveCocoa, iOS]
categories: Programming
---
从知道ReactiveCocoa开始就发现对这个库有不同的声音，上次参加<T>技术沙龙时唐巧对在项目中已全面使用FRP的代码家提出为什么这种编程模型出现了这么长时间怎么像ReactiveCocoa这种完全按FRP编写的库没能够流行起来这个问题。对这个问题的回答一般都是门槛高，解决方法就是培训和通过熟悉以前的代码来快速入门。其实在我学习的过程中也发现确实会有这个问题，不过就算是有这样那样问题使得ReactiveCocoa这样的库没法大面积使用起来，也不能错失学习这种编程思想的机会。

如果不用这样的库，能不能将这种库的编程思想融入项目中，发挥出其优势呢？答案是肯定的。

FRP全称Function Reactive Programming，从名称就能够看出来这个模型关键就是Function Programming和Reactive Programming的结合。那么就先从函数式编程说起。说函数式编程前先聊聊链式编程，先看看一个开源Alert控件的头文件里定义的接口方法的写法。

```objectivec
/*
 *  自定义样式的alertView
 *
 */
+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                        completion:(PXAlertViewCompletionBlock)completion
                       cancelTitle:(NSString *)cancelTitle
                       otherTitles:(NSString *)otherTitles, ... NS_REQUIRES_NIL_TERMINATION;

/*
 * @param otherTitles Must be a NSArray containing type NSString, or set to nil for no otherTitles.
 */
+ (instancetype)showAlertWithTitle:(NSString *)title
                       contentView:(UIView *)view
                       secondTitle:(NSString *)secondTitle
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                       otherTitles:(NSArray *)otherTitles
                          btnStyle:(BOOL)btnStyle
                        completion:(PXAlertViewCompletionBlock)completion;

```

库里还有更多这样的组合，这么写是没有什么问题，无非是为了更方便组合使用而啰嗦了点，但是如果现在要添加一个AttributeString，那么所有组合接口都需要修改，每次调用接口方法如果不需要用Attribuite的地方还要去设置nil，这样会很不易于扩展。下面举个上报日志接口的例子。

```objectivec
@interface SMLogger : NSObject
//初始化
+ (SMLogger *)create;
//可选设置
- (SMLogger *)object:(id)obj;                        //object对象记录
- (SMLogger *)message:(NSString *)msg;               //描述
- (SMLogger *)classify:(SMProjectClassify)classify;  //分类
- (SMLogger *)level:(SMLoggerLevel)level;            //级别

//最后需要执行这个方法进行保存，什么都不设置也会记录文件名，函数名，行数等信息
- (void)save;

@end

//宏
FOUNDATION_EXPORT void SMLoggerDebugFunc(DCProjectClassify classify, DCLoggerLevel level, NSString *format, ...) NS_FORMAT_FUNCTION(3,4);
//debug方式打印日志，不会上报
#define SMLoggerDebug(frmt, ...) \
do { SMLoggerDebugFunc(SMProjectClassifyNormal,DCLoggerLevelDebug,frmt, ##__VA_ARGS__);} while(0)
//简单的上报日志
#define SMLoggerSimple(frmt, ...) \
do { SMLoggerDebugFunc(SMProjectClassifyNormal,SMLoggerLevelDebug,frmt, ##__VA_ARGS__);} while(0)
//自定义classify和level的日志，可上报
#define SMLoggerCustom(classify,level,frmt, ...) \
do { SMLoggerDebugFunc(classify,level,frmt, ##__VA_ARGS__);} while(0)
```

从这个头文件可以看出，对接口所需的参数不用将各种组合一一定义，只需要按照需要组合即可，而且做这个日志接口时发现后续维护过程中会增加越来越多的功能和需要更多的input数据。比如每条日志添加应用生命周期唯一编号，产品线每次切换唯一编号这样需要在特定场景需要添加的input支持。采用这种方式会更加易于扩展。写的时候会是[[[[DCLogger create] message:@"此处必改"] classify:DCProjectClassifyTradeHome] save]; 这样，对于不是特定场所较通用的场景可以使用宏来定义，内部实现还是按照前者的来实现，看起来是[DCLogger loggerWithMessage:@"此处必改"];，这样就能够同时满足常用场景和特殊场景的调用需求。

有了链式编程这种易于扩展方式的编程方式再来构造函数式编程，函数编程主要思路就是用有输入输出的函数作为参数将运算过程尽量写成一系列嵌套的函数调用，下面我构造一个需求来看看函数式编程的例子。

```objectivec
typedef NS_ENUM(NSUInteger, SMStudentGender) {
    SMStudentGenderMale,
    SMStudentGenderFemale
};

typedef BOOL(^SatisfyActionBlock)(NSUInteger credit);

@interface SMStudent : NSObject

@property (nonatomic, strong) SMCreditSubject *creditSubject;

@property (nonatomic, assign) BOOL isSatisfyCredit;

+ (SMStudent *)create;
- (SMStudent *)name:(NSString *)name;
- (SMStudent *)gender:(SMStudentGender)gender;
- (SMStudent *)studentNumber:(NSUInteger)number;

//积分相关
- (SMStudent *)sendCredit:(NSUInteger(^)(NSUInteger credit))updateCreditBlock;
- (SMStudent *)filterIsASatisfyCredit:(SatisfyActionBlock)satisfyBlock;

@end
```

这个例子中，sendCredit的block函数参数会处理当前的积分这个数据然后返回给SMStudent记录下来，filterIsASatisfyCredit的block函数参数会处理是否达到合格的积分判断返回是或否的BOOL值给SMStudent记录下来。实现代码如下

```objectivec
    //present
    self.student = [[[[[SMStudent create]
                       name:@"ming"]
                      gender:SMStudentGenderMale]
                     studentNumber:345]
                    filterIsASatisfyCredit:^BOOL(NSUInteger credit){
                        if (credit >= 70) {
                            self.isSatisfyLabel.text = @"合格";
                            self.isSatisfyLabel.textColor = [UIColor redColor];
                            return YES;
                        } else {
                            self.isSatisfyLabel.text = @"不合格";
                            return NO;
                        }

                    }];

    @weakify(self);
    [[self.testButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);

        [self.student sendCredit:^NSUInteger(NSUInteger credit) {
            credit += 5;
            NSLog(@"current credit %lu",credit);
            [self.student.creditSubject sendNext:credit];
            return credit;
        }];
    }];

    [self.student.creditSubject subscribeNext:^(NSUInteger credit) {
        NSLog(@"第一个订阅的credit处理积分%lu",credit);
        self.currentCreditLabel.text = [NSString stringWithFormat:@"%lu",credit];
        if (credit < 30) {
            self.currentCreditLabel.textColor = [UIColor lightGrayColor];
        } else if(credit < 70) {
            self.currentCreditLabel.textColor = [UIColor purpleColor];
        } else {
            self.currentCreditLabel.textColor = [UIColor redColor];
        }
    }];

    [self.student.creditSubject subscribeNext:^(NSUInteger credit) {
        NSLog(@"第二个订阅的credit处理积分%lu",credit);
        if (!(credit > 0)) {
            self.currentCreditLabel.text = @"0";
            self.isSatisfyLabel.text = @"未设置";
        }
    }];
```

每次按钮点击都会增加5个积分，达到70个积分就算合格了。上面的例子里可以看到一个对每次积分变化有不同的观察者处理的操作代码，这里并没有使用ReactiveCocoa里的信号，而是自己实现了一个特定的积分的类似信号的对象，方法名也用的是一样的。实现这个对象也是用的函数式编程方式。下面我的具体的实现代码

```objectivec
@interface SMCreditSubject : NSObject

typedef void(^SubscribeNextActionBlock)(NSUInteger credit);

+ (SMCreditSubject *)create;

- (SMCreditSubject *)sendNext:(NSUInteger)credit;
- (SMCreditSubject *)subscribeNext:(SubscribeNextActionBlock)block;

@end

@interface SMCreditSubject()

@property (nonatomic, assign) NSUInteger credit;
@property (nonatomic, strong) SubscribeNextActionBlock subscribeNextBlock;
@property (nonatomic, strong) NSMutableArray *blockArray;

@end

@implementation SMCreditSubject

+ (SMCreditSubject *)create {
    SMCreditSubject *subject = [[self alloc] init];
    return subject;
}

- (SMCreditSubject *)sendNext:(NSUInteger)credit {
    self.credit = credit;
    if (self.blockArray.count > 0) {
        for (SubscribeNextActionBlock block in self.blockArray) {
            block(self.credit);
        }
    }
    return self;
}

- (SMCreditSubject *)subscribeNext:(SubscribeNextActionBlock)block {
    if (block) {
        block(self.credit);
    }
    [self.blockArray addObject:block];
    return self;
}

#pragma mark - Getter
- (NSMutableArray *)blockArray {
    if (!_blockArray) {
        _blockArray = [NSMutableArray array];
    }
    return _blockArray;
}
```

Demo地址：<https://github.com/ming1016/RACStudy>

主要思路就是subscribeNext时将参数block的实现输入添加到一个数组中，sendNext时记录输入的积分，同时遍历那个记录subscribeNext的block的数组使那些block再按照新积分再实现一次输入，达到更新积分通知多个subscriber来实现新值的效果。

除了block还可以将每次sendNext的积分放入一个数组记录每次的积分变化，在RAC中的Signal就是这样处理的，如下图，这样新加入的subscirber能够读取到积分变化历史记录。

所以不用ReactiveCocoa库也能够按照函数式编程方式改造现有项目达到同样的效果。

上面的例子也能够看出FRP的另一个响应式编程的特性。说响应式编程之前可以先看看我之前关于解耦的那篇文章里的Demo<https://github.com/ming1016/DecoupleDemo>，里面使用了Model作为连接视图，请求存储和控制器之间的纽带，通过KVO使它们能够通过Model的属性来相互监听来避免它们之间的相互依赖达到解耦的效果。

像上面的例子那样其实也能够达到同样的效果，创建一个Model然后通过各个Subject来贯穿视图层和数据层进行send值和多subscribe值的处理。

了解了这种编程模型，再去了解下ReactiveCocoa使用的三种设计模式就能够更容易的将它学以致用了，下面配上这三种贯穿ReactiveCocoa的设计模式，看这些图里的方法名是不是很眼熟。

ReactiveCocoa里面还有很多可以学习的地方，比如宏的运用，可以看看sunnyxx的那篇《Reactive Cocoa Tutorial [1] = 神奇的Macros》<http://blog.sunnyxx.com/2014/03/06/rac_1_macros/>