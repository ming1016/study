//
//  PublishCom.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/20.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PublishCom : NSObject

- (void)viewInVC:(NSDictionary *)dic;

- (void)showEmergeView:(NSDictionary *)dic;
- (void)hideEmergeView:(NSDictionary *)dic;

// emerge 点击状态控制
- (void)confirmEmerge_state_focusFromAddress:(NSDictionary *)dic;
- (void)confirmEmerge_state_focusToAddress:(NSDictionary *)dic;
- (void)confirmEmerge_state_focusPeople:(NSDictionary *)dic;

// 发布
- (void)checkPublish:(NSDictionary *)dic;
- (void)publishing:(NSDictionary *)dic;

- (void)reset:(NSDictionary *)dic;

@end
