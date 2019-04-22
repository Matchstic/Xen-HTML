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

#import "XENHBaseHTMLPreferenceController.h"
#import "XENHPResources.h"
#import "XENHEditorViewController.h"
#import "XENHMultiplexWidgetsController.h"
#import "XENHBasePreviewCell.h"
#import "XENHPreviewSliderCell.h"
#import "XENHLockscreenPreviewCell.h"
#import "XENHHomescreenPreviewCell.h"

#import "XENHSBForegroundController.h"

@interface XENHBaseHTMLPreferenceController ()
@end

@implementation XENHBaseHTMLPreferenceController

#pragma mark Customisation

- (NSString*)titleForController {
    return @"GENERIC";
}

// Same as wallpaper variant really; 0 == LS, 1 == SB
- (int)variant {
    return -1;
}

- (NSArray*)additionalSettingsSpecifiers {
    // This will be overriden in subclasses to provide settings for each section
    return [NSArray array];
}

- (NSString*)preferenceKeyForEnabledState {
    return @"";
}

#pragma mark Init

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return nil;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Title.
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[self titleForController]];
    }
    
    // Enabled switch.
    UISwitch *enabled = [[UISwitch alloc] init];
    [enabled addTarget:self action:@selector(toggleEnabledState:) forControlEvents:UIControlEventValueChanged];
    
    id value = [XENHResources getPreferenceKey:[self preferenceKeyForEnabledState]];
    BOOL on = (value ? [value boolValue] : YES);
    
    [enabled setOn:on];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:enabled];
    self.navigationItem.rightBarButtonItems = @[item];
    
    // Broadcast current enabled state to the preview cell
    [self _notifyPreviewCellOfStateChange:on];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
   // [self _notifyPreviewCellOfDisplay];
}

-(void)toggleEnabledState:(UISwitch*)control {
    [XENHResources setPreferenceKey:[self preferenceKeyForEnabledState] withValue:[NSNumber numberWithBool:control.on]];
    
    [self _notifyPreviewCellOfStateChange:control.on];
}

- (void)_notifyPreviewCellOfStateChange:(BOOL)newstate {
    // Notify the preview cell of an enabled state change.
    [XENHResources setPreviewState:newstate forVariant:[self variant]];
}

- (void)_notifyPreviewCellOfSliderChange:(CGFloat)percent {
    [XENHResources setPreviewSkewPercentage:percent forVariant:[self variant]];
}

- (void)_notifyPreviewCellOfDisplay {
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    if ([cell isKindOfClass:[XENHBasePreviewCell class]]) {
        [(XENHBasePreviewCell*)cell _reloadWallpaper];
    }
}

#pragma mark Preference specifiers

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [[self defaultSpecifiersForCurrentVariant] mutableCopy];
        
        // Add any additional specifiers wanted for this panel
        [testingSpecs addObjectsFromArray:[self additionalSettingsSpecifiers]];
        
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
            
            if ([self _debuggingShouldDisableSpecifier:spec]) {
                [spec setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
            }
        }
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

- (BOOL)_debuggingShouldDisableSpecifier:(PSSpecifier*)specifier {
    NSNumber *debugDisable = [specifier.properties objectForKey:@"debugDisable"];
    
    if (!debugDisable) {
        return NO;
    }
    
    // If our system version is higher than the specifier's disabling threshold for debugging...
    return [UIDevice currentDevice].systemVersion.floatValue >= debugDisable.floatValue;
}

