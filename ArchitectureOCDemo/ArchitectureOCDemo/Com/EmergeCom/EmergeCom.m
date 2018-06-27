//
//  EmergeCom.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/26.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "EmergeCom.h"
#import "Masonry.h"

@interface EmergeCom()

@property (nonatomic, strong) UIView *emergeView;
@property (nonatomic, strong) UIButton *confirmBt;

@end

@implementation EmergeCom

- (UIView *)emergeView:(NSDictionary *)dic {
    self.emergeView = [UIView new];
    self.emergeView.backgroundColor = [UIColor redColor];
    self.confirmBt = dic[@"confirmBt"];
    if (self.confirmBt) {
        [self.emergeView addSubview:self.confirmBt];
        [self.confirmBt mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.emergeView);
            make.size.mas_equalTo(CGSizeMake(100, 40));
        }];
    }
    return self.emergeView;
}

- (void)updateConfirmBtTitle:(NSDictionary *)dic {
    NSString *title = dic[@"title"];
    if (!title) {
        title = @"确定";
    }
    [self.confirmBt setTitle:title forState:UIControlStateNormal];
    
}

- (NSString *)confirmBtTitle:(NSDictionary *)dic {
    return [self.confirmBt titleForState:UIControlStateNormal];
}

@end
