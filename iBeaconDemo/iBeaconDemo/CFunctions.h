//
//  CFunctions.h
//  iBeaconDemo
//
//  Created by Tozy on 14-8-12.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

@class CLBeaconRegion, CLBeacon;
extern NSArray *StoredRegions();
extern void DeleteStoredRegion(CLBeaconRegion *region);
extern BOOL CLBeaconRegionEqualToRegion(CLBeaconRegion *region1, CLBeaconRegion *region2);
extern BOOL CLBeaconEqualToBeacon(CLBeacon *beacon1, CLBeacon *beacon2);

void LMLog(NSString *format, ...);
void RegisterDefaultsFromSettingsBundle();