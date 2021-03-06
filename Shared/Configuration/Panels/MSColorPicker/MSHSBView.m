//
// MSHSBView.m
//
// Created by Maksym Shcheglov on 2014-02-17.
//
// The MIT License (MIT)
// Copyright (c) 2015 Maksym Shcheglov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSHSBView.h"
#import "MSColorWheelView.h"
#import "MSColorComponentView.h"
#import "MSSliderView.h"
#import "MSColorUtils.h"

#import "XENHResources.h"

extern CGFloat const MSAlphaComponentMaxValue;
extern CGFloat const MSHSBColorComponentMaxValue;

static CGFloat const MSColorWheelDimension = 250.0f;

@interface MSHSBView () <UITextFieldDelegate>
{
    @private

    MSColorWheelView *_colorWheel;
    MSColorComponentView *_brightnessView;
    MSColorComponentView *_opacityView;

    HSB _colorComponents;
    NSArray *_layoutConstraints;
}

@end

@implementation MSHSBView

@synthesize delegate = _delegate;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        [self ms_baseInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self ms_baseInit];
    }

    return self;
}

- (void)reloadData
{
    [self ms_reloadViewsWithColorComponents:_colorComponents];
}

- (void)setColor:(UIColor *)color
{
    _colorComponents = MSRGB2HSB(MSRGBColorComponents(color));
    [self reloadData];
}

- (UIColor *)color
{
    return [UIColor colorWithHue:_colorComponents.hue saturation:_colorComponents.saturation brightness:_colorComponents.brightness alpha:_colorComponents.alpha];
}

#pragma mark - Private methods

- (void)ms_baseInit
{
    self.accessibilityLabel = @"hsb_view";

    _colorWheel = [[MSColorWheelView alloc] init];
    [self addSubview:_colorWheel];

    _brightnessView = [[MSColorComponentView alloc] init];
    _brightnessView.title = [XENHResources localisedStringForKey:@"BRIGHTNESS"];
    _brightnessView.maximumValue = MSHSBColorComponentMaxValue;
    _brightnessView.format = @"%.2f";
    _brightnessView.useInput = NO;
    [self addSubview:_brightnessView];
    
    _opacityView = [[MSColorComponentView alloc] init];
    _opacityView.title = [XENHResources localisedStringForKey:@"OPACITY"];
    _opacityView.maximumValue = MSAlphaComponentMaxValue;
    _opacityView.format = @"%.f";
    _opacityView.useInput = NO;
    [self addSubview:_opacityView];

    [_colorWheel addTarget:self action:@selector(ms_colorDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    [_brightnessView addTarget:self action:@selector(ms_brightnessDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    [_opacityView addTarget:self action:@selector(ms_opacityDidChangeValue:) forControlEvents:UIControlEventValueChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _colorWheel.frame = CGRectMake((self.bounds.size.width - MSColorWheelDimension) / 2, 16, MSColorWheelDimension, MSColorWheelDimension);
    
    CGFloat sliderHeight = MSSliderViewTrackHeight * 2;
    _brightnessView.frame = CGRectMake(0, MSColorWheelDimension + 32, self.bounds.size.width, sliderHeight);
    _opacityView.frame = CGRectMake(0, MSColorWheelDimension + 32 + sliderHeight, self.bounds.size.width, sliderHeight);
}

- (void)ms_reloadViewsWithColorComponents:(HSB)colorComponents
{
    _colorWheel.hue = colorComponents.hue;
    _colorWheel.saturation = colorComponents.saturation;
    [self ms_updateSlidersWithColorComponents:colorComponents];
}

- (void)ms_updateSlidersWithColorComponents:(HSB)colorComponents
{
    UIColor *tmp = [UIColor colorWithHue:colorComponents.hue saturation:colorComponents.saturation brightness:1.0f alpha:1.0f];
    
    [_brightnessView setValue:colorComponents.brightness];
    [_brightnessView setColors:@[(id)[UIColor blackColor].CGColor, (id)tmp.CGColor]];
    
    [_opacityView setValue:colorComponents.alpha * 100.0];
    [_opacityView setColors:@[(id)[UIColor clearColor].CGColor, (id)tmp.CGColor]];
}

- (void)ms_colorDidChangeValue:(MSColorWheelView *)sender
{
    _colorComponents.hue = sender.hue;
    _colorComponents.saturation = sender.saturation;
    [self.delegate colorView:self didChangeColor:self.color];
    [self reloadData];
}

- (void)ms_brightnessDidChangeValue:(MSColorComponentView *)sender
{
    _colorComponents.brightness = sender.value;
    [self.delegate colorView:self didChangeColor:self.color];
    [self reloadData];
}

- (void)ms_opacityDidChangeValue:(MSColorComponentView *)sender
{
    _colorComponents.alpha = sender.value / 100.0;
    [self.delegate colorView:self didChangeColor:self.color];
    [self reloadData];
}

@end
