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
    UIColor *textColor = dic[@"textColor"];
    UIColor *bgColor = dic[@"bgColor"];
    if (text) {
        [bt setTitle:text forState:UIControlStateNormal];
    } else {
        [bt setTitle:@"Button" forState:UIControlStateNormal];
    }
    if (textColor) {
        bt.titleLabel.textColor = textColor;
    } else {
        bt.titleLabel.textColor = [UIColor whiteColor];
    }
    if (bgColor) {
        bt.backgroundColor = bgColor;
    } else {
        bt.backgroundColor = [UIColor blackColor];
    }
    
    [[bt rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        if (action) {
            action();
        }
        
    }];
    return bt;
}

@end
