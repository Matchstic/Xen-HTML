//
// MSRGBView.m
//
// Created by Maksym Shcheglov on 2014-02-16.
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

#import "MSRGBView.h"
#import "MSColorComponentView.h"
#import "MSSliderView.h"
#import "MSColorUtils.h"
#import "MSColorPicker.h"

#import "XENHResources.h"

extern CGFloat const MSRGBColorComponentMaxValue;

static NSUInteger const MSRGBColorComponentsSize = 3;

@interface MSRGBView () <UITextFieldDelegate>
{
    @private

    NSArray *_colorComponentViews;
    RGB _colorComponents;
    UITextField *_hexInputField;
    UILabel *_hexInputLabel;
}

@end

@implementation MSRGBView

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
    [self ms_reloadColorComponentViews:_colorComponents];
}

- (void)setColor:(UIColor *)color
{
    _colorComponents = MSRGBColorComponents(color);
    _hexInputField.text = [self textContentFromColor:color];
    [self reloadData];
}

- (UIColor *)color
{
    return [UIColor colorWithRed:_colorComponents.red green:_colorComponents.green blue:_colorComponents.blue alpha:_colorComponents.alpha];
}

- (NSString*)textContentFromColor:(UIColor*)color {
    return [MSHexStringFromColor(color) stringByReplacingOccurrencesOfString:@"#" withString:@""];
}

#pragma mark - Private methods

- (void)ms_baseInit
{
    self.accessibilityLabel = @"rgb_view";

    NSMutableArray *tmp = [NSMutableArray array];
    NSArray *titles = @[
        [XENHResources localisedStringForKey:@"RED"],
        [XENHResources localisedStringForKey:@"GREEN"],
        [XENHResources localisedStringForKey:@"BLUE"]
    ];
    NSArray *maxValues = @[@(MSRGBColorComponentMaxValue), @(MSRGBColorComponentMaxValue), @(MSRGBColorComponentMaxValue)];

    for (NSUInteger i = 0; i < MSRGBColorComponentsSize; ++i) {
        UIControl *colorComponentView = [self ms_colorComponentViewWithTitle:titles[i] tag:i maxValue:[maxValues[i] floatValue]];
        [self addSubview:colorComponentView];
        [colorComponentView addTarget:self action:@selector(ms_colorComponentDidChangeValue:) forControlEvents:UIControlEventValueChanged];
        [tmp addObject:colorComponentView];
    }

    _colorComponentViews = [tmp copy];
    
    // Hex input editor
    _hexInputField = [[UITextField alloc] init];
    [_hexInputField setKeyboardType:UIKeyboardTypeAlphabet];
    _hexInputField.textAlignment = NSTextAlignmentCenter;
    _hexInputField.layer.cornerRadius = 5;
    _hexInputField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    _hexInputField.autocorrectionType = UITextAutocorrectionTypeNo;
    _hexInputField.placeholder = [XENHResources localisedStringForKey:@"HEX"];
    _hexInputField.inputAccessoryView = [self keyboardDoneButton];
    
    if (@available(iOS 13.0, *)) {
        _hexInputField.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
        _hexInputField.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    } else {
        _hexInputField.backgroundColor = [UIColor whiteColor];
    }
    [self addSubview:_hexInputField];

    [_hexInputField setDelegate:self];
    
    _hexInputLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _hexInputLabel.textAlignment = NSTextAlignmentRight;
    _hexInputLabel.text = [XENHResources localisedStringForKey:@"HEXCODE"];
    _hexInputLabel.font = [UIFont systemFontOfSize:16];
    
    [self addSubview:_hexInputLabel];
}

- (void)ms_colorComponentDidChangeValue:(MSColorComponentView *)sender
{
    [self ms_setColorComponentValue:sender.value / sender.maximumValue atIndex:sender.tag];
    [self.delegate colorView:self didChangeColor:self.color];
    [self reloadData];
}

- (void)ms_setColorComponentValue:(CGFloat)value atIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            _colorComponents.red = value;
            break;

        case 1:
            _colorComponents.green = value;
            break;

        case 2:
            _colorComponents.blue = value;
            break;

        default:
            _colorComponents.alpha = value;
            break;
    }
}

