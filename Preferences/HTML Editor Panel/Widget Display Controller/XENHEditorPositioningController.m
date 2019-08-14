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

#import "XENHEditorPositioningController.h"
#import "XENHPResources.h"

@interface XENHEditorPositioningController ()

@property (nonatomic, weak) id<XENHEditorPositioningDelegate> delegate;

@property (nonatomic, weak) UIView *positioningView;
@property (nonatomic, readwrite) BOOL shouldSnapToGuides;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, readwrite) CGPoint startPoint;
@property (nonatomic, readwrite) CGPoint startOrigin;
@property (nonatomic, strong) UIView *verticalGuide;

@end

@implementation XENHEditorPositioningController

- (instancetype)initWithDelegate:(id<XENHEditorPositioningDelegate>)delegate shouldSnapToGuides:(BOOL)snapToGuides andPositioningView:(UIView*)posView {
    
    self = [super init];
    
    if (self) {
        self.delegate = delegate;
        self.shouldSnapToGuides = snapToGuides;
        self.positioningView = posView;
    }
    
    return self;
}

- (void)updatePositioningView:(UIView*)posView {
    self.positioningView = posView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
    [super loadView];
    
    self.view.userInteractionEnabled = YES;
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGesture.minimumNumberOfTouches = 1;
    
    [self.view addGestureRecognizer:self.panGesture];
    
    self.verticalGuide = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 0.5, 0, 1, self.view.bounds.size.height)];
    self.verticalGuide.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.verticalGuide.hidden = YES;
    self.verticalGuide.alpha = 0.0;
    self.verticalGuide.userInteractionEnabled = NO;
    
    [self.view addSubview:_verticalGuide];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.verticalGuide.frame = CGRectMake(self.view.bounds.size.width/2 - 0.5, 0, 1, self.view.bounds.size.height);
}

#pragma mark UIPanGestureRecongizer delegate

-(void)handlePan:(UIPanGestureRecognizer*)gesture {
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // If enabled, show guides.
        
        self.verticalGuide.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.positioningView.alpha = 0.75;
            self.verticalGuide.alpha = 1.0;
        }];
        
        self.startPoint = [gesture locationInView:self.view];
        self.startOrigin = self.positioningView.frame.origin;
        
        [self.delegate didStartPositioning];
        
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        // Move around on-screen.
        CGPoint currentPoint = [gesture locationInView:self.view];
        
        // If the current point is within 5px of a guideline, snap to it!
        // This is achieved by simply modifying the value of currentPoint.
        
        CGFloat xOffset = currentPoint.x - self.startPoint.x;
        CGFloat yOffset = currentPoint.y - self.startPoint.y;
        
        self.positioningView.frame = CGRectMake(self.startOrigin.x+xOffset, self.startOrigin.y+yOffset, self.positioningView.frame.size.width,  self.positioningView.frame.size.height);
        
        if (self.shouldSnapToGuides) {
            CGFloat center = self.view.bounds.size.width/2;
            
            if (self.positioningView.center.x > center-10 && self.positioningView.center.x < center+10) {
                // SNAP!
                self.positioningView.center = CGPointMake(center, self.positioningView.center.y);
            }
            
            // We do need to snap to the top edge if possible.
            if (self.positioningView.frame.origin.y < 10 && self.positioningView.frame.origin.y > -10) {
                // SNAP!
                self.positioningView.frame = CGRectMake(self.positioningView.frame.origin.x, 0, self.positioningView.frame.size.width, self.positioningView.frame.size.height);
            }
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        // Move around on-screen.
        CGPoint currentPoint = [gesture locationInView:self.view];
        
        CGFloat xOffset = currentPoint.x - self.startPoint.x;
        CGFloat yOffset = currentPoint.y - self.startPoint.y;
        
        self.positioningView.frame = CGRectMake(self.startOrigin.x+xOffset, self.startOrigin.y+yOffset, self.positioningView.frame.size.width, self.positioningView.frame.size.height);
        
        if (self.shouldSnapToGuides) {
            CGFloat center = self.view.bounds.size.width/2;
            
            if (self.positioningView.center.x > center-10 && self.positioningView.center.x < center+10) {
                // SNAP!
                self.positioningView.center = CGPointMake(center, self.positioningView.center.y);
            }
            
            // We do need to snap to the top edge if possible.
            if (self.positioningView.frame.origin.y < 10 && self.positioningView.frame.origin.y > -10) {
                // SNAP!
                self.positioningView.frame = CGRectMake(self.positioningView.frame.origin.x, 0, self.positioningView.frame.size.width, self.positioningView.frame.size.height);
            }
        }
        
        // Ensure that position is saved before the user navigates backwards
        [self.delegate didUpdatePositioningWithX:self.positioningView.frame.origin.x/self.view.frame.size.width andY:self.positioningView.frame.origin.y/self.view.frame.size.height];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.positioningView.alpha = 1.0;
            self.verticalGuide.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.verticalGuide.hidden = YES;
        }];
        
        [self.delegate didEndPositioning];
    }
}

@end
