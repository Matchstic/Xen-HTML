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

#import "XENDWidgetConfigurationPage.h"

@implementation XENDWidgetConfigurationPage

- (instancetype)initWithOptions:(NSArray*)options
                       delegate:(id<XENDWidgetConfigurationDelegate>)delegate {
    self = [super init];
    
    if (self) {
        // Config
        _groups = [self parseGroups:options delegate:delegate];
    }
    
    return self;
}

- (NSArray<XENDWidgetConfigurationGroup*>*)parseGroups:(NSArray*)options
                                              delegate:(id<XENDWidgetConfigurationDelegate>)delegate {
    if (!options || options.count == 0) return @[];
    
    // Iterate over items, and split into groups of cells
    // Split reasons:
    // - First item in array
    // - Item is a title (split before, if > 0 groups)
    // - Item is a comment (split after)
    // - Item is a gap (split anywhere)
    
    NSMutableArray *groups = [NSMutableArray array];
    
    NSMutableArray *currentGroup = [NSMutableArray array];
    for (NSDictionary *cell in options) {
        NSString *type = [cell objectForKey:@"type"];
        if (!type) continue;
        
        if ([type isEqualToString:@"title"]) {
            if (currentGroup.count > 0) {
                [groups addObject:currentGroup];
                currentGroup = [NSMutableArray array];
            }
            
            [currentGroup addObject:cell];
            
        } else if ([type isEqualToString:@"comment"]) {
            
            [currentGroup addObject:cell];
            [groups addObject:currentGroup];
            
            currentGroup = [NSMutableArray array];
            
        } else if ([type isEqualToString:@"gap"]) {
            // Disallow multiple gaps following each other
            // This also ignores 'gap' after a comment
            if (currentGroup.count > 0) {
                [groups addObject:currentGroup];
                currentGroup = [NSMutableArray array];
            }
        } else {
            
            [currentGroup addObject:cell];
            
        }
    }
    
    // Add trailing group
    [groups addObject:currentGroup];
    
    // Convert arrays of dictionaries into groups
    NSMutableArray *modelGroups = [NSMutableArray array];
    for (NSArray *arrayGroup in groups) {
        XENDWidgetConfigurationGroup *modelGroup = [[XENDWidgetConfigurationGroup alloc] initWithArray:arrayGroup
                 delegate:delegate];
        
        [modelGroups addObject:modelGroup];
    }
    
    return modelGroups;
}

@end
