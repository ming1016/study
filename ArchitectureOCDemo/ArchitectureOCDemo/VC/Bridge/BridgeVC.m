//
//  BridgeVC.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/23.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "BridgeVC.h"
#import "FieryDragon.h"
#import "RedFieryDragonAbility.h"
#import "BlackFieryDragonAbility.h"

@interface BridgeVC ()

@end

@implementation BridgeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    FieryDragon *fieryDragon = [[FieryDragon alloc] init];
    
    fieryDragon.dragonAbility = [[RedFieryDragonAbility alloc] init];
    [fieryDragon fly];
    [fieryDragon fire];
    [fieryDragon eat];
    
    fieryDragon.dragonAbility = [[BlackFieryDragonAbility alloc] init];
    [fieryDragon fly];
    [fieryDragon fire];
    [fieryDragon eat];
}

@end
