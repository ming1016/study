//
//  FirstVC.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/11.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "FirstVC.h"
#import "Cdnt+First.h"

@interface FirstVC ()

@property (nonatomic, strong) Cdnt *ct;
@end

@implementation FirstVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.ct firstViewInVC:self];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self.ct firstViewAppear];
}

// getter
- (Cdnt *)ct {
    if (!_ct) {
        _ct = [Cdnt new];
    }
    return _ct;
}


















@end
