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
#import "XENDWidgetConfigurationGroup.h"
#import "../XENDWidgetConfigurationDelegate.h"

/**
 Models a page of widget configuration
 
 Available cell types:
 - title
 - comment
 - gap
 
 Expected page layout is an array of objects
 */
@interface XENDWidgetConfigurationPage : NSObject

@property (nonatomic, strong, readonly) NSArray<XENDWidgetConfigurationGroup*> *groups;

/**
 Initialises with a representation of a configuration page, and the current values set for it
 */
- (instancetype)initWithOptions:(NSArray*)options
                       delegate:(id<XENDWidgetConfigurationDelegate>)delegate;

@end
