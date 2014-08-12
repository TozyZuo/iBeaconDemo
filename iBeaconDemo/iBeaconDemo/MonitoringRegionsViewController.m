//
//  AddRegionViewController.m
//  iBeaconDemo
//
//  Created by Tozy on 14-8-6.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import "MonitoringRegionsViewController.h"
#import "AddRegionViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface MonitoringRegionsViewController ()
@property (nonatomic, strong) NSArray *monitoringRegions;
@end

@implementation MonitoringRegionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"MonitoringRegions";
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction)];

    __weak MonitoringRegionsViewController *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NKey_MonitoringRegionsChanged object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf reloadData];
    }];

    [self reloadData];
}

- (void)reloadData
{
    self.monitoringRegions = StoredRegions();
    [self.tableView reloadData];
}

- (void)addAction
{
    [self.navigationController pushViewController:[[AddRegionViewController alloc] init] animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.monitoringRegions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"BeaconCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"BeaconCell" owner:nil options:nil][0];
    }
    CLBeaconRegion *region = self.monitoringRegions[indexPath.row];
    ((UILabel *)[cell viewWithTag:1]).text = region.proximityUUID.UUIDString;
    ((UILabel *)[cell viewWithTag:2]).text = [NSString stringWithFormat:@"major:%@ minor:%@", region.major, region.minor];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        DeleteStoredRegion(self.monitoringRegions[indexPath.row]);
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    CLBeaconRegion *region = self.monitoringRegions[indexPath.row];
    AddRegionViewController *vc = [[AddRegionViewController alloc] init];

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:region.proximityUUID.UUIDString forKey:SKey_UUID];
    [params setValue:region.major forKey:SKey_Major];
    [params setValue:region.minor forKey:SKey_Minor];

    vc.params = params;

    [self.navigationController pushViewController:vc animated:YES];
}


@end
