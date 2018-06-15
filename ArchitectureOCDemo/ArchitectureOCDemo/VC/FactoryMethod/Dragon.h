//
//  Dragon.h
//  ArchitectureOCDemo
//
//  Created by DaiMing on 2018/6/12.
//  Copyright © 2018年 Starming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol Dragon <NSObject>

- (NSString *)fly;

- (NSString *)fire;

- (NSString *)eat;

- (UIColor *)color;

@end
