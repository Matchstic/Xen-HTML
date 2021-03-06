//
// MSThumbView.m
//
// Created by Maksym Shcheglov on 2016-05-25.
// Copyright (c) 2016 Maksym Shcheglov.
// License: http://opensource.org/licenses/MIT
//

#import "MSThumbView.h"
#import <objc/runtime.h>

static const CGFloat MSSliderViewThumbDimension = 28.0f;

@interface MSThumbView ()
@property (nonatomic, strong) CALayer *thumbLayer;
@property (nonatomic, strong) UIGestureRecognizer *gestureRecognizer;
@end

@implementation MSThumbView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, MSSliderViewThumbDimension, MSSliderViewThumbDimension)];

    if (self) {
        self.thumbLayer = [CALayer layer];

        self.thumbLayer.borderColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.4].CGColor;
        self.thumbLayer.borderWidth = .5;
        self.thumbLayer.cornerRadius = MSSliderViewThumbDimension / 2;
        self.thumbLayer.backgroundColor = [UIColor whiteColor].CGColor;
        self.thumbLayer.shadowColor = [UIColor blackColor].CGColor;
        self.thumbLayer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.thumbLayer.shadowRadius = 2;
        self.thumbLayer.shadowOpacity = 0.3f;
        [self.layer addSublayer:self.thumbLayer];
        self.gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:nil action:nil];
        [self addGestureRecognizer:self.gestureRecognizer];
    }

    return self;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    if (layer != self.layer) {
        return;
    }

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    self.thumbLayer.bounds = CGRectMake(0, 0, MSSliderViewThumbDimension, MSSliderViewThumbDimension);
    self.thumbLayer.position = CGPointMake(MSSliderViewThumbDimension / 2, MSSliderViewThumbDimension / 2);
    [CATransaction commit];
}

- (void)setHitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets
{
    NSValue *value = [NSValue value:&hitTestEdgeInsets withObjCType:@encode(UIEdgeInsets)];
    objc_setAssociatedObject(self, @selector(hitTestEdgeInsets), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)hitTestEdgeInsets
{
    NSValue *value = objc_getAssociatedObject(self, @selector(hitTestEdgeInsets));

    if (value) {
        UIEdgeInsets edgeInsets;
        [value getValue:&edgeInsets];
        return edgeInsets;
    }

    return UIEdgeInsetsZero;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden || !self.userInteractionEnabled || self.alpha == 0) return [super pointInside:point withEvent:event];

    CGRect relativeFrame = self.bounds;
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.hitTestEdgeInsets);

    return CGRectContainsPoint(hitFrame, point);
}

@end
