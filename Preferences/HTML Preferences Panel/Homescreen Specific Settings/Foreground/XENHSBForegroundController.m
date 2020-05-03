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

#import "XENHSBForegroundController.h"
#import "XENHPResources.h"

@interface XENHSBForegroundController ()

@end

@implementation XENHSBForegroundController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.headerView = [[XENHMultiplexWidgetsHeaderView alloc] initWithVariant:kMultiplexVariantHomescreenForeground];
    }
    
    return self;
}

- (NSString*)plistName {
    return @"SBForeground";
}

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"SBForeground" target:self];
        
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
            
            // Override the enabled state for perPageModeIsEnabled if needed
            if ([[spec.properties objectForKey:@"key"] isEqualToString:@"SBOnePageWidgetMode"] &&
                [self perPageModeIsEnabled]) {
                [spec.properties setObject:@0 forKey:@"enabled"];
            }
        }
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [XENHResources setPreferenceKey:specifier.properties[@"key"] withValue:value];
    
    if ([specifier.properties[@"key"] isEqualToString:@"SBPerPageHTMLWidgetMode"])
        [self updateEnabledStateForOPWModeToggle];
    
    // Also fire off the custom cell notification.
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

- (int)tableViewStyle {
    return UITableViewStyleGrouped;
}

-(CGFloat)tableView:(UITableView*)arg1 heightForHeaderInSection:(NSInteger)arg2 {
    if (arg2 == 0) {
        CGFloat tableViewWidth = self.table.frame.size.width;
        CGFloat iconMargin = 20;
        CGFloat iconHeight = 40;
        CGFloat labelMargin = 10;
        UIFont *labelFont = [UIFont systemFontOfSize:16];
        
        NSString *labelText = [XENHResources localisedStringForKey:@"WIDGETS_SBFOREGROUND_DETAIL"];
        
        CGRect labelRect = [XENHResources boundedRectForFont:labelFont andText:labelText width:tableViewWidth - (labelMargin * 2.0)];
        
        return iconMargin + iconHeight + labelMargin + labelRect.size.height + iconMargin;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (id)tableView:(UITableView*)arg1 detailTextForHeaderInSection:(int)arg2 {
    return nil;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (id)tableView:(UITableView*)arg1 viewForHeaderInSection:(NSInteger)arg2 {
    if (arg2 == 0) {
        return self.headerView;
    } else {
        return nil;
    }
}

- (BOOL)perPageModeIsEnabled {
    id value = [XENHResources getPreferenceKey:@"SBPerPageHTMLWidgetMode"];
    return value != nil ? [value boolValue] : NO;
}

- (void)updateEnabledStateForOPWModeToggle {
    NSLog(@"Xen HTML :: Updating enabled state");
    
    PSSpecifier *spec;
    for (PSSpecifier *_specifier in _specifiers) {
        if ([[_specifier.properties objectForKey:@"key"] isEqualToString:@"SBOnePageWidgetMode"]) {
            spec = _specifier;
            break;
        }
    }
    
    [spec.properties setObject:[self perPageModeIsEnabled] ? @0 : @1 forKey:@"enabled"];
    
    // Reload this specifier
    [self reloadSpecifier:spec];
}

@end
