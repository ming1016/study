//
//  PublishCom.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/20.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "PublishCom.h"
#import "Masonry.h"

@interface PublishCom()

@property (nonatomic, weak) UIView *vcView;
@property (nonatomic, strong) UIButton *fromAddressBt;
@property (nonatomic, strong) UIButton *toAddressBt;
@property (nonatomic, strong) UIButton *peopleBt;
@property (nonatomic, strong) UIView *emergeView;
@property (nonatomic, strong) UIButton *publishBt;

@property (nonatomic, strong) UIView *adView;

@end

@implementation PublishCom

- (void)viewInVC:(NSDictionary *)dic {
    self.vcView = dic[@"vcView"];
    self.fromAddressBt = dic[@"fromAddressBt"];
    self.toAddressBt = dic[@"toAddressBt"];
    self.peopleBt = dic[@"peopleBt"];
    self.emergeView = dic[@"emergeView"];
    self.publishBt = dic[@"publishBt"];
    
    if (!self.fromAddressBt || !self.toAddressBt || !self.peopleBt || !self.emergeView) {
        return;
    }
    UIView *topView = [UIView new];
    topView.backgroundColor = [UIColor redColor];
    
    [self.vcView addSubview:topView];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vcView).offset(60);
        make.centerX.equalTo(self.vcView);
        make.size.mas_equalTo(CGSizeMake(300, 300));
    }];
    
    [topView addSubview:self.fromAddressBt];
    [self.fromAddressBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topView).offset(20);
        make.centerX.equalTo(topView);
        make.size.mas_equalTo(CGSizeMake(200, 40));
    }];
    
    [topView addSubview:self.toAddressBt];
    [self.toAddressBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.fromAddressBt.mas_bottom).offset(20);
        make.centerX.equalTo(topView);
        make.size.equalTo(self.fromAddressBt);
    }];
    
    [topView addSubview:self.peopleBt];
    [self.peopleBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.toAddressBt.mas_bottom).offset(20);
        make.centerX.equalTo(topView);
        make.size.mas_equalTo(CGSizeMake(70, 40));
    }];
    
    [self.vcView addSubview:self.publishBt];
    [self.publishBt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(100, 40));
        make.centerX.equalTo(self.vcView);
        make.bottom.equalTo(self.vcView);
    }];
    
    [self.vcView addSubview:self.emergeView];
    [self.emergeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vcView.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(320, 200));
        make.centerX.equalTo(self.vcView);
    }];
    
}

- (void)showEmergeView:(NSDictionary *)dic {
    [self.emergeView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vcView.mas_bottom).offset(-200);
    }];
    [UIView animateWithDuration:0.2 animations:^{
        [self.vcView layoutIfNeeded];
    }];
}

- (void)hideEmergeView:(NSDictionary *)dic {
    [self.emergeView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vcView.mas_bottom);
    }];
    [UIView animateWithDuration:0.2 animations:^{
        [self.vcView layoutIfNeeded];
    }];
}

// 状态管理
- (void)confirmEmerge_state_focusFromAddress:(NSDictionary *)dic {
    NSString *title = dic[@"title"];
    [self.fromAddressBt setTitle:title forState:UIControlStateNormal];
    self.fromAddressBt.tag = 1;
}
- (void)confirmEmerge_state_focusToAddress:(NSDictionary *)dic {
    NSString *title = dic[@"title"];
    [self.toAddressBt setTitle:title forState:UIControlStateNormal];
    self.toAddressBt.tag = 1;
}
- (void)confirmEmerge_state_focusPeople:(NSDictionary *)dic {
    NSString *title = dic[@"title"];
    [self.peopleBt setTitle:title forState:UIControlStateNormal];
    self.peopleBt.tag = 1;
}

// 发布按钮状态检查
- (void)checkPublish:(NSDictionary *)dic {
    if (self.fromAddressBt.tag == 1 && self.toAddressBt.tag == 1 && self.peopleBt.tag == 1) {
        self.publishBt.backgroundColor = [UIColor blackColor];
    } else {
        self.publishBt.backgroundColor = [UIColor lightGrayColor];
    }
}
- (void)publishing:(NSDictionary *)dic {
    self.publishBt.backgroundColor = [UIColor redColor];
}
- (void)reset:(NSDictionary *)dic {
    [self.fromAddressBt setTitle:@"起始地" forState:UIControlStateNormal];
    self.fromAddressBt.tag = 0;
    [self.toAddressBt setTitle:@"前往" forState:UIControlStateNormal];
    self.toAddressBt.tag = 0;
    [self.peopleBt setTitle:@"人数" forState:UIControlStateNormal];
    self.peopleBt.tag = 0;
    
    [UIView animateWithDuration:0.1 animations:^{
        [self.vcView layoutIfNeeded];
    }];
}

@end
