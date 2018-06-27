//
//  FirstListCom.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/13.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstListCom : NSObject

- (void)viewInVC:(NSDictionary *)dic;
- (void)pushVC:(NSDictionary *)dic;

// demo subscriber
- (void)inVCSubscriberDispatch:(NSDictionary *)dic;
- (void)outVCSubscriberDispatch:(NSDictionary *)dic;

- (void)simRequest:(NSDictionary *)dic;

// demo state
- (void)diffStateShow:(NSDictionary *)dic;
- (void)diffStateShow_state_1:(NSDictionary *)dic;
- (void)diffStateShow_state_2:(NSDictionary *)dic;

@end
