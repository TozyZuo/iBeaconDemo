//
//  BeaconManager.h
//  iBeaconDemo
//
//  Created by Tozy on 14-8-6.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BeaconManager : NSObject

@property (nonatomic, readonly) NSArray *rangedBeacons;

BeaconManager *BeaconManagerInstance();
+ (BeaconManager *)sharedManager;

- (void)start;

@end
