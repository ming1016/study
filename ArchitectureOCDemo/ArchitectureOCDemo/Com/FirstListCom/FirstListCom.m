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

@end

@implementation FirstListCom

// vc:UIViewController
- (void)viewInVC:(NSDictionary *)dic {
    UIViewController *vc = dic[@"vc"];
    UIButton *fcBt = dic[@"factoryMethodButton"];
    [vc.view addSubview:fcBt];
    [fcBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(vc.view);
        make.top.equalTo(vc.view).offset(100);
        make.size.mas_equalTo(CGSizeMake(200, 55));
    }];
    
    UIButton *pBt = dic[@"publishButton"];
    [vc.view addSubview:pBt];
    [pBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(vc.view);
        make.top.equalTo(fcBt.mas_bottom).offset(50);
        make.size.mas_equalTo(CGSizeMake(200, 55));
    }];
    
}

- (void)pushVC:(NSDictionary *)dic {
    UIViewController *vc = dic[@"vc"];
    UIViewController *toVc = dic[@"toVc"];
    [vc.navigationController pushViewController:toVc animated:YES];
}

- (void)inVCSubscriberDispatch:(NSDictionary *)dic {
    NSLog(@"inVC subscriber dispatch");
}
- (void)outVCSubscriberDispatch:(NSDictionary *)dic {
    NSLog(@"outVC subscriber dispatch");
}

- (void)simRequest:(NSDictionary *)dic {
    void (^action)(void) = dic[@"action"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        action();
    });
}

- (void)diffStateShow:(NSDictionary *)dic {
    NSLog(@"currentState is 0，diffStateShow");
}
- (void)diffStateShow_state_1:(NSDictionary *)dic {
    NSLog(@"currentState is 1, diffStateShow_state_1");
}
- (void)diffStateShow_state_2:(NSDictionary *)dic {
    NSLog(@"currentState is 2, diffStateShow_state_2");
}


@end






