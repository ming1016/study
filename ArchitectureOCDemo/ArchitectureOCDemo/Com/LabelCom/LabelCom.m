//
//  LabelCom.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/21.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "LabelCom.h"

@implementation LabelCom

- (UILabel *)configLabel:(NSDictionary *)dic {
    UILabel *lb = [UILabel new];
    NSString *text = dic[@"text"];
    UIColor *textColor = dic[@"textColor"];
    if (text) {
        lb.text = text;
    } else {
        lb.text = @"label";
    }
    if (textColor) {
        lb.textColor = textColor;
    } else {
        lb.textColor = [UIColor blackColor];
    }
    return lb;
}

@end
