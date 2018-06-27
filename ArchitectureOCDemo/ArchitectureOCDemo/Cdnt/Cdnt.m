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

// State
@property (nonatomic, copy) NSString *p_currentState;

// Middleware
@property (nonatomic, strong) NSMutableDictionary *middlewares; // 中间件
@property (nonatomic, strong) NSString *chainMiddlewareKey;

// Observer
@property (nonatomic, strong) NSMutableDictionary *observersIdentifier;  // 存储 identifier 观察者
@property (nonatomic, strong) NSString *chainIdentifier;

// Factory
@property (nonatomic, strong) NSMutableDictionary *factories;
@property (nonatomic, strong) NSString *chainFactoryClass;

@end

@implementation Cdnt

// ------- State ---------
- (void)updateCurrentState:(NSString *)state {
    if (state.length < 1) {
        return;
    }
    self.p_currentState = state;
}
- (NSString *)currentState {
    return self.p_currentState;
}
- (Cdnt *(^)(NSString *))updateCurrentState {
    return ^Cdnt *(NSString *state) {
        if (state.length > 0) {
            self.p_currentState = state;
        }
        return self;
    };
}

// -------- Middleware --------
- (void)middleware:(NSString *)whenClassMethod thenAddDispatch:(CdntAction *)action {
    if (whenClassMethod.length < 1 || !action) {
        return;
    }
    NSMutableArray *mArr = [self.middlewares objectForKey:whenClassMethod];
    if (!mArr) {
        mArr = [NSMutableArray new];
    }
    [mArr addObject:action];
    self.middlewares[whenClassMethod] = mArr;
}
- (Cdnt *(^)(NSString *))middleware {
    return ^Cdnt *(NSString *mid) {
        if (mid.length < 1) {
            return self;
        }
        self.chainMiddlewareKey = mid;
        return self;
    };
}
- (Cdnt *(^)(CdntAction *))addMiddlewareAction {
    return ^Cdnt *(CdntAction *act) {
        if (!act) {
            return self;
        }
        NSMutableArray *mArr = [self.middlewares objectForKey:self.chainMiddlewareKey];
        if (!mArr) {
            mArr = [NSMutableArray new];
        }
        [mArr addObject:act];
        self.middlewares[self.chainMiddlewareKey] = mArr;
        return self;
    };
}

// --------- Observer ------------
- (void)observerWithIdentifier:(NSString *)identifier observer:(CdntAction *)act {
    if (identifier.length < 1 || !act) {
        return;
    }
    NSMutableArray *mArr = [self.observersIdentifier objectForKey:identifier];
    if (!mArr) {
        mArr = [NSMutableArray new];
    }
    [mArr addObject:act];
    self.observersIdentifier[identifier] = mArr;
}
- (void)notifyObservers:(NSString *)identifier {
    NSMutableArray *mArr = [self.observersIdentifier objectForKey:identifier];
    if (mArr.count > 0) {
        for (CdntAction *act in mArr) {
            self.dispatch(act);
        }
    }
}
- (Cdnt *(^)(NSString *))observerWithIdentifier {
    return ^Cdnt *(NSString *identifier) {
        if (identifier.length > 0) {
            self.chainIdentifier = identifier;
        }
        return self;
    };
}
- (Cdnt *(^)(CdntAction *))addObserver {
    return ^Cdnt *(CdntAction *act) {
        NSMutableArray *mArr = [self.observersIdentifier objectForKey:self.chainIdentifier];
        if (!mArr) {
            mArr = [NSMutableArray new];
        }
        [mArr addObject:act];
        self.observersIdentifier[self.chainIdentifier] = mArr;
        return self;
    };
}

// --------- Factory -------------
- (void)factoryClass:(NSString *)fClass useFactory:(NSString *)factory {
    if (fClass.length < 1 || factory.length < 1) {
        return;
    }
    self.factories[fClass] = factory;
}
- (Cdnt *(^)(NSString *))factoryClass {
    return ^Cdnt *(NSString *fClass) {
        self.chainFactoryClass = fClass;
        return self;
    };
}
- (Cdnt *(^)(NSString *))factory {
    return ^Cdnt *(NSString *factory) {
        self.factories[self.chainFactoryClass] = factory;
        return self;
    };
}

// --------- Action --------------
// Chain dispatch
- (id (^)(CdntAction *))dispatch {
    return ^Cdnt *(CdntAction *act) {
        return [self dispatch:act];
    };
}
- (id)dispatch:(CdntAction *)action {
    if (action.toState.length > 0) {
        self.p_currentState = action.toState;
    }
    return [self classMethod:action.classMethod parameters:action.parameters];
}

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
    
    // Factory
    // 由于后面的执行都会用到 class 所以需要优先处理 class 的变形体
    NSString *factory = [self.factories objectForKey:classStr];
    if (factory) {
        classStr = [NSString stringWithFormat:@"%@_factory_%@", classStr, factory];
        classMethod = [NSString stringWithFormat:@"%@ %@", classStr, sep[1]];
    }
    
    // Middleware 中间件
    id middleware = [self.middlewares valueForKey:classMethod];
    if (middleware) {
        [self perform:middleware];
    }
    
    NSObject *obj = self.classes[classStr];
    if (obj == nil) {
        Class objClass = NSClassFromString(classStr);
        obj = [[objClass alloc] init];
        self.classes[classStr] = obj;
    }
    SEL method = NSSelectorFromString(methodStr);
    // State action 状态处理
    if (![self.p_currentState isEqual:@"init"]) {
        SEL stateMethod = NSSelectorFromString([NSString stringWithFormat:@"%@_state_%@:", sep[1], self.p_currentState]);
        if ([obj respondsToSelector:stateMethod]) {
            return [self executeMethod:stateMethod obj:obj parameters:parameters];
        }
    }
    // 普通 action
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

- (void)perform:(id)action {
    if ([action isKindOfClass:[CdntAction class]]) {
        [self dispatch:action];
    } else if ([action isKindOfClass:[NSMutableArray class]]) {
        for (CdntAction *act in action) {
            [self dispatch:act];
        }
    }
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
- (NSMutableDictionary *)middlewares {
    if (!_middlewares) {
        _middlewares = [NSMutableDictionary new];
    }
    return _middlewares;
}

- (NSString *)p_currentState {
    if (!_p_currentState) {
        _p_currentState = @"init";
    }
    return _p_currentState;
}
- (NSMutableDictionary *)observersIdentifier {
    if (!_observersIdentifier) {
        _observersIdentifier = [NSMutableDictionary new];
    }
    return _observersIdentifier;
}
- (NSString *)chainMiddlewareKey {
    if (!_chainMiddlewareKey) {
        _chainMiddlewareKey = @"empty";
    }
    return _chainMiddlewareKey;
}
- (NSString *)chainIdentifier {
    if (!_chainIdentifier) {
        _chainIdentifier = @"empty";
    }
    return _chainIdentifier;
}
- (NSMutableDictionary *)factories {
    if (!_factories) {
        _factories = [NSMutableDictionary new];
    }
    return _factories;
}
- (NSString *)chainFactoryClass {
    if (!_chainFactoryClass) {
        _chainFactoryClass = @"empty";
    }
    return _chainFactoryClass;
}

@end
