//
//  LogManager.m
//  iBeaconDemo
//
//  Created by Tozy on 14-8-6.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import "LogManager.h"
#import "ConsoleView.h"

@interface LogManager ()
<UIScrollViewDelegate>
@end

@implementation LogManager

LogManager *LogManagerInstance()
{
    return [LogManager sharedManager];
}

+ (LogManager *)sharedManager
{
    static LogManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[LogManager alloc] init];
    });
    return _sharedManager;
}

- (void)logMessage:(NSString *)message
{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:@"/log"];

    FILE *f = fopen(path.UTF8String, "a");
    fprintf(f, "%s", message.UTF8String);
    fclose(f);

    printf("%s", message.UTF8String);

    self.consoleView.text = [self.consoleView.text stringByAppendingString:message];
}

@end
