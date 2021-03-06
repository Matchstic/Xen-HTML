//
// MSColorComponentView.m
//
// Created by Maksym Shcheglov on 2014-02-12.
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

#import "MSColorComponentView.h"
#import "MSSliderView.h"
#import "MSColorPicker.h"

#import "XENHResources.h"

extern CGFloat const MSRGBColorComponentMaxValue;

@interface MSColorComponentView () <UITextFieldDelegate>
{
    @private

    UILabel *_label;
    MSSliderView *_slider; // The color slider to edit color component.
    UITextField *_textField;
    BOOL _useInput;
}

@end

@implementation MSColorComponentView

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

- (void)setTitle:(NSString *)title
{
    _label.text = [title uppercaseString];
}

- (void)setMinimumValue:(CGFloat)minimumValue
{
    _slider.minimumValue = minimumValue;
}

- (void)setMaximumValue:(CGFloat)maximumValue
{
    _slider.maximumValue = maximumValue;
}

- (void)setValue:(CGFloat)value
{
    _slider.value = value;
    _textField.text = [NSString stringWithFormat:_format, value];
}

- (void)setUseInput:(BOOL)useInput {
    _useInput = useInput;
    
    _textField.hidden = !useInput;
}

- (NSString *)title
{
    return _label.text;
}

- (CGFloat)minimumValue
{
    return _slider.minimumValue;
}

- (CGFloat)maximumValue
{
    return _slider.maximumValue;
}

- (CGFloat)value
{
    return _slider.value;
}

- (void)setColors:(NSArray *)colors
{
    NSParameterAssert(colors);
    [_slider setColors:colors];
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] postNotificationName:MSColorTextFieldDidStartEditing object:nil userInfo:@{
        @"field": textField
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self setValue:[textField.text floatValue]];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
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
    NSCharacterSet *characterSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789,."] invertedSet];

    if ([newString rangeOfCharacterFromSet:characterSet].location != NSNotFound) {
        return NO;
    }

    return [newString floatValue] <= _slider.maximumValue;
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
    [_textField resignFirstResponder];
}

#pragma mark - Private methods

- (void)ms_baseInit
{
    self.accessibilityLabel = @"color_component_view";

    _format = @"%.f";
    _useInput = YES;

    _label = [[UILabel alloc] init];
    _label.font = [UIFont systemFontOfSize:12];
    
    if (@available(iOS 13.0, *)) {
        _label.textColor = [UIColor secondaryLabelColor];
    } else {
        _label.textColor = [UIColor grayColor];
    }
    
    [self addSubview:_label];

    _slider = [[MSSliderView alloc] init];
    _slider.maximumValue = MSRGBColorComponentMaxValue;
    [self addSubview:_slider];
    
    _textField = [[UITextField alloc] init];
    [_textField setKeyboardType:UIKeyboardTypeDecimalPad];
    _textField.textAlignment = NSTextAlignmentCenter;
    _textField.layer.cornerRadius = 5;
    _textField.inputAccessoryView = [self keyboardDoneButton];
    if (@available(iOS 13.0, *)) {
        _textField.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
        _textField.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    } else {
        _textField.backgroundColor = [UIColor whiteColor];
    }
    [self addSubview:_textField];

    [self setValue:0.0f];
    [_slider addTarget:self action:@selector(ms_didChangeSliderValue:) forControlEvents:UIControlEventValueChanged];
    [_textField setDelegate:self];
}

- (void)ms_didChangeSliderValue:(MSSliderView *)sender
{
    [self setValue:sender.value];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _label.frame = CGRectMake(0, 0, self.bounds.size.width, 32);
    
    if (_useInput) {
        CGFloat inputWidth = 50;
        _slider.frame = CGRectMake(0, 32, self.bounds.size.width - inputWidth - 16, MSSliderViewTrackHeight);
        _textField.frame = CGRectMake(self.bounds.size.width - inputWidth, 32 + 3, inputWidth, MSSliderViewTrackHeight - 6);
    } else {
        _slider.frame = CGRectMake(0, 32, self.bounds.size.width, MSSliderViewTrackHeight);
    }
}

@end
