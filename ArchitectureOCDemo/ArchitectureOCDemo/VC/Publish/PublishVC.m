//
//  PublishVC.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/20.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "PublishVC.h"
#import "Cdnt+Publish.h"

@interface PublishVC ()

@property (nonatomic, strong) Cdnt *ct;

@end

@implementation PublishVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.ct publishInVC:self];
}

- (Cdnt *)ct {
    if (!_ct) {
        _ct = [Cdnt new];
    }
    return _ct;
}

@end
