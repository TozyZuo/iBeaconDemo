//
//  ConsoleView.m
//  iBeaconDemo
//
//  Created by Tozy on 14-8-12.
//  Copyright (c) 2014年 Tozy. All rights reserved.
//

#import "ConsoleView.h"

@interface ConsoleView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) NSDictionary *attributes;

@end

@implementation ConsoleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialization];
    }
    return self;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"ConsoleView" owner:nil options:nil];
        for (UIView *view in array) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                _scrollView = (UIScrollView *)view;
            }
        }
    }
    return _scrollView;
}

- (UILabel *)label
{
    if (!_label) {
        NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"ConsoleView" owner:nil options:nil];
        for (UIView *view in array) {
            if ([view isKindOfClass:[UILabel class]]) {
                _label = (UILabel *)view;
                self.attributes = @{NSFontAttributeName: self.label.font};
            }
        }
    }
    return _label;
}

- (void)initialization
{
    self.scrollView.frame = self.bounds;
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.label];

    self.text = @"";
}

- (NSString *)text
{
    return self.label.text;
}

- (void)setText:(NSString *)text
{
    self.label.text = text;

    static NSInteger options = NSStringDrawingUsesLineFragmentOrigin    |
                               NSStringDrawingUsesFontLeading           |
                               NSStringDrawingTruncatesLastVisibleLine;

    CGRect rect = [text boundingRectWithSize:CGSizeMake(self.frame.size.width, MAXFLOAT) options:options attributes:self.attributes context:nil];
    rect.size.width = self.bounds.size.width;
    self.label.frame = rect;

    CGFloat bottom = self.scrollView.contentOffset.y + self.scrollView.bounds.size.height;
    if (bottom >= self.scrollView.contentSize.height - .3) {// auto roll
        CGFloat y = rect.size.height - self.scrollView.bounds.size.height;
        self.scrollView.contentOffset = CGPointMake(0, MAX(0, y));
    }
    self.scrollView.contentSize = rect.size;
}

@end
