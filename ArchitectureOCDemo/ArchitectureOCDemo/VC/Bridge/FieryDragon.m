//
//  DragonWithAbility.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/23.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "FieryDragon.h"

@implementation FieryDragon

- (void)fire {
    [self.dragonAbility fire];
}
- (void)fly {
    [self.dragonAbility fly];
}
- (void)eat {
    [self.dragonAbility eat];
}

// builder
- (void)action {
    [self.dragonAbility fire];
    [self.dragonAbility fly];
    [self.dragonAbility eat];
}

@end
