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

#import "XENHSetupLockscreenImportController.h"
#import "XENHResources.h"
#import "XENHSetupHomescreenImportController.h"

@interface XENHSetupLockscreenImportController ()

@end

@implementation XENHSetupLockscreenImportController

-(NSString*)headerTitle {
    return [XENHResources localisedStringForKey:@"SETUP_LOCKSCREEN_IMPORT_TITLE"];
}

-(NSString*)cellReuseIdentifier {
    return @"setupCell";
}

-(NSInteger)rowsToDisplay {
    NSInteger availableRows = 1;
    
    if ([self hasLockHTML]) availableRows++;
    if ([self hasGroovyLock]) availableRows++;
    
    return availableRows;
}

-(BOOL)hasLockHTML {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.bushe.lockhtml.plist"];
}

-(BOOL)hasGroovyLock {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.groovycarrot.GroovyLock.plist"];
}

-(BOOL)hasCydget {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.saurik.Cydget.plist"];
}

-(UIImage*)footerImage {
    NSString *imagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Setup/Lockscreen%@", [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        // Oh for crying out loud CoolStar
        imagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Setup/Lockscreen%@", [XENHResources imageSuffix]];
    }
    
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENHResources localisedStringForKey:@"SETUP_LOCKSCREEN_IMPORT_FOOTER_TITLE"];
}

-(NSString*)footerBody {
    return [XENHResources localisedStringForKey:@"SETUP_LOCKSCREEN_IMPORT_FOOTER_BODY"];
}

-(NSString*)titleForCellAtIndex:(NSInteger)index {
    // Will remain in this order.
    int shown = 0;
    
    // Handle first row.
    if ([self hasLockHTML] && index == 1) {
        shown = 1;
    } else if ([self hasGroovyLock] && index == 1) {
        shown = 2;
    } else if ([self hasCydget] && index == 1) {
        shown = 3;
    }
    
    // next, handle second row. Displaying either groovyLock or Cydget
    if (![self hasLockHTML] && index == 2) {
        // Index 1 was groovy
        shown = 3;
    } else if ([self hasGroovyLock] && index == 2) {
        // Index 1 was lock
        shown = 2;
    } else if ([self hasCydget] && index == 2) {
        // Has LockHTML, and not groovy.
        shown = 3;
    }
    
    if (index == 3) {
        shown = 3; // If on index 3, definitely have all 3.
    }
    
    switch (shown) {
        case 0:
            return [XENHResources localisedStringForKey:@"SETUP_LOCKSCREEN_IMPORT_NONE"];
            break;
        case 1:
            return [XENHResources localisedStringForKey:@"SETUP_LOCKSCREEN_IMPORT_LOCKHTML"];
            break;
        case 2:
            return [XENHResources localisedStringForKey:@"SETUP_LOCKSCREEN_IMPORT_GROOVYLOCK"];
            break;
    
        default:
            return @"";
            break;
    }
}

