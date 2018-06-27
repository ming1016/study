//
//  Cdnt.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/12.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CdntAction.h"
#import "Dic.h"

@interface Cdnt : NSObject

/* ------- Reducer ------- */
// Reducer 下面几种是不同的调用写法，最终的执行是一致的。
- (id)dispatch:(CdntAction *)action; // 可以设置更改当前状态
- (id)classMethod:(NSString *)classMethod;
- (id)classMethod:(NSString *)classMethod parameters:(NSDictionary *)parameters;
// helper
- (id (^)(CdntAction *))dispatch;

/* ------- Middleware ------- */
// Middleware 当设置的方法执行时先执行指定的方法，可用于观察某方法的执行，然后通知其它 com 执行观察方法进行响应
- (void)middleware:(NSString *)whenClassMethod thenAddDispatch:(CdntAction *)action;
// Middleware 链式写法支持
- (Cdnt *(^)(NSString *))middleware;
- (Cdnt *(^)(CdntAction *))addMiddlewareAction;

/* ------- State ------- */
// State manager 状态管理
- (NSString *)currentState;
- (void)updateCurrentState:(NSString *)state;
// State 链式写法支持
- (Cdnt *(^)(NSString *))updateCurrentState;

/* ------- Observer ------- */
// Observer
- (void)observerWithIdentifier:(NSString *)identifier observer:(CdntAction *)act;
- (void)notifyObservers:(NSString *)identifier;
// Observer 链式写法支持
- (Cdnt *(^)(NSString *))observerWithIdentifier;
- (Cdnt *(^)(CdntAction *))addObserver;

/* --------- Factory ---------*/
- (void)factoryClass:(NSString *)fClass useFactory:(NSString *)factory;
// Factory 链式写法
- (Cdnt *(^)(NSString *))factoryClass;
- (Cdnt *(^)(NSString *))factory;


@end
