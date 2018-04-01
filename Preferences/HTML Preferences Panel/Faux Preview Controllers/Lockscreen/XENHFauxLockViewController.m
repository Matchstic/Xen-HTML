//
//  XENHFauxLockViewController.m
//  
//
//  Created by Matt Clarke on 07/09/2016.
//
//

#import "XENHFauxLockViewController.h"
#import "XENHResources.h"
#import <objc/runtime.h>

@interface XENHFauxLockViewController ()

@end

@implementation XENHFauxLockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.userInteractionEnabled = NO;
    
    _dateView = [objc_getClass("SBFLockScreenDateView") alloc];
    if ([_dateView respondsToSelector:@selector(initForDashBoard:withFrame:)])
        _dateView = [_dateView initForDashBoard:YES withFrame:CGRectMake(0, 0, SCREEN_MIN_LENGTH, 100)];
    else
        _dateView = [_dateView initWithFrame:CGRectMake(0, 0, SCREEN_MIN_LENGTH, 100)];
    
    _dateView.date = [NSDate date];
    
    if ([_dateView respondsToSelector:@selector(_addLabels)])
        [_dateView _addLabels];
    if ([_dateView respondsToSelector:@selector(_updateLabels)])
        [_dateView _updateLabels];
    
    [self reloadForSettingsChange];
    
    [self.view addSubview:_dateView];
}

- (BOOL)shouldHideClock {
    if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
        id value = [XENHResources getPreferenceKey:@"hideClock"];
        return (value ? [value boolValue] : NO);
    } else {
        id value = [XENHResources getPreferenceKey:@"hideClock10"];
        return (value ? [value intValue] : 0) > 0;
    }
}

- (void)reloadForSettingsChange {
    _dateView.alpha = [self shouldHideClock] ? 0.1 : 1.0;
    [_dateView setNeedsDisplay];
    [_dateView setNeedsLayout];
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _dateView.frame = CGRectMake(0, [objc_getClass("SBFLockScreenMetrics") dateViewBaselineY] - [objc_getClass("SBFLockScreenMetrics") dateBaselineOffsetFromTime], SCREEN_MIN_LENGTH, [objc_getClass("SBFLockScreenDateView") defaultHeight]);
}

@end
