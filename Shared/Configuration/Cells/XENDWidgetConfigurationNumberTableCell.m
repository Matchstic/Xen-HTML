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

#import "XENDWidgetConfigurationNumberTableCell.h"
#import "XENHResources.h"

@interface XENDWidgetConfigurationNumberTableCell ()
@property (nonatomic, strong) UITextField *textField;
@end

@implementation XENDWidgetConfigurationNumberTableCell

- (void)setup {
    if (!self.textField) {
        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        self.textField.delegate = self;
        self.textField.textAlignment = NSTextAlignmentRight;
        
        if (@available(iOS 13.0, *)) {
            self.textField.textColor = [UIColor labelColor];
            self.textField.backgroundColor = [UIColor tertiarySystemGroupedBackgroundColor];
        } else {
            self.textField.textColor = [UIColor darkTextColor];
            self.textField.backgroundColor = [UIColor colorWithWhite:(229.0 / 255.0) alpha:1.0];
        }
        
        self.textField.layer.cornerRadius = 5;
    
        if (@available(iOS 13.0, *)) {
            self.textField.font = [UIFont monospacedSystemFontOfSize:18 weight:UIFontWeightRegular];
        } else {
            // Fallback on earlier versions
        }
        self.textField.returnKeyType = UIReturnKeyDone;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeDecimalPad;
        self.textField.inputAccessoryView = [self keyboardDoneButton];
        
        self.accessoryView = self.textField;
    }
    
    NSNumber *currentValue = self.cell.value;
    if (currentValue) {
        self.textField.text = currentValue ? [NSString stringWithFormat:@"%@", currentValue] : @"0";
    }
}

- (void)barButtonHitReturn:(id)sender {
    if (!self.textField.text) {
        self.textField.text = @"0";
    }
    
    [self.cell setValue:[self toNumber]];
    [self.textField resignFirstResponder];
}

- (NSNumber*)toNumber {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *number = [formatter numberFromString:self.textField.text];
    if (!number) {
        number = @0;
    }
    
    return number;
}

- (void)textFieldDidChange:(UITextField*)sender {
    [self.cell setValue:[self toNumber]];
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
    CGFloat width = 51; // Equivalent to UISwitch
    self.accessoryView.frame = CGRectMake(self.bounds.size.width - width - padding, 6, width, self.bounds.size.height - 12);
}

@end
