//
//  VCGeneratorCom.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/13.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VCGeneratorCom : NSObject

- (UIViewController *)factoryMethodVC:(NSDictionary *)dic;
- (NSString *)factoryMethodVCTitle:(NSDictionary *)dic;

- (UIViewController *)publishVC:(NSDictionary *)dic;
- (NSString *)publishVCTitle:(NSDictionary *)dic;

@end
