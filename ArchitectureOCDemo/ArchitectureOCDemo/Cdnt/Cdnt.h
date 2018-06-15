//
//  Cdnt.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/12.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cdnt : NSObject
//aop
@property (nonatomic, strong) NSDictionary *aops; // Aop 映射表

- (id)classMethod:(NSString *)classMethod;
- (id)classMethod:(NSString *)classMethod parameters:(NSDictionary *)parameters;

@end
