//
//  RangingViewController.m
//  iBeaconDemo
//
//  Created by Tozy on 14-8-6.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import "RangingViewController.h"
#import "MonitoringRegionsViewController.h"
#import "BeaconManager.h"
#import "LogManager.h"
#import "ConsoleView.h"

@interface RangingViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet ConsoleView *consoleView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (nonatomic, strong) NSArray *rangeBeacons;
@property (nonatomic, strong) NSArray *sectionTitles;

@end

@implementation RangingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    LogManagerInstance().consoleView = self.consoleView;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 40, 30);
    [btn addTarget:self action:@selector(toggleLogAction:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"Log" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithRed:0x45/255. green:0x79/255. blue:0xfb/255. alpha:1] forState:UIControlStateNormal];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction)];
    self.navigationItem.titleView = self.segmentedControl;

    [self toggleLogAction:nil];

    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(update:) userInfo:nil repeats:YES];

    CGRect frame = self.consoleView.frame;
    frame.size.width = [UIScreen mainScreen].applicationFrame.size.width;
    self.consoleView.frame = frame;
}

#pragma mark - Action

- (IBAction)reloadAction
{
    [self update:nil];
}

- (void)addAction
{
    [self.navigationController pushViewController:[[MonitoringRegionsViewController alloc] init] animated:YES];
}

- (void)toggleLogAction:(UIButton *)btn
{
    self.consoleView.hidden = !self.consoleView.hidden;

    CGRect frame = self.tableView.frame;
    frame.size.height = 128 - self.tableView.frame.size.height + 376 * 2;
    self.tableView.frame = frame;
}

#pragma mark - Private

- (NSArray *)sortedBeaconsArray
{
    return [BeaconManagerInstance().rangedBeacons sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CLBeacon *b1 = (CLBeacon *)obj1;
        CLBeacon *b2 = (CLBeacon *)obj2;
        switch (self.segmentedControl.selectedSegmentIndex) {
            case 0: {// UUID
                NSString *uuid1 = b1.proximityUUID.UUIDString;
                NSString *uuid2 = b2.proximityUUID.UUIDString;
                if ([uuid1 isEqualToString:uuid2])
                {
                    double c1 = b1.accuracy > 0 ? b1.accuracy : MAXFLOAT;
                    double c2 = b2.accuracy > 0 ? b2.accuracy : MAXFLOAT;
                    if (c1 < c2)
                    {
                        return NSOrderedAscending;
                    }
                    else
                    {
                        return NSOrderedDescending;
                    }
                }
                else
                {
                    return [uuid1 compare:uuid2];
                }
            }
                break;
            case 1: {// Distance
                double c1 = b1.accuracy > 0 ? b1.accuracy : MAXFLOAT;
                double c2 = b2.accuracy > 0 ? b2.accuracy : MAXFLOAT;
                if (c1 < c2)
                {
                    return NSOrderedAscending;
                }
                else
                {
                    return NSOrderedDescending;
                }
            }
            case 2: {// Major
                short m1 = b1.major ? b1.major.shortValue : -1;
                short m2 = b2.major ? b2.major.shortValue : -1;
                if (m1 < m2)
                {
                    return NSOrderedAscending;
                }
                else
                {
                    return NSOrderedDescending;
                }
            }
            case 3: {// Minor
                short m1 = b1.minor ? b1.minor.shortValue : -1;
                short m2 = b2.minor ? b2.minor.shortValue : -1;
                if (m1 < m2)
                {
                    return NSOrderedAscending;
                }
                else
                {
                    return NSOrderedDescending;
                }
            }
        }
        return NSOrderedSame;
    }];
}

- (void)manageDataSourceWithSortedBeacons:(NSArray *)beacons
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSMutableArray *sectionTitles = [[NSMutableArray alloc] init];
    NSInteger index = -1;
    for (CLBeacon *beacon in beacons) {
        CLBeacon *oneBeacon;
        if (array.count && [array[index] count]) {
            oneBeacon = array[index][0];
        }
        BOOL isIn = NO;
        NSString *key;
        switch (self.segmentedControl.selectedSegmentIndex) {
            case 0: {// UUID
                isIn = [oneBeacon.proximityUUID.UUIDString isEqualToString:beacon.proximityUUID.UUIDString];
                key = isIn ? @"" : beacon.proximityUUID.UUIDString;
            }
                break;
            case 1: {// Distance
                isIn = oneBeacon ? YES : NO;
                key = @"";// prevent crash
            }
                break;
            case 2: {// Major
                NSNumber *m1 = oneBeacon.major;
                NSNumber *m2 = beacon.major;
                if (m1 && m2)
                {
                    isIn = m1.shortValue == m2.shortValue;
                    key = [NSString stringWithFormat:@"%@", m2];
                }
                else if (!(m1 || m2))
                {
                    isIn = YES;
                }
                else
                {
                    isIn = NO;
                    key = [NSString stringWithFormat:@"%@", m2];
                }
            }
                break;
            case 3: {// Minor
                NSNumber *m1 = oneBeacon.minor;
                NSNumber *m2 = beacon.minor;
                if (m1 && m2)
                {
                    isIn = m1.shortValue == m2.shortValue;
                    key = [NSString stringWithFormat:@"%@", m2];
                }
                else if (!(m1 || m2))
                {
                    isIn = YES;
                }
                else
                {
                    isIn = NO;
                    key = [NSString stringWithFormat:@"%@", m2];
                }
            }
        }
        if (isIn)
        {
            [array[index] addObject:beacon];
        }
        else
        {
            [sectionTitles addObject:key];
            [array addObject:[[NSMutableArray alloc] init]];
            [array[++index] addObject:beacon];
        }
    }
    self.sectionTitles = sectionTitles;
    self.rangeBeacons = array;
}

- (void)update:(NSTimer *)timer
{
    [self manageDataSourceWithSortedBeacons:[self sortedBeaconsArray]];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.rangeBeacons.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.rangeBeacons[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.segmentedControl.selectedSegmentIndex == 1) {
        return nil;
    }
    return self.sectionTitles[section];
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"BeaconCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"BeaconCell" owner:nil options:nil][0];
    }

    CLBeacon *beacon = self.rangeBeacons[indexPath.section][indexPath.row];

    ((UILabel *)[cell viewWithTag:1]).text = beacon.proximityUUID.UUIDString;

    NSString *distance;
    if (beacon.accuracy > 0)
    {
        distance = [NSString stringWithFormat:@"%.2fM", beacon.accuracy];
    }
    else
    {
        distance = @"unknown";
    }
    ((UILabel *)[cell viewWithTag:2]).text = [NSString stringWithFormat:@"major:%@ minor:%@ distance:%@", beacon.major, beacon.minor, distance];
    
    return cell;
}

@end
