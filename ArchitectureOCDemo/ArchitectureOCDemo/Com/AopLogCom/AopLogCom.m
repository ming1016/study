//
//  AopLogCom.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/15.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "AopLogCom.h"

@implementation AopLogCom

- (void)aopAppearLog:(NSDictionary *)dic {
    NSLog(@"appear good");
}

- (void)aopFactorySetTitle:(NSDictionary *)dic {
    NSLog(@"factorytitle was set");
}

@end
