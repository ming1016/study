//
//  FirstListCom.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/13.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "FirstListCom.h"
#import "Masonry.h"
#import "FactoryMethodVC.h"

@interface FirstListCom ()

@property (nonatomic, weak) UIViewController *vc;

@end

@implementation FirstListCom

// vc:UIViewController
- (void)viewInVC:(NSDictionary *)dic {
    self.vc = dic[@"vc"];
    UIButton *bt = dic[@"factoryMethodButton"];
    [self.vc.view addSubview:bt];
    [bt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.vc.view);
        make.top.equalTo(self.vc.view).offset(100);
        make.size.mas_equalTo(CGSizeMake(200, 55));
    }];
}


@end






