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

#import <Foundation/Foundation.h>
#import "../XENDWidgetConfigurationDelegate.h"

/**
 Represents a configuration cell in a page
 */
@interface XENDWidgetConfigurationCell : NSObject

/**
 Type of the cell
 
 Oneof +types
 */
@property (nonatomic, strong, readonly) NSString *type;

/**
 Preference key for the cell
 */
@property (nonatomic, strong, readonly) NSString *key;

/**
 Text for the cell
 */
@property (nonatomic, strong, readonly) NSString *text;

/**
 Any properties associated with the cell
 */
@property (nonatomic, strong, readonly) NSDictionary *properties;

/**
 All possible cell types, excluding control cells like 'title', 'comment' and 'gap'
 */
+ (NSArray<NSString*>*)types;

/**
 Initialises the cell model with a dictionary
 */
- (instancetype)initWithDictionary:(NSDictionary*)dictionary
                      currentValue:(id)value
                          delegate:(id<XENDWidgetConfigurationDelegate>)delegate;

/**
 Setter for the current state of the cell
 */
- (void)setValue:(id)value;

/**
 Getter for the current state of the cell
 */
- (id)value;

@end
