//
//  Dic.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/21.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Dic : NSObject

+ (Dic *)create;

- (Dic *(^)(NSString *))key;
- (Dic *(^)(id))val;
- (NSMutableDictionary *)done;

@end
