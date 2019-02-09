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

#import "XENHConfigJSCell.h"
#import "XENHPResources.h"

@implementation XENHConfigJSCell

-(void)_configureViewsIfNeeded {
    if (!self.switchControl) {
        self.switchControl = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self.switchControl addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
    }
    
    if (!self.textField) {
        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        self.textField.delegate = self;
        self.textField.textAlignment = NSTextAlignmentRight;
        self.textField.textColor = [UIColor grayColor];
        self.textField.returnKeyType = UIReturnKeyDone;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        [self.contentView addSubview:self.textField];
    }
    
    if (!self.commentLabel) {
        self.commentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.commentLabel.textAlignment = NSTextAlignmentNatural;
        self.commentLabel.textColor = [UIColor lightGrayColor];
        self.commentLabel.font = [UIFont systemFontOfSize:15];
        self.commentLabel.numberOfLines = 0;
        
        [self.contentView addSubview:self.commentLabel];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:NO animated:NO];
    
    if (!self.textField.hidden && selected) {
        [self.textField becomeFirstResponder];
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, self.textLabel.frame.size.width, 44.0);
    
    // TODO: Layout custom views.
    CGRect rect = [XENHResources boundedRectForFont:self.commentLabel.font andText:self.commentLabel.text width:self.frame.size.width - 30];
    
    self.commentLabel.frame = CGRectMake(15, self.textLabel.frame.size.height, self.frame.size.width-30, rect.size.height);
    
    if (![[_datum objectForKey:@"isBool"] boolValue]) {
        // We have the text field.
        CGFloat maxWidth = self.bounds.size.width * 0.75;
        
        // Also, need to ensure the text label ins't being weird.
        CGFloat height = self.textLabel.frame.size.height;
        [self.textLabel sizeToFit];
        
        self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, 0, self.textLabel.frame.size.width, height);
        
        if (self.textLabel.frame.size.width > maxWidth) {
            self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, maxWidth, self.textLabel.frame.size.height);
        }
        
        CGFloat x = self.textLabel.frame.size.width + self.textLabel.frame.origin.x;
        CGFloat width = self.frame.size.width - x - (self.textLabel.frame.origin.x*2);
        
        self.textField.frame = CGRectMake(x + self.textLabel.frame.origin.x, 0, width, self.textLabel.frame.size.height);
    } else {
        // Handle accessory view framing.
        CGFloat y = (44.0 - self.accessoryView.frame.size.height)/2;
        self.accessoryView.frame = CGRectMake(self.accessoryView.frame.origin.x, y, self.accessoryView.frame.size.width, self.accessoryView.frame.size.height);
    }
}

-(void)switchDidChange:(UISwitch*)sender {
    // Let the delegate know the switch changed, with the key too.
    [self.delegate switchDidChange:[NSNumber numberWithBool:sender.isOn] withKey:[_datum objectForKey:@"key"]];
}

-(void)barButtonHitReturn:(id)sender {
    if (!self.textField.text || [self.textField.text isEqualToString:@""]) {
        // Only going here if number.
        self.textField.text = @"0";
    }
    
    [self.delegate textFieldDidChange:self.textField.text withKey:[_datum objectForKey:@"key"]];
    [self.textField resignFirstResponder];
}

-(void)textFieldDidChange:(UITextField*)sender {
    // Let delegate know we've changed.
    [self.delegate textFieldDidChange:sender.text withKey:[_datum objectForKey:@"key"]];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return NO;
}

-(UIView*)keyboardDoneButton {
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"DONE"]
                                                                   style:UIBarButtonItemStyleDone target:self
                                                                  action:@selector(barButtonHitReturn:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:flex, doneButton, nil]];
    return keyboardDoneButtonView;
}

-(void)setupWithDatum:(NSDictionary*)datum {
    [self _configureViewsIfNeeded];
    
    _datum = datum;
    
    self.textLabel.text = [datum objectForKey:@"key"];
    
    if ([[datum objectForKey:@"isBool"] boolValue]) {
        // Show switch, hide text field.
        self.accessoryView = self.switchControl;
        [self.switchControl setOn:[[datum objectForKey:@"value"] boolValue]];
        
        // Default value is a bool.
        self.textField.hidden = YES;
    } else {
        // Show text field, switch hidden.
        self.accessoryView = nil;
        
        // Default value can be anything, check isNumber.
        self.textField.hidden = NO;
        
        if ([[datum objectForKey:@"isNumber"] boolValue]) {
            self.textField.text = [NSString stringWithFormat:@"%@", [datum objectForKey:@"value"]];
            self.textField.keyboardType = UIKeyboardTypeDecimalPad;
            
            // Needs the "done" button accessory view.
            self.textField.inputAccessoryView = [self keyboardDoneButton];
        } else {
            self.textField.text = [datum objectForKey:@"value"];
            self.textField.keyboardType = UIKeyboardTypeDefault;
            
            self.textField.inputAccessoryView = nil;
        }
    }
    
    self.commentLabel.text = [datum objectForKey:@"comment"];
}

@end
