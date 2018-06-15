//
//  RedDragonFactory.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/12.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "RedDragonFactory.h"
#import "RedDragon.h"

@implementation RedDragonFactory

- (id<Dragon>)newDragon {
    return [[RedDragon alloc] init];
}

@end
