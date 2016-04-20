//
//  CFunctions.m
//  iBeaconDemo
//
//  Created by Tozy on 14-8-12.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import "CFunctions.h"
#import "LogManager.h"
#import <CoreLocation/CoreLocation.h>

void LMLogv(NSString *format, va_list args)
{
    NSDate *now = [NSDate date];

    static NSUInteger c = NSCalendarUnitSecond  |
                          NSCalendarUnitHour    |
                          NSCalendarUnitMinute  ;

	NSDateComponents *components = [[NSCalendar currentCalendar] components:c fromDate:now];

    NSString *prefix = [NSString stringWithFormat:@"[%02d:%02d:%02d] ", (int)components.hour, (int)components.minute, (int)components.second];
    NSString *body = [[NSString alloc] initWithFormat:format arguments:args];

    [LogManagerInstance() logMessage:[NSString stringWithFormat:@"%@%@\n", prefix, body]];
}

void LMLog(NSString *format, ...)
{
    va_list ap;
    va_start(ap, format);
    LMLogv(format, ap);
    va_end(ap);
}

BOOL CLBeaconRegionEqualToRegion(CLBeaconRegion *region1, CLBeaconRegion *region2)
{
    BOOL UUIDEqual = [region1.proximityUUID.UUIDString isEqualToString:region2.proximityUUID.UUIDString];
    BOOL majorEqual = [region1.major isEqual:region2.major] || (region1.major == nil && region2.major == nil);
    BOOL minorEqual = [region1.minor isEqual:region2.minor] || (region1.minor == nil && region2.minor == nil);
    return UUIDEqual && majorEqual && minorEqual;
}

BOOL CLBeaconEqualToBeacon(CLBeacon *beacon1, CLBeacon *beacon2)
{
    BOOL UUIDEqual = [beacon1.proximityUUID.UUIDString isEqualToString:beacon2.proximityUUID.UUIDString];
    BOOL majorEqual = [beacon1.major isEqual:beacon2.major] || (beacon1.major == nil && beacon2.major == nil);
    BOOL minorEqual = [beacon1.minor isEqual:beacon2.minor] || (beacon1.minor == nil && beacon2.minor == nil);
    return UUIDEqual && majorEqual && minorEqual;
}

NSArray *StoredRegions()
{
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:SKey_MonitoringRegions];
    NSMutableArray *regions = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (NSData *data in array) {
        [regions addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    }
    return regions;
}

void DeleteStoredRegion(CLBeaconRegion *region)
{
    if (!region) {
        return;
    }
    NSArray *storedRegions = StoredRegions();
    if ([storedRegions containsObject:region])
    {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:SKey_MonitoringRegions]];

        for (int i = 0; i < array.count; i++) {

            CLBeaconRegion *oneRegion = [NSKeyedUnarchiver unarchiveObjectWithData:array[i]];

            if (CLBeaconRegionEqualToRegion(oneRegion, region)) {
                [array removeObjectAtIndex:i];
                [[NSUserDefaults standardUserDefaults] setObject:array forKey:SKey_MonitoringRegions];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[NSNotificationCenter defaultCenter] postNotificationName:NKey_MonitoringRegionsChanged object:nil userInfo:@{SKey_Kind: SKey_Delete, SKey_Region:region}];
                break;
            }
        }
    }
    else
    {
        LMLog(@"StoredRegions don't contain region %@", region);
    }
}


void RegisterDefaultsFromSettingsBundle()
{
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings"ofType:@"bundle"];

    if(!settingsBundle) {
        LMLog(@"Could not find Settings.bundle");
        return;
    }

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];

    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];

    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];

    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}
