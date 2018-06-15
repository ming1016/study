//
//  FactoryMethodVC.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/12.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "FactoryMethodVC.h"
#import "Masonry.h"
#import "Dragon.h"
#import "DragonFactory.h"
#import "RedDragonFactory.h"
#import "BlackDragonFactory.h"

@interface FactoryMethodVC ()

@property (nonatomic, strong) UILabel *dragonLb;
@property (nonatomic, strong) id<DragonFactory> dragonF;

@end

@implementation FactoryMethodVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.dragonLb];
    [self.dragonLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(100);
        make.centerX.equalTo(self.view);
    }];
    BOOL isRed = true;
    if (isRed) {
        self.dragonF = [[RedDragonFactory alloc] init];
    } else {
        self.dragonF = [[BlackDragonFactory alloc] init];
    }
    id<Dragon> dragon = [self.dragonF newDragon];
    self.dragonLb.text = dragon.eat;
    self.dragonLb.textColor = dragon.color;
}

- (UILabel *)dragonLb {
    if (!_dragonLb) {
        _dragonLb = [UILabel new];
    }
    return _dragonLb;
}




@end
