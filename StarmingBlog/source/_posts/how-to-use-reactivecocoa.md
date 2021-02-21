---
title: iOS函数响应式编程以及ReactiveCocoa的使用
date: 2016-08-09 21:44:10
tags: [ReactiveCocoa, iOS]
categories: Programming
---
打算在项目中大面积使用RAC来开发，所以整理一些常用的实践范例和比较完整的api说明方便开发时随时查阅

# 声明式编程泛型Declarative programming
函数反应式编程是声明式编程的子编程范式之一

# 高阶函数
需要满足两个条件
* 一个或者多个函数作为输入。
* 有且仅有一个函数输出。

objectivec里使用block作为函数
```objectivec
[array enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop)
{
    NSLog(@"%@",number);
}];
```

## 映射map
```objectivec
NSArray * mappedArray = [array rx_mapWithBlock:^id(id each){
    return @(pow([each integerValue],2));
}];
```

## 过滤filter
```objectivec
NSArray *filteredArray = [array rx_filterWithBlock:^BOOL(id each){
    return ([each integerValue] % 2 == 0);
}]
```

## 折叠fold
```objectivec
[[array rx_mapWithBlock:^id (id each){
        return [each stringValue];
    }] rx_foldInitialValue:@"" block:^id (id memo , id each){
        return [memo stringByAppendingString:each];
}];
```

## Currying
用函数生成另一个函数
```Swift
func filterGenerator(lastnameCondition: String) -> (Staff) -> (Bool) {
    return {staff in
        return staff.lastname == lastnameCondition
    }
}

let filterWang = filterGenerator("Wang")
let filterHu = filterGenerator("Hu")

staffs.filter(filterHu)
```

# RAC中使用高阶函数
## 映射
```objectivec
NSArray *array = @[ @1, @2, @3 ];
RACSequence * stream = [array rac_sequence];
//RACSequence是一个RACStream的子类。
[stream map:^id (id value){
    return @(pow([value integerValue], 2));
}];
//RACSequence有一个方法返回数组:array
NSLog(@"%@",[stream array]);

//避免污染变量的作用域
NSLog(@"%@",[[[array rac_sequence] map:^id (id value){
                    return @(pow([value integerValue], 2));
                }] array]);
```

## 过滤
```objectivec
NSLog(@"%@", [[[array rac_sequence] filter:^BOOL (id value){
                        return [value integerValue] % 2 == 0;
                    }] array]);
```

## 折叠
```objectivec
NSLog(@"%@",[[[array rac_sequence] map:^id (id value){
                    return [value stringValue];
                }] foldLeftWithStart:@"" reduce:^id (id accumulator, id value){
                    return [accumulator stringByAppendingString:value];
            }]);
```

