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

#import "XENDWidgetConfigurationCell.h"

@interface XENDWidgetConfigurationCell()
@property (nonatomic, strong) id internalValue;
@property (nonatomic, weak) id<XENDWidgetConfigurationDelegate> delegate;
@end

@implementation XENDWidgetConfigurationCell

+ (NSArray<NSString*>*)types {
    return @[
        @"switch",
        @"number",
        @"text",
        @"slider",
        @"option",
        @"page",
        @"color",
        @"link",
        @"unknown"
    ];
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary
                      currentValue:(id)currentValue
                          delegate:(id<XENDWidgetConfigurationDelegate>)delegate {
    if (self) {
        self.delegate = delegate;
        
        _type = [dictionary objectForKey:@"type"];
        _key = [dictionary objectForKey:@"key"];
        _text = [dictionary objectForKey:@"text"];
        _properties = dictionary;
        
        // Figure out the default value, if possible
        if (![self.type isEqualToString:@"page"]) {
            id defaultValue = [dictionary objectForKey:@"default"];
            self.internalValue = currentValue ? currentValue : defaultValue;
        }
    }
    
    return self;
}

- (void)setValue:(id)value {
    self.internalValue = value;
    
    // Notify up the chain for changes
    [self.delegate onUpdateConfiguration:self.key value:self.value];
}

- (id)value {
    return self.internalValue;
}

@end
