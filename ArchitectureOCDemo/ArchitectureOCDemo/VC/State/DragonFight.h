//
//  DragonFight.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/27.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DragonState.h"

@interface DragonFight : NSObject

@property (nonatomic, strong) id<DragonState> state;

@property (nonatomic, copy) NSString *enemy;
@property (nonatomic) BOOL isWin;

- (void)fight;

@end
