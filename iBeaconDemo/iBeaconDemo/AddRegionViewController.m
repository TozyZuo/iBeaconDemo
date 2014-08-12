//
//  AddRegionViewController.m
//  iBeaconDemo
//
//  Created by Tozy on 14-8-6.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import "AddRegionViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface AddRegionViewController ()
<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *major;
@property (weak, nonatomic) IBOutlet UITextField *minor;
@property (weak, nonatomic) IBOutlet UITextField *pwr;
@property (weak, nonatomic) IBOutlet UITextField *uuid;

@property (nonatomic, strong) NSArray *autoAddLineLength;
@property (nonatomic, strong) NSString *changedString;
@property (nonatomic, strong) CLBeaconRegion *region;
@end

@implementation AddRegionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *uuid = self.params[SKey_UUID];
    if (uuid) {
        self.uuid.text = uuid;
        id major = self.params[SKey_Major];
        id minor = self.params[SKey_Minor];
        id pwr = self.params[SKey_Power];
        self.major.text = [NSString stringWithFormat:@"%@", major ? major : @""];
        self.minor.text = [NSString stringWithFormat:@"%@", minor ? minor : @""];
        self.pwr.text = [NSString stringWithFormat:@"%@", pwr ? pwr : @""];
        self.region = [self regionWithUUID:uuid major:self.major.text minor:self.minor.text];
    }

    self.autoAddLineLength = @[@(8), @(13), @(18), @(23)];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];

    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if ([note.object isEqual:self.uuid]) {
            if ([self.autoAddLineLength containsObject:@(self.uuid.text.length)] &&
                ![self.changedString isEqualToString:@""]) {
                self.uuid.text = [self.uuid.text stringByAppendingString:@"-"];
            }
            self.uuid.text = [self.uuid.text uppercaseString];
        }
    }];
}

- (CLBeaconRegion *)regionWithUUID:(NSString *)uuid major:(NSString *)major minor:(NSString *)minor
{
    CLBeaconRegion *region;

    BOOL majorValid = major && major.length;
    BOOL minorValid = minor && minor.length;

    if (majorValid && minorValid)
    {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuid] major:major.intValue minor:minor.intValue identifier:uuid];
    }
    else if (majorValid)
    {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuid] major:major.intValue identifier:uuid];
    }
    else
    {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuid] identifier:uuid];
    }

    return region;
}

- (void)tapAction
{
    [self.view endEditing:YES];
}

- (IBAction)saveAction:(UIButton *)sender
{
    if (!self.uuid.text.length) {
        return;
    }

    DeleteStoredRegion(self.region);

    CLBeaconRegion *region = [self regionWithUUID:self.uuid.text major:self.major.text minor:self.minor.text];

    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:SKey_MonitoringRegions]];
    [array addObject:[NSKeyedArchiver archivedDataWithRootObject:region]];

    [[NSUserDefaults standardUserDefaults] setObject:array forKey:SKey_MonitoringRegions];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:NKey_MonitoringRegionsChanged object:nil userInfo:@{SKey_Kind: SKey_Add, SKey_Region: region}];

    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    CGFloat bottom = textField.frame.origin.y + textField.frame.size.height;
    CGFloat visibale = self.view.frame.size.height - 216;// keyboard height
    CGFloat delta = MAX(0, bottom - visibale);
    [self.scrollView setContentOffset:CGPointMake(0, delta) animated:YES];

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    [self.scrollView setContentOffset:CGPointZero animated:YES];

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField isEqual:self.uuid]) {
        self.changedString = string;
        return range.location < 36;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
