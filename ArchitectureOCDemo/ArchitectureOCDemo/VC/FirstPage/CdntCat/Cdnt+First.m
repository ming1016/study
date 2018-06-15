//
//  Cdnt+First.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/13.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "Cdnt+First.h"

@implementation Cdnt (First)

- (UIViewController *)factoryMethodVC {
    UIViewController *vc = [self classMethod:@"VCGeneratorCom factoryMethodVC"];
    vc.title = [self classMethod:@"TextGeneratorCom gText"];
    return vc;
}

- (void)FirstViewInVC:(UIViewController *)vc {
    NSMutableDictionary *mDic = [NSMutableDictionary new];
    NSString *factoryTitle = [self classMethod:@"VCGeneratorCom factoryMethodVCTitle"];
    UIViewController *factoryVC = [self classMethod:@"VCGeneratorCom factoryMethodVC"];
    mDic[@"vc"] = vc;
    mDic[@"factoryMethodTitel"] = factoryTitle;
    mDic[@"factoryMethodButton"] = [self classMethod:@"ButtonCom configButton" parameters:@{@"text":factoryTitle,@"action": ^(void){
        [vc.navigationController pushViewController:factoryVC animated:YES];
    }}];
    [self classMethod:@"FirstListCom viewInVC" parameters:mDic];
}

- (void)configAop {
    // 也可以通过 prefix suffix 或正则等规则生成这样一份映射表
    self.aops = @{
                  @"FirstListCom viewInVC":@"AopLogCom aopAppearLog",
                  @"VCGeneratorCom factoryMethodVCTitle":@"AopLogCom aopFactorySetTitle"
                  };
}

@end
