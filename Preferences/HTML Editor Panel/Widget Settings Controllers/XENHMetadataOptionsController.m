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

#import "XENHMetadataOptionsController.h"
#import "XENHPResources.h"

@interface XENHMetadataOptionsController ()

@end

@implementation XENHMetadataOptionsController

-(instancetype)initWithOptions:(NSDictionary*)options fallbackState:(BOOL)state andPlist:(NSArray*)plist {
    self = [super initForContentSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT)];
    
    if (self) {
        _options = [options mutableCopy];
        _plist = plist;
        
        self.fallbackState = state;
    }
    
    return self;
}

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [NSMutableArray array];
        
        // Build specifiers from _plist.
        
        /*
         * Format:
         * name
         * type - switch, edit, select
         * label
         * default
         * options (select only)
         */
        
        NSOperatingSystemVersion version;
        version.majorVersion = 10.0;
        version.minorVersion = 0;
        version.patchVersion = 0;
        
        BOOL allowLegacyMode = ![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
        
        if (allowLegacyMode) {
            // Legacy mode toggle first
            PSSpecifier *legacyGroup = [PSSpecifier groupSpecifierWithName:@""];
            NSString *fallbackFooter = [XENHResources localisedStringForKey:@"WIDGET_SETTINGS_LEGACY_FOOTER"];
            [legacyGroup setProperty:fallbackFooter forKey:@"footerText"];
            [testingSpecs addObject:legacyGroup];
            
            PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:[XENHResources localisedStringForKey:@"WIDGET_SETTINGS_LEGACY_MODE"]
                                                                    target:self
                                                                       set:@selector(setPreferenceValue:specifier:)
                                                                       get:@selector(readPreferenceValue:)
                                                                    detail:nil
                                                                      cell:PSSwitchCell
                                                                      edit:nil];
            [specifier setProperty:@YES forKey:@"enabled"];
            [specifier setProperty:[NSNumber numberWithBool:self.fallbackState] forKey:@"default"];
            [specifier setProperty:@"_xh_fallback" forKey:@"key"];
            
            [testingSpecs addObject:specifier];
        }

        PSSpecifier *mainGroup = [PSSpecifier groupSpecifierWithName:@""];
        [testingSpecs addObject:mainGroup];
        
        for (NSDictionary *item in _plist) {
            NSString *type = [item objectForKey:@"type"];
            NSString *key = [item objectForKey:@"name"];
            NSString *label = [item objectForKey:@"label"];
            id defaultValue = [item objectForKey:@"default"];
            
            // Hold up. We might be seeing some weird usage of the iWidget UI on the part of the modder.
            if (!key || [key isEqualToString:@""]) {
                // Well, okay then.
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:defaultValue
                                                                        target:self
                                                                           set:nil
                                                                           get:nil
                                                                        detail:nil
                                                                          cell:PSStaticTextCell
                                                                          edit:nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                
                [testingSpecs addObject:specifier];
                
                continue;
            }
            
            // Handle from type.
            if ([type isEqualToString:@"switch"]) {
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:label
                                                                        target:self
                                                                           set:@selector(setPreferenceValue:specifier:)
                                                                           get:@selector(readPreferenceValue:)
                                                                        detail:nil
                                                                          cell:PSSwitchCell
                                                                          edit:nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                [specifier setProperty:defaultValue forKey:@"default"];
                [specifier setProperty:key forKey:@"key"];
                
                [testingSpecs addObject:specifier];
            } else if ([type isEqualToString:@"select"]) {
                // Link cell to a selector UI.
                
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:label
                                                                        target:self
                                                                           set:@selector(setPreferenceValue:specifier:)
                                                                           get:@selector(readPreferenceValue:)
                                                                        detail:NSClassFromString(@"PSListItemsController")
                                                                          cell:PSLinkListCell
                                                                          edit:Nil];
                
                [specifier setProperty:@YES forKey:@"enabled"];
                [specifier setProperty:defaultValue forKey:@"default"];
                
                NSMutableArray *values = [NSMutableArray array];
                NSMutableArray *titles = [NSMutableArray array];
                
                NSDictionary *options = [item objectForKey:@"options"];
                NSArray *allKeys = [self sortedKeysForDictionary:options];
                
                for (NSString *key in allKeys) {
                    [titles addObject:key];
                    [values addObject:[options objectForKey:key]];
                }
                
                specifier.values = values;
                specifier.titleDictionary = [NSDictionary dictionaryWithObjects:titles forKeys:specifier.values];
                specifier.shortTitleDictionary = [NSDictionary dictionaryWithObjects:titles forKeys:specifier.values];
                [specifier setProperty:key forKey:@"key"];
                
                [testingSpecs addObject:specifier];
            } else {
                // Just an edit cell, because why not!
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:label
                                                                        target:self
                                                                           set:@selector(setPreferenceValue:specifier:)
                                                                           get:@selector(readPreferenceValue:)
                                                                        detail:nil
                                                                          cell:PSEditTextCell
                                                                          edit:nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                [specifier setProperty:@YES forKey:@"noAutoCorrect"];
                [specifier setProperty:defaultValue forKey:@"default"];
                [specifier setProperty:@0 forKey:@"alignment"];
                [specifier setProperty:key forKey:@"key"];
                
                [testingSpecs addObject:specifier];
            }
        }
        
        _specifiers = testingSpecs;
    }
    
    return _specifiers;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // If this cell has a text edit UI, force right hand alignment.
    for (UIView *view in cell.contentView.subviews) {
        if ([[view class] isSubclassOfClass:[UITextField class]]) {
            UITextField *txt = (UITextField*)view;
            
            // Set right alignment.
            txt.textAlignment = NSTextAlignmentRight;
            
            break;
        }
    }
    
    return cell;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *key = specifier.properties[@"key"];
    
    // Handle fallback
    if ([key isEqualToString:@"_xh_fallback"]) {
        self.fallbackState = [value boolValue];
        [self.fallbackDelegate fallbackStateDidChange:[value boolValue]];
        return;
    }
    
    // Save new setting.
    [_options setObject:value forKey:key];
}

-(id)readPreferenceValue:(PSSpecifier*)spec {
    NSString *key = spec.properties[@"key"];
    
    // Handle fallback
    if ([key isEqualToString:@"_xh_fallback"]) {
        return [NSNumber numberWithBool:self.fallbackState];
    }
    
    id value = [_options objectForKey:key];
    
    if (!value) {
        for (NSDictionary *item in _plist) {
            if ([[item objectForKey:@"name"] isEqualToString:spec.properties[@"key"]]) {
                value = [item objectForKey:@"default"];
                break;
            }
        }
    }
        
    return value;
}

-(void)viewWillAppear:(BOOL)view {
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[XENHResources localisedStringForKey:@"WIDGET_SETTINGS_TITLE"]];
    }
    [super viewWillAppear:view];
}

-(NSDictionary*)currentOptions {
    return _options;
}

- (NSArray *)sortedKeysForDictionary:(NSDictionary *)dict {
    NSArray *keys = [dict allKeys];
    NSMutableArray *anArray = [NSMutableArray arrayWithArray:keys];
    keys = [anArray sortedArrayUsingSelector:@selector(localizedCompare:)];
    return keys;
}

@end
