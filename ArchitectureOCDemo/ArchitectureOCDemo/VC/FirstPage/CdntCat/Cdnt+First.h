//
//  Cdnt+First.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/13.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "Cdnt.h"
#import <UIKit/UIKit.h>

@interface Cdnt (First)

- (void)configAop;
- (UIViewController *)factoryMethodVC;
- (void)FirstViewInVC:(UIViewController *)vc;

@end
