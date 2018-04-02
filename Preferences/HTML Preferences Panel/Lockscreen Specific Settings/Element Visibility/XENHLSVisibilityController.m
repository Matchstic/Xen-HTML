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

#import "XENHLSVisibilityController.h"
#import "XENHResources.h"

@interface XENHLSVisibilityController ()

@end

@implementation XENHLSVisibilityController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"LSOtherVisibility" target:self];
        
        // Iterate over the specifiers. If marked as not working on this version of iOS, remove from specs.
        for (PSSpecifier *spec in [testingSpecs copy]) {
            NSNumber *minVer = [spec.properties objectForKey:@"minVer"];
            NSNumber *maxVer = [spec.properties objectForKey:@"maxVer"];
            NSNumber *d22 = [spec.properties objectForKey:@"d22"];
            
            if (minVer) {
                if ([UIDevice currentDevice].systemVersion.floatValue < minVer.floatValue) {
                    [testingSpecs removeObject:spec];
                }
            }
            
            if (maxVer) {
                // Only check max if present.
                if ([UIDevice currentDevice].systemVersion.floatValue > maxVer.floatValue) {
                    [testingSpecs removeObject:spec];
                }
            }
            
            if (d22) {
                // Check if the current device is d22 (i.e., an iPhone X etc)
                // Remove if *d22 == false && current-device-is-d22
                // Remove if *d22 == true && !current-device-is-d22
                
                BOOL isCurrentDeviceD22 = [XENHResources isCurrentDeviceD22];
                
                if (([d22 boolValue] == NO && isCurrentDeviceD22) ||
                    ([d22 boolValue] == YES && !isCurrentDeviceD22)) {
                    
                    [testingSpecs removeObject:spec];
                }
            }
        }
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[[s objectAtIndex: i] name] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] table:nil] forKey: key];
            }
            [[s objectAtIndex: i] setTitleDictionary: newTitles];
        }
    }
    
    return s;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [XENHResources setPreferenceKey:specifier.properties[@"key"] withValue:value];
    
    // Also fire off the custom cell notification.
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end
