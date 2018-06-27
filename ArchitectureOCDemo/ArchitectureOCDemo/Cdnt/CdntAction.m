//
//  CdntAction.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/19.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "CdntAction.h"

@interface CdntAction ()

@property (nonatomic, strong) NSString *chainCls;

@end

@implementation CdntAction

+ (CdntAction *)classMethod:(NSString *)classMethod {
    return [CdntAction classMethod:classMethod parameters:nil toState:nil];
}

+ (CdntAction *)classMethod:(NSString *)classMethod parameters:(NSMutableDictionary *)parameters {
    return [CdntAction classMethod:classMethod parameters:parameters toState:nil];
}

+ (CdntAction *)classMethod:(NSString *)classMethod parameters:(NSMutableDictionary *)parameters toState:(NSString *)toState {
    CdntAction *act = [[CdntAction alloc] init];
    act.classMethod = classMethod;
    act.parameters = parameters;
    act.toState = toState;
    return act;
}

// Chain Helper
+ (CdntAction *(^)(NSString *))clsmtd {
    return ^CdntAction *(NSString *clsmtd) {
        CdntAction *act = [[CdntAction alloc] init];
        act.classMethod = clsmtd;
        return act;
    };
}

+ (CdntAction *(^)(NSString *))cls {
    return ^CdntAction *(NSString *cls) {
        CdntAction *act = [[CdntAction alloc] init];
        act.chainCls = cls;
        return act;
    };
}

- (CdntAction *(^)(NSString *))mtd {
    return ^CdntAction *(NSString *mtd) {
        self.classMethod = [NSString stringWithFormat:@"%@ %@",self.chainCls, mtd];
        return self;
    };
}

- (CdntAction *(^)(NSMutableDictionary *))pa {
    return ^CdntAction *(NSMutableDictionary *pa) {
        self.parameters = pa;
        return self;
    };
}

- (CdntAction *(^)(NSString *))toSt {
    return ^CdntAction *(NSString *toSt) {
        self.toState = toSt;
        return self;
    };
}

@end