-(void)userDidSelectCellAtIndex:(NSInteger)index {
    // Setup as appropriate.
    int shown = 0;
    
    // Handle first row.
    if ([self hasLockHTML] && index == 1) {
        shown = 1;
    } else if ([self hasGroovyLock] && index == 1) {
        shown = 2;
    } else if ([self hasCydget] && index == 1) {
        shown = 3;
    }
    
    // next, handle second row. Displaying either groovyLock or Cydget
    if (![self hasLockHTML] && index == 2) {
        // Index 1 was groovy
        shown = 3;
    } else if ([self hasGroovyLock] && index == 2) {
        // Index 1 was lock
        shown = 2;
    } else if ([self hasCydget] && index == 2) {
        // Has LockHTML, and not groovy.
        shown = 3;
    }
    
    if (index == 3) {
        shown = 3; // If on index 3, definitely have all 3.
    }
    
    switch (shown) {
        case 0:
            // No changes, so set defaults and continue as normal!
            
            [XENHResources setPreferenceKey:@"hideClock" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENHResources setPreferenceKey:@"hideSTU" withValue:[NSNumber numberWithBool:YES] andPost:NO];
            [XENHResources setPreferenceKey:@"sameSizedStatusBar" withValue:[NSNumber numberWithBool:YES] andPost:NO];
            [XENHResources setPreferenceKey:@"hideStatusBar" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENHResources setPreferenceKey:@"hideTopGrabber" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENHResources setPreferenceKey:@"hideBottomGrabber" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENHResources setPreferenceKey:@"hideCameraGrabber" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENHResources setPreferenceKey:@"disableCameraGrabber" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            
            [XENHResources setPreferenceKey:@"widgets" withValue:@{} andPost:YES];
            
            break;
            
        case 1: {
            // LockHTML
            NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.bushe.lockhtml.plist"];
            
            NSString *widgetPosition = [settings objectForKey:@"widgetPosition"] ? [settings objectForKey:@"widgetPosition"] : @"above";
            NSArray *selected = [settings objectForKey:@"ThemesSelected"] ? [settings objectForKey:@"ThemesSelected"] : @[];
            BOOL hideTopGrabber = [settings objectForKey:@"hideTopGrabber"] ? [[settings objectForKey:@"hideTopGrabber"] boolValue] : NO;
            BOOL hideLSLabel = [settings objectForKey:@"hideLSLabel"] ? [[settings objectForKey:@"hideLSLabel"] boolValue] : NO;
            BOOL hideBottomGrabber = [settings objectForKey:@"hideBottomGrabber"] ? [[settings objectForKey:@"hideBottomGrabber"] boolValue] : NO;
            
            // Camera
            BOOL grabberHide = [settings objectForKey:@"grabberHide"] ? [[settings objectForKey:@"grabberHide"] boolValue] : NO;
            BOOL grabberDisabled = [settings objectForKey:@"grabberDisabled"] ? [[settings objectForKey:@"grabberDisabled"] boolValue] : NO;
            
            BOOL clockHide = [settings objectForKey:@"hideTop"] ? [[settings objectForKey:@"hideTop"] boolValue] : NO;
            
            // XXX: Now, we port to XenHTML.
            [XENHResources setPreferenceKey:@"hideClock" withValue:[NSNumber numberWithBool:clockHide] andPost:NO];
            [XENHResources setPreferenceKey:@"hideSTU" withValue:[NSNumber numberWithBool:hideLSLabel] andPost:NO];
            [XENHResources setPreferenceKey:@"hideTopGrabber" withValue:[NSNumber numberWithBool:hideTopGrabber] andPost:NO];
            [XENHResources setPreferenceKey:@"hideBottomGrabber" withValue:[NSNumber numberWithBool:hideBottomGrabber] andPost:NO];
            [XENHResources setPreferenceKey:@"hideCameraGrabber" withValue:[NSNumber numberWithBool:grabberHide] andPost:NO];
            [XENHResources setPreferenceKey:@"disableCameraGrabber" withValue:[NSNumber numberWithBool:grabberDisabled] andPost:NO];
            
            NSDictionary *widgetCoordinates = [settings objectForKey:@"WidgetCoordinates"];
            NSMutableArray *widgetArray = [NSMutableArray array];
            NSMutableDictionary *widgetMetadata = [NSMutableDictionary dictionary];
            
            for (NSDictionary *theme in selected) {
                NSString *name = [theme objectForKey:@"name"];
                NSString *path = [theme objectForKey:@"path"];
                NSString *html = [theme objectForKey:@"html"];
                
                NSString *widgetURL = [NSString stringWithFormat:@"%@/%@", path, html];
                [widgetArray addObject:widgetURL];
                
                // Next, pull metadata for this one.
                NSMutableDictionary *metadata = [[XENHResources rawMetadataForHTMLFile:path] mutableCopy];
                NSDictionary *dict = [widgetCoordinates objectForKey:name];
                
                id widgetX = [dict objectForKey:@"widgetX"];
                id widgetY = [dict objectForKey:@"widgetY"];
                
                CGFloat x = 0;
                CGFloat y = 0;
                
                if (widgetX) {
                    x = [widgetX floatValue];
                    x /= SCREEN_WIDTH;
                }
                
                if (widgetY) {
                    y = [widgetY floatValue];
                    y /= SCREEN_HEIGHT;
                }
                
                [metadata setValue:[NSNumber numberWithFloat:x] forKey:@"x"];
                [metadata setValue:[NSNumber numberWithFloat:y] forKey:@"y"];
                
                [widgetMetadata setObject:metadata forKey:widgetURL];
            }
            
            NSString *key = [widgetPosition isEqualToString:@"above"] ? @"LSForeground" : @"LSBackground";
            
            NSMutableDictionary *existingWidgets = [XENHResources getPreferenceKey:@"widgets"];
            [existingWidgets setObject:@{ @"widgetArray": widgetArray, @"widgetMetadata": widgetMetadata } forKey:key];
            [XENHResources setPreferenceKey:@"widgets" withValue:existingWidgets andPost:YES];
            
            // Done.
            
            break;
        } case 2: {
            // GroovyLock
            NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.groovycarrot.GroovyLock.plist"];
            
            NSString *activeTheme = [settings objectForKey:@"ActiveTheme"] ? [settings objectForKey:@"ActiveTheme"] : @"";
            BOOL backgroundPosition = [settings objectForKey:@"Background"] ? [[settings objectForKey:@"Background"] boolValue] : NO;
            BOOL hideClock = [settings objectForKey:@"HideClock"] ? [[settings objectForKey:@"HideClock"] boolValue] : NO;
            
            // Sort out activeTheme
            if (![activeTheme isEqualToString:@""]) {
                activeTheme = [NSString stringWithFormat:@"/var/mobile/GroovyLock/%@/LockBackground.html", activeTheme];
            }
            
            // XXX: Now, we port to XenHTML.
            // Prefs
            [XENHResources setPreferenceKey:@"hideClock" withValue:[NSNumber numberWithBool:hideClock] andPost:NO];
            
            // Widget data
            NSString *key = !backgroundPosition ? @"LSForeground" : @"LSBackground";
            
            NSArray *widgetArray = @[ activeTheme ];
            NSDictionary *widgetMetadata = @{ activeTheme: [XENHResources rawMetadataForHTMLFile:activeTheme] };
            
            NSMutableDictionary *existingWidgets = [XENHResources getPreferenceKey:@"widgets"];
            [existingWidgets setObject:@{ @"widgetArray": widgetArray, @"widgetMetadata": widgetMetadata } forKey:key];
            [XENHResources setPreferenceKey:@"widgets" withValue:existingWidgets andPost:YES];
            
            // Job done!
            
            break;
        }
        default:
            break;
    }
    
    [XENHResources reloadSettings];
}

// This will either be the user selected cell, or whatever is currently checkmarked.
-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    XENHSetupHomescreenImportController *nextController = [[XENHSetupHomescreenImportController alloc] initWithStyle:UITableViewStyleGrouped];
    
    return nextController;
}

-(BOOL)shouldSegueToNewControllerAfterSelectingCell {
    return YES;
}

@end