- (UIControl *)ms_colorComponentViewWithTitle:(NSString *)title tag:(NSUInteger)tag maxValue:(CGFloat)maxValue
{
    MSColorComponentView *colorComponentView = [[MSColorComponentView alloc] init];

    colorComponentView.title = title;
    colorComponentView.translatesAutoresizingMaskIntoConstraints = NO;
    colorComponentView.tag  = tag;
    colorComponentView.maximumValue = maxValue;
    return colorComponentView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    __block CGFloat y = 0;
    [_colorComponentViews enumerateObjectsUsingBlock:^(UIView *colorComponentView, NSUInteger idx, BOOL *stop) {
        colorComponentView.frame = CGRectMake(0, y, self.bounds.size.width, MSSliderViewTrackHeight * 2);
        y += MSSliderViewTrackHeight * 2;
    }];
    
    y += MSSliderViewTrackHeight;
    _hexInputField.frame = CGRectMake(self.bounds.size.width - 80, y, 80, 32);
    _hexInputLabel.frame = CGRectMake(0, y, self.bounds.size.width - 80 - 16, 32);
}

- (NSArray *)ms_colorComponentsWithRGB:(RGB)rgb
{
    return @[@(rgb.red), @(rgb.green), @(rgb.blue), @(rgb.alpha)];
}

- (void)ms_reloadColorComponentViews:(RGB)colorComponents
{
    NSArray *components = [self ms_colorComponentsWithRGB:colorComponents];

    [_colorComponentViews enumerateObjectsUsingBlock:^(MSColorComponentView *colorComponentView, NSUInteger idx, BOOL *stop) {
         [colorComponentView setColors:[self ms_colorsWithColorComponents:components
                                                        currentColorIndex:colorComponentView.tag]];
         colorComponentView.value = [components[idx] floatValue] * colorComponentView.maximumValue;
     }];
}

- (NSArray *)ms_colorsWithColorComponents:(NSArray *)colorComponents currentColorIndex:(NSUInteger)colorIndex
{
    CGFloat currentColorValue = [colorComponents[colorIndex] floatValue];
    CGFloat colors[12];

    for (NSUInteger i = 0; i < MSRGBColorComponentsSize; i++) {
        colors[i] = [colorComponents[i] floatValue];
        colors[i + 4] = [colorComponents[i] floatValue];
        colors[i + 8] = [colorComponents[i] floatValue];
    }

    colors[colorIndex] = 0;
    colors[colorIndex + 4] = currentColorValue;
    colors[colorIndex + 8] = 1.0;
    UIColor *start = [UIColor colorWithRed:colors[0] green:colors[1] blue:colors[2] alpha:1.0f];
    UIColor *middle = [UIColor colorWithRed:colors[4] green:colors[5] blue:colors[6] alpha:1.0f];
    UIColor *end = [UIColor colorWithRed:colors[8] green:colors[9] blue:colors[10] alpha:1.0f];
    return @[(id)start.CGColor, (id)middle.CGColor, (id)end.CGColor];
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] postNotificationName:MSColorTextFieldDidStartEditing object:nil userInfo:@{
        @"field": textField
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.text.length != 6) {
        // Reset to previous
        _hexInputField.text = [self textContentFromColor:[self color]];
        return;
    }
    
    NSString *hex = [NSString stringWithFormat:@"#%@", textField.text];
    UIColor *color = MSColorFromHexString(hex);
    
    [self.delegate colorView:self didChangeColor:color];
    
    _colorComponents = MSRGBColorComponents(color);
    [self reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];

    //first, check if the new string is numeric only. If not, return NO;
    NSCharacterSet *characterSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"] invertedSet];

    if ([newString rangeOfCharacterFromSet:characterSet].location != NSNotFound) {
        return NO;
    }

    // Only allow max length of 6
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;

    NSUInteger newLength = oldLength - rangeLength + replacementLength;

    return newLength <= 6;
}

- (UIView*)keyboardDoneButton
{
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"DONE"]
                                                                   style:UIBarButtonItemStyleDone target:self
                                                                  action:@selector(barButtonHitDone:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:flex, doneButton, nil]];
    return keyboardDoneButtonView;
}

- (void)barButtonHitDone:(id)sender {
    [_hexInputField resignFirstResponder];
}

@end
