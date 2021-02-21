---
title: 使用ReactiveCocoa开发RSS阅读器
date: 2016-09-02 21:47:59
tags: [iOS, RSSReader]
categories: Programming
---
目前已经完成的功能有对RSS的解析和Atom解析，RSS内容本地数据库存储和读取，抓取中状态进度展示，标记阅读状态，标记全部已读等。这些功能里我对一些异步操作产生的数据采用了ReactiveCocoa来对数据流向进行了控制，下面我来说下如何运用RAC来进行的开发。

# 初始时读取本地存储首页列表数据，过滤无效数据，监听列表数据变化进行列表更新

![截图](https://github.com/ming1016/GCDFetchFeed/blob/master/GCDFetchFeed/resource/ScreenShot1.png?raw=true)

这里会用到RAC这个宏可以方便的来进行键值和信号的绑定，RACObserve这个宏方便的进行键值变化的监听处理。具体实现代码如下：
```objectivec
@weakify(self);
//首页列表数据赋值，过滤无效数据
RAC(self, feeds) = [[[SMDB shareInstance] selectAllFeeds] filter:^BOOL(NSMutableArray *feedsArray) {
    if (feedsArray.count > 0) {
        return YES;
    } else {
        return NO;
    }
}];

//监听列表数据变化进行列表更新
[RACObserve(self, feeds) subscribeNext:^(id x) {
    @strongify(self);
    [self.tableView reloadData];
}];

//本地读取首页订阅源数据
- (RACSignal *)selectAllFeeds {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        FMDatabase *db = [FMDatabase databaseWithPath:self.feedDBPath];
        if ([db open]) {
            FMResultSet *rs = [db executeQuery:@"select * from feeds"];
            NSUInteger count = 0;
            NSMutableArray *feedsArray = [NSMutableArray array];
            while ([rs next]) {
                SMFeedModel *feedModel = [[SMFeedModel alloc] init];
                feedModel.fid = [rs intForColumn:@"fid"];
                feedModel.title = [rs stringForColumn:@"title"];
                feedModel.link = [rs stringForColumn:@"link"];
                feedModel.des = [rs stringForColumn:@"des"];
                feedModel.copyright = [rs stringForColumn:@"copyright"];
                feedModel.generator = [rs stringForColumn:@"generator"];
                feedModel.imageUrl = [rs stringForColumn:@"imageurl"];
                feedModel.feedUrl = [rs stringForColumn:@"feedurl"];
                feedModel.unReadCount = [rs intForColumn:@"unread"];
                [feedsArray addObject:feedModel];
                count++;
            }
            [subscriber sendNext:feedsArray];
            [subscriber sendCompleted];
            [db close];
        }
        return nil;
    }];
}
```

# 通过网络获取订阅源最新内容，获取后进行本地存储，转成显示用的model进行列表的显示
这里的异步操作比较多，而且为了尽快取得数据采用的是并行队列，需要准确的获取到每个源完成的状态，包括解析的完成，本地存储完成，全部获取完成等数据完成情况。具体使用RAC方式的代码如下：
```objectivec
//获取所有feeds以及完成处理
- (void)fetchAllFeeds {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.tableView.tableHeaderView = self.tbHeaderView;
    self.fetchingCount = 0; //统计抓取数量
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
    }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(SMFeedModel *feedModel) {
        //抓完一个
        @strongify(self);
        //显示抓取状态
        self.fetchingCount += 1;
        self.tbHeaderLabel.text = [NSString stringWithFormat:@"正在获取%@...(%lu/%lu)",feedModel.title,(unsigned long)self.fetchingCount,(unsigned long)self.feeds.count];
        [self.tableView reloadData];
    }];
}
//网络获取以及解析本地存储
- (RACSignal *)fetchAllFeedWithModelArray:(NSMutableArray *)modelArray {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        //创建并行队列
        dispatch_queue_t fetchFeedQueue = dispatch_queue_create("com.starming.fetchfeed.fetchfeed", DISPATCH_QUEUE_CONCURRENT);
        dispatch_group_t group = dispatch_group_create();
        self.feeds = modelArray;

        for (int i = 0; i < modelArray.count; i++) {
            dispatch_group_enter(group);
            SMFeedModel *feedModel = modelArray[i];
            dispatch_async(fetchFeedQueue, ^{
                [self GET:feedModel.feedUrl parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
                    //解析feed
                    self.feeds[i] = [self.feedStore updateFeedModelWithData:responseObject preModel:feedModel];
                    //入库存储
                    SMDB *db = [[SMDB alloc] init];
                    [[db insertWithFeedModel:self.feeds[i]] subscribeNext:^(NSNumber *x) {
                        SMFeedModel *model = (SMFeedModel *)self.feeds[i];
                        model.fid = [x integerValue];
                        //插入本地数据库成功后开始sendNext
                        [subscriber sendNext:@(i)];
                        //通知单个完成
                        dispatch_group_leave(group);
                    }];

                } failure:^(NSURLSessionTask *operation, NSError *error) {
                    NSLog(@"Error: %@", error);
                    dispatch_group_leave(group);
                }];

            });//end dispatch async

        }//end for
        //全完成后执行事件
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [subscriber sendCompleted];
        });
        return nil;
    }];
}
```

# 读取RSS列表，异步读取，主线程更新

![截图](https://github.com/ming1016/GCDFetchFeed/blob/master/GCDFetchFeed/resource/ScreenShot2.png?raw=true)

这里通过RAC能够很方便的进行主线程操作UI，非主线程操作数据这样的操作，具体实现如下：
```objectivec
//获取列表数据以及对应的操作
- (void)selectFeedItems {
    RACScheduler *scheduler = [RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh];
    @weakify(self);
    [[[[[SMDB shareInstance] selectFeedItemsWithPage:self.page fid:self.feedModel.fid]
       subscribeOn:scheduler]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSMutableArray *x) {
        @strongify(self);
        if (self.listData.count > 0) {
            //进入时加载
            [self.listData addObjectsFromArray:x];
        } else {
            //加载更多
            self.listData = x;
        }
        //刷新
        [self.tableView reloadData];
    } error:^(NSError *error) {
        //处理无数据的显示
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    } completed:^{
        //加载完成后的处理
        [self.tableView.mj_footer endRefreshing];
    }];
    self.page += 1;
}

//数据库获取信号
- (RACSignal *)selectFeedItemsWithPage:(NSUInteger)page fid:(NSUInteger)fid {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        FMDatabase *db = [FMDatabase databaseWithPath:self.feedDBPath];
        if ([db open]) {
            //分页获取
            FMResultSet *rs = [db executeQuery:@"select * from feeditem where fid = ? and isread = ? order by iid desc limit ?, 20",@(fid), @(0), @(page * 20)];
            NSUInteger count = 0;
            NSMutableArray *feedItemsArray = [NSMutableArray array];
            //设置返回Array里的Model
            while ([rs next]) {
                SMFeedItemModel *itemModel = [[SMFeedItemModel alloc] init];
                itemModel.iid = [rs intForColumn:@"iid"];
                itemModel.fid = [rs intForColumn:@"fid"];
                itemModel.link = [rs stringForColumn:@"link"];
                itemModel.title = [rs stringForColumn:@"title"];
                itemModel.author = [rs stringForColumn:@"author"];
                itemModel.category = [rs stringForColumn:@"category"];
                itemModel.pubDate = [rs stringForColumn:@"pubDate"];
                itemModel.des = [rs stringForColumn:@"des"];
                itemModel.isRead = [rs intForColumn:@"isread"];
                [feedItemsArray addObject:itemModel];
                count++;
            }
            if (count > 0) {
                [subscriber sendNext:feedItemsArray];
            } else {
                //获取出错处理
                [subscriber sendError:nil];
            }
            [subscriber sendCompleted];
            [db close];
        }
        return nil;
    }];
}
```

![截图](https://github.com/ming1016/GCDFetchFeed/blob/master/GCDFetchFeed/resource/ScreenShot3.png?raw=true)

完整代码可以在这里看:<https://github.com/ming1016/GCDFetchFeed>