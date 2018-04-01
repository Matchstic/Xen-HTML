//
//  XENHPreviewScaledController.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 26/01/2018.
//

#import "XENHPreviewScaledController.h"

@interface XENHPreviewScaledController ()

@property (nonatomic, strong) UIView *scalingView;
@property (nonatomic, readwrite) CGFloat scaleRatio;

@end

@implementation XENHPreviewScaledController

- (void)fitToSize {
    self.view.bounds = CGRectMake(0, 0, self.containedViewController.view.bounds.size.width * self.scaleRatio, self.containedViewController.view.bounds.size.height * self.scaleRatio);
}

- (void)setContainedViewController:(UIViewController *)containedViewController previewHeight:(CGFloat)previewHeight {
    self.containedViewController = containedViewController;
    
    self.scalingView = [[UIView alloc] initWithFrame:containedViewController.view.bounds];
    self.scalingView.userInteractionEnabled = NO;
    self.scalingView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.scalingView];
    
    [self.scalingView addSubview:self.containedViewController.view];
    
    self.scaleRatio = previewHeight / self.containedViewController.view.frame.size.height;
    
    self.scalingView.transform = CGAffineTransformScale(CGAffineTransformIdentity, self.scaleRatio, self.scaleRatio);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.scalingView.center = CGPointMake((self.containedViewController.view.bounds.size.width * self.scaleRatio)/2.0, (self.containedViewController.view.bounds.size.height * self.scaleRatio)/2.0);
}

@end
