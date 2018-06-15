//
//  Cdnt.m
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/12.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import "Cdnt.h"

@interface Cdnt ()

@property (nonatomic, strong) NSMutableDictionary *classes;

@end

@implementation Cdnt

- (id)classMethod:(NSString *)classMethod {
    return [self classMethod:classMethod parameters:nil];
}

- (id)classMethod:(NSString *)classMethod parameters:(NSDictionary *)parameters {
    
    NSArray *sep = [classMethod componentsSeparatedByString:@" "];
    NSString *classStr = @"";
    NSString *methodStr = @"";
    if (sep.count == 2) {
        classStr = sep[0];
        methodStr = [NSString stringWithFormat:@"%@:", sep[1]];
    } else {
        return nil;
    }
    
    // Aop
    NSString *aop = [self.aops valueForKey:classMethod];
    if (aop) {
        [self classMethod:aop];
    }
    
    NSObject *obj = self.classes[classStr];
    if (obj == nil) {
        Class objClass = NSClassFromString(classStr);
        // TODO: 对于是单例的对象特殊处理下
        obj = [[objClass alloc] init];
        self.classes[classStr] = obj;
    }
    SEL method = NSSelectorFromString(methodStr);
    SEL notFoundMethod = NSSelectorFromString(@"notFound:");
    if ([obj respondsToSelector:method]) {
        return [self executeMethod:method obj:obj parameters:parameters];
    } else if ([obj respondsToSelector:notFoundMethod]) {
        return [self executeMethod:method obj:obj parameters:parameters];
    } else {
        [self.classes removeObjectForKey:classStr];
        return nil;
    }
    
    return nil;
}

- (id)executeMethod:(SEL)method obj:(NSObject *)obj parameters:(NSDictionary *)parameters {
    NSMethodSignature* methodSig = [obj methodSignatureForSelector:method];
    if(methodSig == nil) {
        return nil;
    }
    const char* retType = [methodSig methodReturnType];
    
    if (strcmp(retType, @encode(void)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&parameters atIndex:2];
        [invocation setSelector:method];
        [invocation setTarget:obj];
        [invocation invoke];
        return nil;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [obj performSelector:method withObject:parameters];
#pragma clang diagnostic pop
}


// Getter
- (NSMutableDictionary *)classes {
    if (!_classes) {
        _classes = [[NSMutableDictionary alloc] init];
    }
    return _classes;
}
- (NSDictionary *)aops {
    if (!_aops) {
        _aops = [NSDictionary new];
    }
    return _aops;
}

@end
