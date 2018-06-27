//
//  DragonState.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/24.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DragonFight;

@protocol DragonState <NSObject>

- (void)dealWithEnemy:(DragonFight *)dragonFight;

@end
