---
title: 竭尽全力的去解耦的一次实践，封装一个TableView和一些功能组合的控件
date: 2016-05-23 21:24:25
tags: [iOS, Pattern]
categories: Programming
---
可以先看看这个Demo：<https://github.com/ming1016/DecoupleDemo>。从这个Demo里可以看到Controller和View还有Store的头文件里没有任何Delegate，Block回调，只有初始化和更新ViewModel的方法。所有这些控件，请求，ViewController和视图之间的联系都是通过ViewModel来进行的，而viewModel也不进行任何逻辑处理，只是简单的起到描述和默认值设置的作用。ViewController也被减轻的小得不能再小了，只需要初始化视图和Store即可。这也是我的一次尝试，看看如何利用KVO能够做到最大限度的解耦，和最大限度的减少代码和接口。

可以先看看以前代码最臃肿的地方在使用了新的思路后会变成怎么样，首先是ViewController
```objectivec
- (void)viewDidLoad {
    [super viewDidLoad];
    [self addKVO];
    [self buildConstraints];
    self.tbStore = [[TestTableStore alloc] initWithViewModel:self.tbView.viewModel];
}
```
可以看到里面仅仅做了添加KVO，布局控件和初始化Store的工作。

封装的TableView作为一个通用控件是不会去设置管理不同的Cell的，可以看看不用Delegate和Block是如何处理的。
```objectivec
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.viewModel.tableViewIdentifier = smTableViewIdentifier;
    self.viewModel.tableView = tableView;
    self.viewModel.cellIndexPath = indexPath;
    return self.viewModel.cell;
}
```
我觉得这样应该很简化了。当触发到UITableView这个配置Cell的回调时，通过对ViewModel的键值的监听就能够在任何地方对Cell进行配置了，而不用通过繁琐的Delegate和Block来层层回调了。

除了这里外，其它地方也用同样的方法进行了处理，比如说对新出现消息提示点击使其消失只需要设置ViewModel里的isHideHintView的值的处理，还有对请求不同状态显示不同引导页，只要是以前需要通过接口和回调的全部干掉，用ViewModel去控制，下面可以看看我写的ViewModel中，我将KVO分成了View Side和Data Side，前者主要是响应视图方面的逻辑变化，后者Data Side是响应不同的动作来产生对数据不同的处理，其它就都是些关于样式和数据配置相关的了。
```objectivec
//---------------------------
//           KVO View Side
//---------------------------
@property (nonatomic, assign) BOOL isHideGuideView;             //是否显示guide view
@property (nonatomic, assign) BOOL isHideHintView;              //是否显示hint view
//下拉刷新上拉加载更多
@property (nonatomic, assign) SMTableRequestStatus requestStatus; //刷新状态
//TableView Delegate
//通用
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *tableViewIdentifier;
//Cell
@property (nonatomic, strong) NSIndexPath *cellIndexPath;
@property (nonatomic, strong) UITableViewCell *cell;
//CellHeight
@property (nonatomic, strong) NSIndexPath *cellHeightIndexPath;
@property (nonatomic, assign) CGFloat cellHeight;

//---------------------------
//          KVO Data Side
//---------------------------
@property (nonatomic, assign) SMTableRefreshingStatus dataSourceRefreshingStatus; //请求状态
```

纵观整个项目，头文件都很干净，唯一有方法需要参数的也就是ViewModel。这种完全面向对象思路的编程方式在需求经常变更的情况下优势就会慢慢显露出来，对吧。