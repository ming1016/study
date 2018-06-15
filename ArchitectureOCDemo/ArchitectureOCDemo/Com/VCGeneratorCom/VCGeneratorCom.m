//
//  VCGeneratorCom.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/13.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "VCGeneratorCom.h"
#import "FactoryMethodVC.h"

@implementation VCGeneratorCom

- (UIViewController *)factoryMethodVC:(NSDictionary *)dic {
    FactoryMethodVC *vc = [[FactoryMethodVC alloc] init];
    return vc;
}
- (NSString *)factoryMethodVCTitle:(NSDictionary *)dic {
    return @"Factory";
}

@end
