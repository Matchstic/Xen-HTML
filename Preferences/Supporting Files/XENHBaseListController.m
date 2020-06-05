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

#import "XENHBaseListController.h"

@interface XENHBaseListController ()

@end

@implementation XENHBaseListController

- (NSString*)plistName {
    return @"";
}

- (id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:[self plistName] target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

// From: https://stackoverflow.com/a/47297734
- (NSString*)_fallbackStringForKey:(NSString*)key {
    NSBundle *mainBundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle"];
    NSString *fallbackBundlePath = [mainBundle pathForResource:@"en" ofType:@"lproj"];
    NSBundle *fallbackBundle = [NSBundle bundleWithPath:fallbackBundlePath];
    NSString *fallbackString = [fallbackBundle localizedStringForKey:key value:key table:[self plistName]];
    
    return fallbackString;
}

- (NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)specifiers {
    for (int i = 0; i < [specifiers count]; i++) {
        
        if ([[specifiers objectAtIndex:i] name]) {
            NSString *correspondingObject = [[specifiers objectAtIndex:i] name];
            NSString *fallbackName = [self _fallbackStringForKey:correspondingObject];
            NSString *localisedName = [[self bundle] localizedStringForKey:correspondingObject value:fallbackName table:[self plistName]];
            
            [[specifiers objectAtIndex:i] setName:localisedName];
        }
        
        if ([[specifiers objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            
            for (NSString *key in [[specifiers objectAtIndex: i] titleDictionary]) {
                NSString *correspondingObject = [[[specifiers objectAtIndex: i] titleDictionary] objectForKey:key];
                NSString *fallbackName = [self _fallbackStringForKey:correspondingObject];
                NSString *localisedName = [[self bundle] localizedStringForKey:correspondingObject value:fallbackName table:[self plistName]];
                
                [newTitles setObject:localisedName forKey:key];
            }
            
            [[specifiers objectAtIndex: i] setTitleDictionary:newTitles];
        }
    }
    
    return specifiers;
}

@end
