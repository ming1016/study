//
//  DragonWithAbility.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/23.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DragonAbility.h"

@interface FieryDragon : NSObject

@property (nonatomic, strong) id<DragonAbility> dragonAbility;

// Bridge
- (void)fire;
- (void)fly;
- (void)eat;

// builder 组装模式
- (void)action;

@end
