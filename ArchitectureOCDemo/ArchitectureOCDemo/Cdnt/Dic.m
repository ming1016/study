//
//  Dic.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/21.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "Dic.h"

@interface Dic ()

@property (nonatomic, strong) NSMutableDictionary *chainDic;
@property (nonatomic, strong) NSString *chainCurrentKey;

@end

@implementation Dic

+ (Dic *)create {
    return [[Dic alloc] init];
}

// parameters
- (Dic *(^)(NSString *))key {
    return ^Dic *(NSString *pKey) {
        self.chainCurrentKey = pKey;
        return self;
    };
}
- (Dic *(^)(id))val {
    return ^Dic *(id pVal) {
        self.chainDic[self.chainCurrentKey] = pVal;
        return self;
    };
}
- (NSMutableDictionary *)done {
    NSMutableDictionary *re = [NSMutableDictionary dictionaryWithDictionary:self.chainDic];
    self.chainDic = [NSMutableDictionary new];
    return re;
}

// Getter
- (NSMutableDictionary *)chainDic {
    if (!_chainDic) {
        _chainDic = [NSMutableDictionary new];
    }
    return _chainDic;
}

@end