-(NSArray*)defaultSpecifiersForCurrentVariant {
    // Load up the preview group, cell, and slider
    
    // Load "Configure:" items based upon variant.
    // i.e., variant == 0, Background and Foreground
    // == 1, Background only.
    
    NSMutableArray *array = [NSMutableArray array];
    
    PSSpecifier *previewGroup = [PSSpecifier groupSpecifierWithName:[XENHResources localisedStringForKey:@"WIDGETS_PREVIEW_HEADER"]];
    [previewGroup setProperty:[XENHResources localisedStringForKey:@"WIDGETS_PREVIEW_FOOTER"] forKey:@"footerText"];
    [array addObject:previewGroup];
    
    // Add preview cell and slider
    PSSpecifier *previewCell = [PSSpecifier preferenceSpecifierNamed:@"" target:nil set:nil get:nil detail:nil cell:15 edit:nil];
    [previewCell setProperty:([self variant] == 0 ? [XENHLockscreenPreviewCell class] : [XENHHomescreenPreviewCell class]) forKey:@"cellClass"];
    [previewCell setProperty:@"PSDefaultCell" forKey:@"cell"];
    [previewCell setProperty:[NSNumber numberWithInt:280] forKey:@"height"];
    
    [array addObject:previewCell];
    
    PSSpecifier *sliderCell = [PSSpecifier preferenceSpecifierNamed:@"" target:nil set:nil get:nil detail:nil cell:15 edit:nil];
    [sliderCell setProperty:[XENHPreviewSliderCell class] forKey:@"cellClass"];
    [sliderCell setProperty:@"PSDefaultCell" forKey:@"cell"];
    [sliderCell setProperty:[NSNumber numberWithInt:[self variant]] forKey:@"variant"];
    
    [array addObject:sliderCell];
    
    PSSpecifier *configureGroup = [PSSpecifier groupSpecifierWithName:[XENHResources localisedStringForKey:@"WIDGETS_CONFIGURE"]];
    [array addObject:configureGroup];
    
    NSString *bgImagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/BackgroundWidget%@", [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:bgImagePath]) {
        // Oh for crying out loud CoolStar
        bgImagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/BackgroundWidget%@", [XENHResources imageSuffix]];
    }
    
    UIImage *bgIcon = [UIImage imageWithContentsOfFile:bgImagePath];
    
    NSString *fgImagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/ForegroundWidget%@", [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fgImagePath]) {
        // Oh for crying out loud CoolStar
        fgImagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/ForegroundWidget%@", [XENHResources imageSuffix]];
    }
    
    UIImage *fgIcon = [UIImage imageWithContentsOfFile:fgImagePath];
    
    if ([self variant] == 0) {
        // Lockscreen
        
        PSSpecifier* background = [PSSpecifier preferenceSpecifierNamed:[XENHResources localisedStringForKey:@"WIDGETS_BACKGROUND"]
                                                                   target:self
                                                                      set:NULL
                                                                      get:NULL
                                                                   detail:[XENHEditorViewController class]
                                                                     cell:PSLinkListCell
                                                                     edit:Nil];
        
        [background setProperty:bgIcon forKey:@"iconImage"];
        
        [array addObject:background];
        
        PSSpecifier* foreground = [PSSpecifier preferenceSpecifierNamed:[XENHResources localisedStringForKey:@"WIDGETS_FOREGROUND"]
                                                                 target:self
                                                                    set:NULL
                                                                    get:NULL
                                                                 detail:[XENHEditorViewController class]
                                                                   cell:PSLinkListCell
                                                                   edit:Nil];
        
        [foreground setProperty:fgIcon forKey:@"iconImage"];
        
        [array addObject:foreground];
    } else {
        // Homescreen
        
        PSSpecifier* background = [PSSpecifier preferenceSpecifierNamed:[XENHResources localisedStringForKey:@"WIDGETS_BACKGROUND"]
                                                                 target:self
                                                                    set:NULL
                                                                    get:NULL
                                                                 detail:[XENHEditorViewController class]
                                                                   cell:PSLinkListCell
                                                                   edit:Nil];
        
        [background setProperty:bgIcon forKey:@"iconImage"];
        
        // [background setProperty:@"BackgroundWidget.png" forKey:@"icon"];
        
        [array addObject:background];
        
        PSSpecifier* foreground = [PSSpecifier preferenceSpecifierNamed:[XENHResources localisedStringForKey:@"WIDGETS_FOREGROUND"]
                                                                 target:self
                                                                    set:NULL
                                                                    get:NULL
                                                                 detail:[XENHEditorViewController class]
                                                                   cell:PSLinkListCell
                                                                   edit:Nil];
        
        [foreground setProperty:fgIcon forKey:@"iconImage"];
        
        [array addObject:foreground];
    }
    
    return array;
}

// From: https://stackoverflow.com/a/47297734
- (NSString*)_fallbackStringForKey:(NSString*)key {
    NSString *fallbackLanguage = @"en";
    NSString *fallbackBundlePath = [[NSBundle mainBundle] pathForResource:fallbackLanguage ofType:@"lproj"];
    NSBundle *fallbackBundle = [NSBundle bundleWithPath:fallbackBundlePath];
    NSString *fallbackString = [fallbackBundle localizedStringForKey:key value:key table:nil];
    
    return fallbackString;
}

-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[self _fallbackStringForKey:[[s objectAtIndex: i] name]] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[self _fallbackStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key]] table:nil] forKey: key];
            }
            [[s objectAtIndex: i] setTitleDictionary: newTitles];
        }
    }
    
    return s;
}

#pragma mark Overrides for table cell taps

-(void)tableView:(UITableView*)view didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    // Based on the indexPath of the selected cell, make sure to correctly launch the
    // multiplex manager
    
    if (indexPath.section == 1) {
        XENHMultiplexVariant variant = 0;
        
        switch (indexPath.row) {
            case 0:
                // Open background
                variant = [self variant] == 0 ? kMultiplexVariantLockscreenBackground : kMultiplexVariantHomescreenBackground;
                break;
            case 1:
                // Open foreground
                variant = [self variant] == 0 ? kMultiplexVariantLockscreenForeground : kMultiplexVariantHomescreenForeground;
                break;
                
            default:
                break;
        }
        
        [view deselectRowAtIndexPath:indexPath animated:YES];
        
        if (variant == kMultiplexVariantHomescreenForeground) {
            // Handle as appropriate, this is a special case
            
            XENHSBForegroundController *controller = [[XENHSBForegroundController alloc] init];
            [self.navigationController pushViewController:controller animated:YES];
            
        } else {
            // Push to navigational stack.
            XENHMultiplexWidgetsController *multiplexController = [[XENHMultiplexWidgetsController alloc] initWithVariant:variant];
            [self.navigationController pushViewController:multiplexController animated:YES];
            
            // Request to cache the wallpaper
            NSString *cacheWallpaperNotification = @"";
            switch (variant) {
                case kMultiplexVariantLockscreenBackground:
                case kMultiplexVariantLockscreenForeground:
                    cacheWallpaperNotification = @"com.matchstic.xenhtml/cacheLockscreenWallpaper";
                    break;
                case kMultiplexVariantHomescreenBackground:
                    cacheWallpaperNotification = @"com.matchstic.xenhtml/cacheHomescreenWallpaper";
                    break;
                    
                default:
                    break;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:cacheWallpaperNotification object:nil];
        }
        
        return;
    }
    
    [super tableView:view didSelectRowAtIndexPath:indexPath];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [XENHResources setPreferenceKey:specifier.properties[@"key"] withValue:value];
    
    // Also fire off the custom cell notification.
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end
