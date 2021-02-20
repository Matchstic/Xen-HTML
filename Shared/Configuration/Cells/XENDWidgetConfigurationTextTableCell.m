/*
 Copyright (C) 2021 Matt Clarke
 
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

#import "XENDWidgetConfigurationTextTableCell.h"
#import "XENHResources.h"

@interface XENDWidgetConfigurationTextTableCell ()
@property (nonatomic, strong) UITextField *textField;
@end

@implementation XENDWidgetConfigurationTextTableCell

- (void)setup {
    if (!self.textField) {
        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        self.textField.delegate = self;
        self.textField.textAlignment = NSTextAlignmentNatural;
        
        if (@available(iOS 13.0, *)) {
            self.textField.textColor = [UIColor labelColor];
            self.textField.backgroundColor = [UIColor systemGray5Color];
        } else {
            self.textField.textColor = [UIColor darkTextColor];
            self.textField.backgroundColor = [UIColor colorWithWhite:(229.0 / 255.0) alpha:1.0];
        }
        
        self.textField.layer.cornerRadius = 5;

        self.textField.returnKeyType = UIReturnKeyDone;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.inputAccessoryView = [self keyboardDoneButton];
        
        // Left padding
        self.textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 6, 44)];
        self.textField.leftViewMode = UITextFieldViewModeAlways;
        
        [self.contentView addSubview:self.textField];
    }
    
    NSString *currentValue = self.cell.value;
    NSString *placeholder = [self.cell.properties objectForKey:@"placeholder"];
    NSString *keyboardMode = [self.cell.properties objectForKey:@"mode"];
    if (currentValue) {
        self.textField.placeholder = placeholder ? placeholder : @"Text input";
        self.textField.text = currentValue ? [NSString stringWithFormat:@"%@", currentValue] : @"";
        
        // Swtup keyboard mode
        UIKeyboardType keyboardType = UIKeyboardTypeDefault;
        BOOL secureEntry = NO;
        if ([keyboardMode isEqualToString:@"email"]) {
            keyboardType = UIKeyboardTypeEmailAddress;
        } else if ([keyboardMode isEqualToString:@"password"]) {
            secureEntry = YES;
        }
        
        self.textField.keyboardType = keyboardType;
        self.textField.secureTextEntry = secureEntry;
    }
}

- (void)barButtonHitReturn:(id)sender {
    if (!self.textField.text) {
        self.textField.text = @"";
    }
    
    [self.cell setValue:self.textField.text];
    [self.textField resignFirstResponder];
}

- (void)textFieldDidChange:(UITextField*)sender {
    [self.cell setValue:sender.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return NO;
}

- (UIView*)keyboardDoneButton {
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"DONE"]
                                                                   style:UIBarButtonItemStyleDone target:self
                                                                  action:@selector(barButtonHitReturn:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:flex, doneButton, nil]];
    
    return keyboardDoneButtonView;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = self.textLabel.frame.origin.x;
    CGFloat width = self.bounds.size.width - (padding * 2);
    CGFloat height = 44.0;
    
    self.textLabel.frame = CGRectMake(padding, 0, self.bounds.size.width - (padding * 2), height);
    self.textField.frame = CGRectMake(padding, height, width, height - 12);
}

@end

