//
//  Cdnt+First.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/13.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "Cdnt+First.h"

@implementation Cdnt (First)

- (void)firstViewInVC:(UIViewController *)vc {
    // middleware
    [self configMiddlewares];
    
    // 设置 vc
    // 添加 factoryVC 的按钮
    NSString *factoryTitle = self.dispatch(CdntAction.clsmtd(@"VCGeneratorCom factoryMethodVCTitle"));
    UIViewController *factoryVC = self.dispatch(CdntAction.clsmtd(@"VCGeneratorCom factoryMethodVC"));
    
    // Publish 按钮
    NSString *publishTitle = [self classMethod:@"VCGeneratorCom publishVCTitle"];
    UIViewController *publishVC = [self classMethod:@"VCGeneratorCom publishVC"];
    
    NSMutableDictionary *dic = Dic.create.key(@"vc").val(vc)
    
    // factory 按钮
    .key(@"factoryMethodButton").val(self.dispatch(CdntAction.clsmtd(@"ButtonCom configButton").pa(Dic.create.key(@"text").val(factoryTitle).key(@"action").val(^(void) {
        self.dispatch(CdntAction.clsmtd(@"FirstListCom pushVC").pa(Dic.create.key(@"vc").val(vc).key(@"toVc").val(factoryVC).done));
    }).done)))
    
    // publish 按钮
    .key(@"publishButton").val(self.dispatch(CdntAction.clsmtd(@"ButtonCom configButton").pa(Dic.create.key(@"text").val(publishTitle).key(@"action").val(^(void) {
        self.dispatch(CdntAction.clsmtd(@"FirstListCom pushVC").pa(Dic.create.key(@"vc").val(vc).key(@"toVc").val(publishVC).done));
    }).done)))
    
    .done;
    
    // 组装
    self.dispatch(CdntAction.clsmtd(@"FirstListCom viewInVC").pa(dic).toSt(@"0"));
    
    self.dispatch(CdntAction.clsmtd(@"FirstListCom simRequest").pa(Dic.create.key(@"action").val(^(void) {
        NSLog(@"current state %@", self.currentState);
    }).done));
    
}

- (void)firstViewAppear {
    self.updateCurrentState([NSString stringWithFormat:@"%ld",self.currentState.integerValue + 1]);
    NSLog(@"%@",self.currentState);
    self.dispatch(CdntAction.clsmtd(@"FirstListCom diffStateShow"));
}

- (void)configMiddlewares {
    // 也可以通过 prefix suffix 或正则等规则生成这样一份映射表
    self.middleware(@"FirstListCom viewInVC").addMiddlewareAction(CdntAction.clsmtd(@"AopLogCom aopAppearLog"));
    self.middleware(@"VCGeneratorCom factoryMethodVCTitle").addMiddlewareAction(CdntAction.clsmtd(@"AopLogCom aopFactorySetTitle"));
}

@end
