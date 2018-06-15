//
//  ButtonCom.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/15.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "ButtonCom.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation ButtonCom

- (UIButton *)configButton:(NSDictionary *)dic {
    UIButton *bt = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *text = dic[@"text"];
    void (^action)(void) = dic[@"action"];
    [bt setTitle:text forState:UIControlStateNormal];
    bt.titleLabel.textColor = [UIColor whiteColor];
    bt.backgroundColor = [UIColor blackColor];
    [[bt rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        action();
    }];
    return bt;
}

@end
