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

#import "XENDWidgetConfigurationGroup.h"

@implementation XENDWidgetConfigurationGroup

- (instancetype)initWithArray:(NSArray<NSDictionary*>*)items
                     delegate:(id<XENDWidgetConfigurationDelegate>)delegate {
    self = [super init];
    
    if (self) {
        // Setup title and footer of the group
        _title = [self findText:@"title" inItems:items];
        _footer = [self findText:@"comment" inItems:items];
        
        // Configure cells
        _cells = [self configureCells:items delegate:delegate];
    }
    
    return self;
}

- (NSString*)findText:(NSString*)key inItems:(NSArray<NSDictionary*>*)items {
    NSString *title = @"";
    
    for (NSDictionary *item in items) {
        if ([[item objectForKey:@"type"] isEqualToString:key]) {
            title = [item objectForKey:@"text"];
            break;
        }
    }
    
    return title;
}

- (NSArray<XENDWidgetConfigurationCell*>*)configureCells:(NSArray<NSDictionary*>*)items
                                                delegate:(id<XENDWidgetConfigurationDelegate>)delegate {
    NSMutableArray *cells = [NSMutableArray array];
    
    for (NSDictionary *dictionaryCell in items) {
        // Filter out unknown cell types
        NSString *type = [dictionaryCell objectForKey:@"type"];
        if ([type isEqualToString:@"title"] ||
            [type isEqualToString:@"comment"])
            continue;
        
        BOOL unknown = NO;
        if (!type) unknown = YES;
        if (![[XENDWidgetConfigurationCell types] containsObject:type]) unknown = YES;
        
        if (unknown) {
            XENDWidgetConfigurationCell *unknownCell = [[XENDWidgetConfigurationCell alloc] initWithDictionary:@{
                @"type": @"unknown",
                @"text": @"Unknown Cell Type"
            } currentValue:nil delegate:nil];
            [cells addObject:unknownCell];
            
            continue;
        }
        
        // Continue creating cell for this known type
        NSString *key = [dictionaryCell objectForKey:@"key"];
        id currentValue = nil;
        
        if (key) {
            NSDictionary *currentValues = [delegate currentValues];
            currentValue = [currentValues objectForKey:key];
        }
        
        XENDWidgetConfigurationCell *cell = [[XENDWidgetConfigurationCell alloc] initWithDictionary:dictionaryCell
                                                                                       currentValue:currentValue
                                                                                           delegate:delegate];
        [cells addObject:cell];
    }
    
    return cells;
}

@end