## 绑定键值
```objectivec
RACSignal * validEmailSignal = [self.textField.rac_textSignal map:^id (NSString *value){
    return @([value rangeOfString:@"@"].location != NSNotFound);
}];

RAC(self.button, enabled) = validEmailSignal;

RAC(self.textField, textColor) = [validEmailSignal map: ^id (id value){
    if([value boolValue]){
        return [UIColor greenColor];
    }else{
        return [UIColor redColor];
    }
}];
```
![绑定键值图示](https://github.com/ming1016/study/blob/master/pic/CombinePipeline.png?raw=true)

## 实践
比较好的一个完整的RAC实践的例子：<https://github.com/ashfurrow/FunctionalReactivePixels>

### 网络请求生成对应model
```objectivec
+ (RACSignal *)importPhotos{
    RACReplaySubject * subject = [RACReplaySubject subject];
    NSURLRequest * request = [self popularURLRequest];
    [NSURLConnection sendAsynchronousRequest:request
                                    queue:[NSOperationQueue mainQueue]
                        completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError){
                            if (data) {
                                id results = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

                                [subject sendNext:[[[results[@"photos"] rac_sequence] map:^id(NSDictionary *photoDictionary){
                                    FRPPhotoModel * model = [FRPPhotoModel new];

                                    [self configurePhotoModel:model withDictionary:photoDictionary];
                                    [self downloadThumbnailForPhotoModel:model];

                                    return model;
                                }] array]];

                                [subject sendCompleted];
                            }
                            else{
                                [subject sendError:connectionError];
                            }
    }];

    return subject;

}
```

### 过滤相同大小的图片，取出他们的url，返回第一个
```objectivec
+ (NSString *)urlForImageSize:(NSInteger)size inDictionary:(NSArray *)array{
    return [[[[[array rac_sequence] filter:^ BOOL (NSDictionary * value){
        return [value[@"size"] integerValue] == size;
    }] map:^id (id value){
        return value[@"url"];
    }] array] firstObject];
}
```

### 观察model里的图片数据，进行为空过滤判断，将data转为UIImage，再把绑定新信号的值给对象的关键路径
```objectivec
- (void)setPhotoModel:(FRPPhotoModel *)photoModel{
    self.subscription = [[[RACObserver(photoModel, thumbnailData)
        filter:^ BOOL (id value){
            return value != nil;
        }] map:^id (id value){
            return [UIImage imageWithData:value];
        }] setKeyPath:@keypath(self.imageView, image) onObject:self.imageView];
}
```

### UITableViewCell复用时需要取消cell上各个组件的订阅
```objectivec
- (void)prepareForReuse {
    [super prepareForReuse];
    [self.subscription dispose], self.subscription = nil;
}
```

### Delegate的使用
```objectivec
//注意：你必须retain这个delegate对象，否则他们将会被释放，你将会得到一个EXC_BAD_ACCESS异常。添加下列私有属性到画廊视图控制器：
@property (nonatomic, strong) id collectionViewDelegate;

//同时你也需要导入RACDelegateProxy.h，因为他不是ReactiveCocoa的核心部分，不包含在ReactiveCocoa.h中。
RACDelegateProxy *viewControllerDelegate = [[RACDelegateProxy alloc]
                                    initWithProtocol:@protocol(FRPFullSizePhotoViewControllerDelegate)];

[[viewControllerDelegate rac_signalForSelector:@selector(userDidScroll:toPhotoAtIndex:)     fromProtocol:@protocol(FRPFullSizePhotoViewControllerDelegate)]
        subscribeNext:^(RACTuple *value){
            @strongify(self);
            [self.collectionView
                scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[value.second integerValue] inSection:0]
                atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                animated:NO];
        }];

self.collectionViewDelegate = [[RACDelegateProxy alloc] initWithProtocol:@protocol(UICollectionViewDelegate)];

[[self.collectionViewDelegate rac_signalForSelector:@selector(collectionView:didSelectItemAtIndexPath:)]
        subscribeNext:^(RACTuple *arguments) {
            @strongify(self);
            FRPFullSizePhotoViewController *viewController = [[FRPFullSizePhotoViewController alloc] initWithPhotoModels:self.photosArray currentPhotoIndex:[(NSIndexPath *)arguments.second item]];
            viewController.delegate = (id<FRPFullSizePhotoViewControllerDelegate>)viewControllerDelegate;

            [self.navigationController pushViewController:viewController animated:YES];

        }];
```

### 处理异常，完成执行刷新操作，异常打印日志，执行对应方法
```objectivec
RAC(self, photosArray) = [[[[FRPPhotoImporter importPhotos]
        doCompleted:^{
            @strongify(self);
            [self.collectionView reloadData];
        }] logError] catchTo:[RACSignal empty]];
```

### 网络请求处理数据，获取数据返回主线程
```objectivec
+ (RACSignal *)importPhotos {
    NSURLRequest *request = [self popularURLRequest];

    return [[[[[[NSURLConnection rac_sendAsynchronousRequest:request]
                reduceEach:^id(NSURLResponse *response , NSData *data){
                    //注意：我们可以用下面的reduceEach:替代使用RACTuple的第一个map:，以便提供编译时检查。
                    return data;
                }]
                deliverOn:[RACScheduler mainThreadScheduler]]
                map:^id (NSData *data) {
                    id results = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    return [[[results[@"photo"] rac_sequence]
                        map:^id (NSDictionary *photoDictionary) {
                            FRPPhotoModel *model = [FRPPhotoModel new];
                            [self configurePhotoModel:model withDictionary:photoDictionary];
                            [self downloadThumbnailForPhotoModel:model];
                            return model;
                        }] array];
                }] publish] autoconnect];
    //信号链条最末端的信号操作publish. publish返回一个RACMulitcastConnection,当信号连接上时，他将订阅该接收信号。autoconnect为我们做的是：当它返回的信号被订阅，连接到 该(订阅背后的)信号（underly signal）。
}
```

### 信号的信号Signal of signals，一个外部信号包含一个内部信号，在输出信号的subscribeNext:块中订阅内部信号，会引起嵌套麻烦。使用flattenMap后会生成一个新的信号，和先前信号平级，订阅会订阅到返回的新信号里的值。map方法也是创建一个新信号，但是会将返回的信号也当做值，这样就得不到真正需要的值了。
```objectivec
[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^RACStream *(id value) {
    return [self signInSignal];
}] subscribeNext:^(id x) {
    //x
    NSLog(@"Sign in result: %@", x);
}];
```

### 不同信号顺序链接，程序需要等待前一个信号发出完成事件（sendCompleted），然后再订阅下一个信号（then）
```objectivec
- (RACSignal *)requestAccessToTwitterSignal
{
    // 定义一个错误，如果用户拒绝访问则发送
    NSError *accessError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorAccessDenied userInfo:nil];

    // 创建并返回信号
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {

        // 请求访问twitter
        @strongify(self)
        [self.accountStore requestAccessToAccountsWithType:self.twitterAccountType
                                                   options:nil
                                                completion:^(BOOL granted, NSError *error) {
                                                    // 处理响应
                                                    if (!granted)
                                                    {
                                                        [subscriber sendError:accessError];
                                                    }
                                                    else
                                                    {
                                                        [subscriber sendNext:nil];
                                                        [subscriber sendCompleted];
                                                    }
                                                }];
        return nil;
    }];
}

//throttle可以避免连续输入造成的不必要的请求，then会忽略前一个信号的值，底层的实现是先过滤之前信号发的值，再使用concat连接then返回的信号。
[[[[[[[self requestAccessToTwitterSignal]
      then:^RACSignal *{
          @strongify(self)
          return self.searchText.rac_textSignal;
      }]
     filter:^BOOL(NSString *text) {
         @strongify(self)
         return [self isValidSearchText:text];
     }]
    throttle:0.5]
   flattenMap:^RACStream *(NSString *text) {
       @strongify(self)
       //flattenMap来将每个next事件映射到一个新的被订阅的信号
       return [self signalForSearchWithText:text];
   }]
  deliverOn:[RACScheduler mainThreadScheduler]]
 subscribeNext:^(NSDictionary *jsonSearchResult) {
     NSArray *statuses = jsonSearchResult[@"statuses"];
     NSArray *tweets = [statuses linq_select:^id(id tweet) {
         return [RWTweet tweetWithStatus:tweet];
     }];
     [self.resultsViewController displayTweets:tweets];
 } error:^(NSError *error) {
     NSLog(@"An error occurred: %@", error);
 }];
 - (RACSignal *)signalForSearchWithText:(NSString *)text {
    // 1 - define the errors
    NSError *noAccountsError = [NSError errorWithDomain:RWTwitterInstantDomain
                                                   code:RWTwitterInstantErrorNoTwitterAccounts
                                               userInfo:nil];
    NSError *invalidResponseError = [NSError errorWithDomain:RWTwitterInstantDomain
                                                        code:RWTwitterInstantErrorInvalidResponse
                                                        userInfo:nil];
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        SLRequest *request = [self requestforTwitterSearchWithText:text];
        NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:self.twitterAccountType];         if (twitterAccounts.count == 0) {
            [subscriber sendError:noAccountsError];
        } else {
            [request setAccount:[twitterAccounts lastObject]];
        [request performRequestWithHandler: ^(NSData *responseData,
                NSHTTPURLResponse *urlResponse, NSError *error) {
            if (urlResponse.statusCode == 200) {
                NSDictionary *timelineData = [NSJSONSerialization JSONObjectWithData:responseData
                                                options:NSJSONReadingAllowFragments
                                                  error:nil];
                [subscriber sendNext:timelineData];
                [subscriber sendCompleted];
            } else {
                [subscriber sendError:invalidResponseError];
            }
        }];
    }
    return nil;
    }];
}
```
![不同信号顺序链接](https://github.com/ming1016/study/blob/master/pic/CompletePipeline.png?raw=true)

### 异步加载图片
```objectivec
-(RACSignal *)signalForLoadingImage:(NSString *)imageUrl {

    RACScheduler *scheduler = [RACScheduler
                               schedulerWithPriority:RACSchedulerPriorityBackground];

    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        UIImage *image = [UIImage imageWithData:data];
        [subscriber sendNext:image];
        [subscriber sendCompleted];
        return nil;
    }] subscribeOn:scheduler];
}

cell.twitterAvatarView.image = nil;
[[[self signalForLoadingImage:tweet.profileImageUrl]
  deliverOn:[RACScheduler mainThreadScheduler]]
  subscribeNext:^(UIImage *image) {
   cell.twitterAvatarView.image = image;
  }];
```

### 观察viewModel里的tableView的数据键值和全部读取键值，只要有一个有新值就会调用
```objectivec
@weakify(self);
[[[RACSignal merge: @[RACObserve(self.viewModel,  tweets),
                     RACObserve(self.viewModel,  allTweetsLoaded)]]
    bufferWithTime: 0 onScheduler: [RACScheduler mainThreadScheduler]]
    subscribeNext: ^(id value) {
        @strongify(self);
        [self.tableView reloadData];
    }];
//bufferWithTime设置为0是为了避免同一时刻两个值被同时设置新值产生了table进行了两次reloadData
```

### 封装hook方法，某个selector被调用时，再执行一段指定代码和hook一样。
```objectivec
@weakify(self);
[[tableView rac_signalForSelector:@selector(layoutSubviews)]subscribeNext:^(id x) {
    @strongify(self);
    [self doSomethingBeforeTableViewLayoutSubviews];
}];
```

### 使用RACCommand来实现按钮的状态根据输入邮箱判断邮箱是否非法还有提交到服务器后出错处理等
Demo的github地址：<https://github.com/olegam/RACCommandExample>
```objectivec
- (void)bindWithViewModel {
  RAC(self.viewModel, email) =self.emailTextField.rac_textSignal;
  self.subscribeButton.rac_command = self.viewModel.subscribeCommand;
  RAC(self.statusLabel, text) =RACObserve(self.viewModel, statusMessage);
}

@interface SubscribeViewModel :NSObject
  @property(nonatomic, strong)RACCommand *subscribeCommand;  // writeto this property
  @property(nonatomic, strong) NSString *email;  // read from this property
  @property(nonatomic, strong) NSString *statusMessage;
@end

#import "SubscribeViewModel.h"
#import "AFHTTPRequestOperationManager+RACSupport.h"
#import"NSString+EmailAdditions.h"

static NSString *const kSubscribeURL =@"http://reactivetest.apiary.io/subscribers";

@interface SubscribeViewModel ()
@property(nonatomic, strong) RACSignal*emailValidSignal;
@end

@implementation SubscribeViewModel

- (id)init {
       self= [super init];
       if(self) {
            [self mapSubscribeCommandStateToStatusMessage];
       }
       returnself;
}

-(void)mapSubscribeCommandStateToStatusMessage {
       RACSignal *startedMessageSource = [self.subscribeCommand.executionSignals map:^id(RACSignal *subscribeSignal) {
              return NSLocalizedString(@"Sending request...", nil);
       }];

       RACSignal *completedMessageSource = [self.subscribeCommand.executionSignals flattenMap:^RACStream *(RACSignal *subscribeSignal) {
              return[[[subscribeSignal materialize] filter:^BOOL(RACEvent *event) {
                     return event.eventType == RACEventTypeCompleted;
              }] map:^id(id value) {
                     return NSLocalizedString(@"Thanks", nil);
              }];
       }];

       RACSignal*failedMessageSource = [[self.subscribeCommand.errors subscribeOn:[RACSchedulermainThreadScheduler]] map:^id(NSError *error) {
              return NSLocalizedString(@"Error :(", nil);
       }];

       RAC(self,statusMessage) = [RACSignal merge:@[startedMessageSource, completedMessageSource, failedMessageSource]];
}

- (RACCommand *)subscribeCommand {
       if(!_subscribeCommand) {
              @weakify(self);
              _subscribeCommand = [[RACCommand alloc] initWithEnabled:self.emailValidSignal signalBlock:^RACSignal *(id input) {
                     @strongify(self);
                     return [SubscribeViewModel postEmail:self.email];
              }];
       }
       return _subscribeCommand;
}

+ (RACSignal *)postEmail:(NSString *)email{
       AFHTTPRequestOperationManager*manager = [AFHTTPRequestOperationManager manager];
       manager.requestSerializer= [AFJSONRequestSerializer new];
       NSDictionary*body = @{@"email": email ?: @""};
       return [[[manager rac_POST:kSubscribeURL parameters:body] logError] replayLazily];
}

- (RACSignal *)emailValidSignal {
       if(!_emailValidSignal) {
              _emailValidSignal= [RACObserve(self, email) map:^id(NSString *email) {
                     return@([email isValidEmail]);
              }];
       }
       return _emailValidSignal;
}

@end
```

### 替换Delegate，直接使用RACSubject

# RAC内存管理
RAC会维护一个全局的信号集合，一个或多于一个订阅者就可用，所有订阅者都被移除了，信号就被释放了。

# RAC需要注意的内存问题
## 宏定义
```objectivec
- (void)viewDidLoad
{
    [super viewDidLoad];
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) { //1
        MTModel *model = [[MTModel alloc] init]; // MTModel有一个名为的title的属性
        [subscriber sendNext:model];
        [subscriber sendCompleted];
        return nil;
    }];
    self.flattenMapSignal = [signal flattenMap:^RACStream *(MTModel *model) { //2
        return RACObserve(model, title);
    }];
    [self.flattenMapSignal subscribeNext:^(id x) { //3
        NSLog(@"subscribeNext - %@", x);
    }];
}
```
上面的RACObserve会引起引用不释放的问题，通过RACObserve的定义来看看，里面会对self进行持有。
```objectivec
#define RACObserve(TARGET, KEYPATH) \
    ({ \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Wreceiver-is-weak\"") \
        __weak id target_ = (TARGET); \
        [target_ rac_valuesForKeyPath:@keypath(TARGET, KEYPATH) observer:self]; \
        _Pragma("clang diagnostic pop") \
    })
```

## Subject
对subject进行map这样的操作，这时就需要sendCompleted
```objectivec
- (void)viewDidLoad {
    [super viewDidLoad];
    RACSubject *subject = [RACSubject subject];
    [subject.rac_willDeallocSignal subscribeCompleted:^{
        NSLog(@"subject dealloc");
    }];

    [[subject map:^id(NSNumber *value) {
        return @([value integerValue] * 3);
    }] subscribeNext:^(id x) {
        NSLog(@"next = %@", x);
    }];
    [subject sendNext:@1];
}
```
但是为什么signal进行map操作，不sendCompleted而不会内存泄漏呢。因为调到bind的比如map、filter、merge、combineLatest、flattenMap等操作如果是RACSubject这样会持有订阅者的信号会产生内存泄漏需要sendCompleted。可以先看看bind的实现
```objectivec
- (RACSignal *)bind:(RACStreamBindBlock (^)(void))block {
    NSCParameterAssert(block != NULL);
    /*
     * -bind: should:
     *
     * 1. Subscribe to the original signal of values.
     * 2. Any time the original signal sends a value, transform it using the binding block.
     * 3. If the binding block returns a signal, subscribe to it, and pass all of its values through to the subscriber as they're received.
     * 4. If the binding block asks the bind to terminate, complete the _original_ signal.
     * 5. When _all_ signals complete, send completed to the subscriber.
     *
     * If any signal sends an error at any point, send that to the subscriber.
     */
    return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        RACStreamBindBlock bindingBlock = block();
        NSMutableArray *signals = [NSMutableArray arrayWithObject:self];
        // 此处省略了80行代码
        // ...
    }] setNameWithFormat:@"[%@] -bind:", self.name];
}
```
didSubscribe的开头，就创建了一个数组signals，并且持有了self，也就是源信号，也就是订阅者持有了信号，如果是Subject那么这种信号又会持有订阅者，这样就形成了循环引用。

下面看看sendCompleted如何修复的内存泄漏
```objectivec
void (^completeSignal)(RACSignal *, RACDisposable *) = ^(RACSignal *signal, RACDisposable *finishedDisposable) {
    BOOL removeDisposable = NO;
    @synchronized (signals) {
        [signals removeObject:signal]; //1
        if (signals.count == 0) {
            [subscriber sendCompleted]; //2
            [compoundDisposable dispose]; //3
        } else {
            removeDisposable = YES;
        }
    }
    if (removeDisposable) [compoundDisposable removeDisposable:finishedDisposable]; //4
};
```
从signals这个数组中移除传入的signal，也就是让订阅的signal不会持有subject这种信号。

还有replay这样的操作，因为这个方法返回的是一个RACReplaySubject
```objectivec
RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [subscriber sendNext:@1];
    [subscriber sendCompleted]; // 保证源信号发送完成
    return nil;
}];

RACSignal *replaySignal = [signal replay]; // 这里返回的其实是一个RACReplaySubject

[[replaySignal map:^id(NSNumber *value) {
    return @([value integerValue] * 3);
}] subscribeNext:^(id x) {
    NSLog(@"subscribeNext - %@", x);
}];
```

# 热信号冷信号
* 热信号是主动的，不订阅也能够按时发送。冷信号是被动的，只有订阅才会发送。
* 热信号可以有多个订阅者。冷信号只能够一对一，有不同订阅者，消息会从新完整发送。

# RAC的API手册

## 常见类

### RACSiganl 信号类。
* RACEmptySignal ：空信号，用来实现 RACSignal 的 +empty 方法；
* RACReturnSignal ：一元信号，用来实现 RACSignal 的 +return: 方法；
* RACDynamicSignal ：动态信号，使用一个 block - 来实现订阅行为，我们在使用 RACSignal 的 +createSignal: 方法时创建的就是该类的实例；
* RACErrorSignal ：错误信号，用来实现 RACSignal 的 +error: 方法；
* RACChannelTerminal ：通道终端，代表 RACChannel 的一个终端，用来实现双向绑定。

### RACSubscriber 订阅者

### RACDisposable 用于取消订阅或者清理资源，当信号发送完成或者发送错误的时候，就会自动触发它。
* RACSerialDisposable ：作为 disposable 的容器使用，可以包含一个 disposable 对象，并且允许将这个 disposable 对象通过原子操作交换出来；
* RACKVOTrampoline ：代表一次 KVO 观察，并且可以用来停止观察；
* RACCompoundDisposable ：它可以包含多个 disposable 对象，并且支持手动添加和移除 disposable 对象
* RACScopedDisposable ：当它被 dealloc 的时候调用本身的 -dispose 方法。

### RACSubject 信号提供者，自己可以充当信号，又能发送信号。订阅后发送
* RACGroupedSignal ：分组信号，用来实现 RACSignal 的分组功能；
* RACBehaviorSubject ：重演最后值的信号，当被订阅时，会向订阅者发送它最后接收到的值；
* RACReplaySubject ：重演信号，保存发送过的值，当被订阅时，会向订阅者重新发送这些值。可以先发送后订阅

### RACTuple 元组类,类似NSArray,用来包装值.

### RACSequence RAC中的集合类

### RACCommand RAC中用于处理事件的类，可以把事件如何处理,事件中的数据如何传递，包装到这个类中，他可以很方便的监控事件的执行过程。

### RACMulticastConnection 用于当一个信号，被多次订阅时，为了保证创建信号时，避免多次调用创建信号中的block，造成副作用，可以使用这个类处理。

### RACScheduler RAC中的队列，用GCD封装的。
* RACImmediateScheduler ：立即执行调度的任务，这是唯一一个支持同步执行的调度器；
* RACQueueScheduler ：一个抽象的队列调度器，在一个 GCD 串行列队中异步调度所有任务；
* RACTargetQueueScheduler ：继承自 RACQueueScheduler ，在一个以一个任意的 GCD 队列为 target 的串行队列中异步调度所有任务；
* RACSubscriptionScheduler ：一个只用来调度订阅的调度器。

## 常见用法
* rac_signalForSelector : 代替代理
* rac_valuesAndChangesForKeyPath: KVO
* rac_signalForControlEvents:监听事件
* rac_addObserverForName 代替通知
* rac_textSignal：监听文本框文字改变
* rac_liftSelector:withSignalsFromArray:Signals:当传入的Signals(信号数组)，每一个signal都至少sendNext过一次，就会去触发第一个selector参数的方法。

## 常见宏
* RAC(TARGET, [KEYPATH, [NIL_VALUE]])：用于给某个对象的某个属性绑定
* RACObserve(self, name) ：监听某个对象的某个属性,返回的是信号。
* @weakify(Obj)和@strongify(Obj)
* RACTuplePack ：把数据包装成RACTuple（元组类）
* RACTupleUnpack：把RACTuple（元组类）解包成对应的数据
* RACChannelTo 用于双向绑定的一个终端

## 常用操作方法
* flattenMap map 用于把源信号内容映射成新的内容。
* concat 组合 按一定顺序拼接信号，当多个信号发出的时候，有顺序的接收信号
* then 用于连接两个信号，当第一个信号完成，才会连接then返回的信号。
* merge 把多个信号合并为一个信号，任何一个信号有新值的时候就会调用
* zipWith 把两个信号压缩成一个信号，只有当两个信号同时发出信号内容时，并且把两个信号的内容合并成一个元组，才会触发压缩流的next事件。
* combineLatest:将多个信号合并起来，并且拿到各个信号的最新的值,必须每个合并的signal至少都有过一次sendNext，才会触发合并的信号。
* reduce聚合:用于信号发出的内容是元组，把信号发出元组的值聚合成一个值
* filter:过滤信号，使用它可以获取满足条件的信号.
* ignore:忽略完某些值的信号.
* distinctUntilChanged:当上一次的值和当前的值有明显的变化就会发出信号，否则会被忽略掉。
* take:从开始一共取N次的信号
* takeLast:取最后N次的信号,前提条件，订阅者必须调用完成，因为只有完成，就知道总共有多少信号.
* takeUntil:(RACSignal *):获取信号直到某个信号执行完成
* skip:(NSUInteger):跳过几个信号,不接受。
* switchToLatest:用于signalOfSignals（信号的信号），有时候信号也会发出信号，会在signalOfSignals中，获取signalOfSignals发送的最新信号。
* doNext: 执行Next之前，会先执行这个Block
* doCompleted: 执行sendCompleted之前，会先执行这个Block
* timeout：超时，可以让一个信号在一定的时间后，自动报错。
* interval 定时：每隔一段时间发出信号
* delay 延迟发送next。
* retry重试 ：只要失败，就会重新执行创建信号中的block,直到成功.
* replay重放：当一个信号被多次订阅,反复播放内容
* throttle节流:当某个信号发送比较频繁时，可以使用节流，在某一段时间不发送信号内容，过了一段时间获取信号的最新内容发出。

## UI - Category（常用汇总）

### rac_prepareForReuseSignal： 需要复用时用
* 相关UI: MKAnnotationView、UICollectionReusableView、UITableViewCell、UITableViewHeaderFooterView

### rac_buttonClickedSignal：点击事件触发信号
* 相关UI：UIActionSheet、UIAlertView

### rac_command：button类、刷新类相关命令替换
* 相关UI：UIBarButtonItem、UIButton、UIRefreshControl

### rac_signalForControlEvents: control event 触发
* 相关UI：UIControl

### rac_gestureSignal UIGestureRecognizer 事件处理信号
* 相关UI：UIGestureRecognizer

### rac_imageSelectedSignal 选择图片的信号
* 相关UI：UIImagePickerController

### rac_textSignal
* 相关UI：UITextField、UITextView

### 可实现双向绑定的相关API
* rac_channelForControlEvents: key: nilValue:
* 相关UI：UIControl类
* rac_newDateChannelWithNilValue:
* 相关UI：UIDatePicker
* rac_newSelectedSegmentIndexChannelWithNilValue:
* 相关UI：UISegmentedControl
* rac_newValueChannelWithNilValue:
* 相关UI：UISlider、UIStepper
* rac_newOnChannel
* 相关UI：UISwitch
* rac_newTextChannel
* 相关UI：UITextField

## Foundation - Category （常用汇总）

### NSData
* rac_readContentsOfURL: options: scheduler: 比oc多出线程设置

### NSDictionary
* rac_sequence
* rac_keySequence key 集合
* rac_valueSequence value 集合

### NSArray
* rac_sequence 信号集合

### NSFileHandle
* rac_readInBackground 后台线程读取

### NSInvocation
* rac_setArgument: atIndex: 设置参数
* rac_argumentAtIndex 取某个参数
* rac_returnValue 所关联方法的返回值

### NSNotificationCenter
* rac_addObserverForName: object:注册通知

### NSObject
* rac_willDeallocSignal 对象销毁时发动的信号
* rac_description debug用
* rac_observeKeyPath: options: observer: block:监听某个事件
* rac_liftSelector: withSignals: 全部信号都next在执行
* rac_signalForSelector: 代替某个方法
* rac_signalForSelector:(SEL)selector fromProtocol:代替代理

### NSString
* rac_keyPathComponents 获取一个路径所有的部分
* rac_keyPathByDeletingLastKeyPathComponent 删除路径最后一部分
* rac_keyPathByDeletingFirstKeyPathComponent 删除路径第一部分
* rac_readContentsOfURL: usedEncoding: scheduler: 比之OC多线程调用
* rac_sequence

### NSURLConnection
* rac_sendAsynchronousRequest 发起异步请求

### NSUserDefaults
* rac_channelTerminalForKey 用于双向绑定，此乃一

### NSEnumerator
* rac_sequence

### NSIndexSet
* rac_sequence

### NSOrderedSet
* rac_sequence

### NSSet
* rac_sequence

# RAC图片版的API手册

## ReactiveCocoa objectivec
![ReactiveCocoaobjectivec](https://github.com/ming1016/study/blob/master/pic/ReactiveCocoaOC.png?raw=true)

## ReactiveCocoa Swift
![ReactiveCocoaSwift](https://github.com/ming1016/study/blob/master/pic/ReactiveCocoaSwift.png?raw=true)

## RXSwift
![RXSwift](https://github.com/ming1016/study/blob/master/pic/RXSwift.png?raw=true)

# 本文参考整理自
* ReactiveCocoa Tutorial – The Definitive Introduction: Part 1/2 <https://www.raywenderlich.com/62699/reactivecocoa-tutorial-pt1>
* ReactiveCocoa Tutorial – The Definitive Introduction: Part 2/2 <https://www.raywenderlich.com/62796/reactivecocoa-tutorial-pt2>
* iOS的函数响应型编程 <https://www.gitbook.com/book/kevinhm/functionalreactiveprogrammingonios/details>
* ReactiveCocoa Essentials: Understanding and Using RACCommand <http://codeblog.shape.dk/blog/2013/12/05/reactivecocoa-essentials-understanding-and-using-raccommand/>
* iOS ReactiveCocoa 最全常用API整理（可做为手册查询）<http://www.cocoachina.com/ios/20160729/17236.html>
* ReactiveCocoa和RXSwift速查表 <http://valiantcat.com/2016/07/22/ReactiveCocoa和RXSwift速查表/>
* ReactiveCocoa中潜在的内存泄漏及解决方案<http://tech.meituan.com/potential-memory-leak-in-reactivecocoa.html?from=timeline&isappinstalled=0>