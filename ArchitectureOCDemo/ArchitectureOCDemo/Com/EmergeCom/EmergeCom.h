//
//  EmergeCom.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/26.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmergeCom : NSObject

- (UIView *)emergeView:(NSDictionary *)dic;
- (void)updateConfirmBtTitle:(NSDictionary *)dic;
- (NSString *)confirmBtTitle:(NSDictionary *)dic;

@end
