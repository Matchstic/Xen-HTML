/*
 Copyright (C) 2018  Matt Clarke
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

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
