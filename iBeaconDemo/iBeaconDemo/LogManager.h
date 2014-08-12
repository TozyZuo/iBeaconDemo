//
//  LogManager.h
//  iBeaconDemo
//
//  Created by Tozy on 14-8-6.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ConsoleView;

@interface LogManager : NSObject

@property (nonatomic, strong) ConsoleView *consoleView;

LogManager *LogManagerInstance();
+ (LogManager *)sharedManager;
- (void)logMessage:(NSString *)message;

@end
