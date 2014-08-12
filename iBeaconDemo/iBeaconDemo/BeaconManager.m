//
//  BeaconManager.m
//  iBeaconDemo
//
//  Created by Tozy on 14-8-6.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import "BeaconManager.h"
#import <CoreLocation/CoreLocation.h>

@interface BeaconManager ()
<CLLocationManagerDelegate>
@property (nonatomic, strong) NSArray *monitoringRegions;
@property (nonatomic, strong) NSMutableDictionary *rangeBeaconsDictionary;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, assign) BOOL notifyOnEntry;
@property (nonatomic, assign) BOOL notifyOnExit;
@end

@implementation BeaconManager

BeaconManager *BeaconManagerInstance()
{
    return [BeaconManager sharedManager];
}

+ (BeaconManager *)sharedManager
{
    static BeaconManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[BeaconManager alloc] init];
    });
    return _sharedManager;
}

- (id)init
{
    if (self = [super init]) {
        RegisterDefaultsFromSettingsBundle();

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.rangeBeaconsDictionary = [[NSMutableDictionary alloc] init];
        self.notifyOnEntry = [[[NSUserDefaults standardUserDefaults] objectForKey:SKey_NotifyOnEntry] boolValue];
        self.notifyOnExit = [[[NSUserDefaults standardUserDefaults] objectForKey:SKey_NotifyOnExit] boolValue];

        __weak BeaconManager *weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:NKey_MonitoringRegionsChanged object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSString *kind = note.userInfo[SKey_Kind];
            CLBeaconRegion *region = note.userInfo[SKey_Region];
            if ([kind isEqualToString:SKey_Add])
            {
                [weakSelf addNewRegion:region];
            }
            else if ([kind isEqualToString:SKey_Delete])
            {
                [weakSelf deleteRegion:region];
            }
            else
            {
                LMLog(@"%s no kind for this notify!", __func__);
            }
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSUserDefaults *ud = note.object;
            weakSelf.notifyOnEntry = [[ud objectForKey:SKey_NotifyOnEntry] boolValue];
            weakSelf.notifyOnExit = [[ud objectForKey:SKey_NotifyOnExit] boolValue];
        }];
    }
    return self;
}

- (NSArray *)rangedBeacons
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSArray *allValue = self.rangeBeaconsDictionary.allValues;
    for (NSArray *beacons in allValue) {
        [array addObjectsFromArray:beacons];
    }
    return array;
}

- (void)start
{
    [self startWithRegions:StoredRegions()];
}

- (void)startWithRegions:(NSArray *)regions
{
    [self stopWithRegions:self.monitoringRegions];
    self.monitoringRegions = regions;
    for (CLBeaconRegion *region in regions) {
        [self.locationManager startMonitoringForRegion:region];
        [self.locationManager requestStateForRegion:region];
    }
}

- (void)stopWithRegions:(NSArray *)regions
{
    for (CLBeaconRegion *region in regions) {
        [self.locationManager stopRangingBeaconsInRegion:region];
        [self.locationManager stopMonitoringForRegion:region];
        LMLog(@"Stop Monitoring and Ranging region:%@", region);
    }
}

- (void)addNewRegion:(CLBeaconRegion *)region
{
    self.monitoringRegions = [self.monitoringRegions arrayByAddingObject:region];
    [self.locationManager startMonitoringForRegion:region];
    [self.locationManager requestStateForRegion:region];
}

- (void)deleteRegion:(CLBeaconRegion *)region
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.monitoringRegions];
    for (int i = 0; i < array.count; i++) {
        if (CLBeaconRegionEqualToRegion(region, array[i])) {
            [array removeObjectAtIndex:i];
            break;
        }
    }
    self.monitoringRegions = array;
    [self.locationManager stopRangingBeaconsInRegion:region];
    [self.locationManager stopMonitoringForRegion:region];
    [self.rangeBeaconsDictionary removeObjectForKey:region.proximityUUID.UUIDString];
    LMLog(@"Stop Monitoring and Ranging region:%@", region);
}

- (void)sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region message:(NSString *)message
{
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = message;
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    self.rangeBeaconsDictionary[region.proximityUUID.UUIDString] = beacons;
//    LMLog(@"%d beacons found", self.rangeBeacons.count);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSString *uuid = ((CLBeaconRegion *)region).proximityUUID.UUIDString;
    LMLog(@"Enter region:%@", uuid);

    if (([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) &&
        self.notifyOnEntry)
    {
        [self sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region message:[NSString stringWithFormat:@"Entered beacon region for UUID: %@", uuid]];
    }

    [self.locationManager requestStateForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSString *uuid = ((CLBeaconRegion *)region).proximityUUID.UUIDString;
    LMLog(@"Exit region:%@", uuid);

    if (([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) &&
        self.notifyOnExit)
    {
        [self sendLocalNotificationForBeaconRegion:(CLBeaconRegion *)region message:[NSString stringWithFormat:@"Exit beacon region for UUID: %@", uuid]];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
            [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
            LMLog(@"Start range. State changed to Inside for region %@", region);
            break;
        case CLRegionStateOutside:
            [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
            [self.rangeBeaconsDictionary removeObjectForKey:((CLBeaconRegion *)region).proximityUUID.UUIDString];;
            LMLog(@"Stop range. State changed to Outside for region %@", region);
            break;
        case CLRegionStateUnknown:
            [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
            [self.rangeBeaconsDictionary removeObjectForKey:((CLBeaconRegion *)region).proximityUUID.UUIDString];;
            LMLog(@"Stop range. State changed to Unknown for region %@", region);
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    LMLog(@"monitoringDidFailForRegion:%@ error:%@", region, error);
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    LMLog(@"rangingBeaconsDidFailForRegion:%@ error:%@", region, error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    LMLog(@"locationManagerDidFailWithError:%@", error);
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    LMLog(@"Monitoring for region started successfully:%@", region);
}

@end
