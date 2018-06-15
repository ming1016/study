//
//  BlackDragonFactory.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/12.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "BlackDragonFactory.h"
#import "BlackDragon.h"

@implementation BlackDragonFactory

- (id<Dragon>)newDragon {
    return [[BlackDragon alloc] init];
}

@end
