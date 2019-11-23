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

#import "XENHSetupHomescreenImportController.h"
#import "XENHResources.h"
#import "XENSetupFinalController.h"

@interface XENHSetupHomescreenImportController ()

@end

@implementation XENHSetupHomescreenImportController

-(NSString*)headerTitle {
    return [XENHResources localisedStringForKey:@"SETUP_HOMESCREEN_IMPORT_TITLE"];
}

-(NSString*)cellReuseIdentifier {
    return @"setupCell";
}

-(NSInteger)rowsToDisplay {
    NSInteger availableRows = 1;
    
    if ([self hasSBHTML]) availableRows++;
    
    return availableRows;
}

-(BOOL)hasSBHTML {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.groovycarrot.SBHTML.plist"];
}

-(UIImage*)footerImage {
    NSString *imagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Setup/Homescreen%@", [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        // Oh for crying out loud CoolStar
        imagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Setup/Homescreen%@", [XENHResources imageSuffix]];
    }
    
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENHResources localisedStringForKey:@"SETUP_HOMESCREEN_IMPORT_FOOTER_TITLE"];
}

-(NSString*)footerBody {
    return [XENHResources localisedStringForKey:@"SETUP_HOMESCREEN_IMPORT_FOOTER_BODY"];
}

-(NSString*)titleForCellAtIndex:(NSInteger)index {
    // Will remain in this order.
    int shown = 0;
    
    // Handle first row.
    if ([self hasSBHTML] && index == 1) {
        shown = 1;
    }
    
    switch (shown) {
        case 0:
            return [XENHResources localisedStringForKey:@"SETUP_HOMESCREEN_IMPORT_NONE"];
            break;
        case 1:
            return [XENHResources localisedStringForKey:@"SETUP_HOMESCREEN_IMPORT_SBHTML"];
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
    if ([self hasSBHTML] && index == 1) {
        shown = 1;
    }
    
    switch (shown) {
        case 0: {
            // No changes, so continue as normal!
            
            [XENHResources setPreferenceKey:@"SBHideDockBlur" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENHResources setPreferenceKey:@"SBAllowTouch" withValue:[NSNumber numberWithBool:YES] andPost:NO];
            
            NSMutableDictionary *existingWidgets = [[XENHResources getPreferenceKey:@"widgets"] mutableCopy];
            if (!existingWidgets)
                existingWidgets = [NSMutableDictionary dictionary];
            
            [existingWidgets setObject:@{} forKey:@"SBLocation"];
            [XENHResources setPreferenceKey:@"widgets" withValue:existingWidgets andPost:YES];
            
            break;
        }
        case 1: {
            // SBHTML
            NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.groovycarrot.SBHTML.plist"];
            
            NSString *activeTheme = [settings objectForKey:@"ActiveTheme"] ? [settings objectForKey:@"ActiveTheme"] : @"";
            BOOL dockhidden = [settings objectForKey:@"RemoveBlurredDock"] ? [[settings objectForKey:@"RemoveBlurredDock"] boolValue] : NO;
            
            // Sort out activeTheme
            if (![activeTheme isEqualToString:@""]) {
                activeTheme = [NSString stringWithFormat:@"/var/mobile/SBHTML/%@/Wallpaper.html", activeTheme];
            }
            
            // XXX: Now, we port to XenHTML.
            [XENHResources setPreferenceKey:@"SBHideDockBlur" withValue:[NSNumber numberWithBool:dockhidden] andPost:NO];
            [XENHResources setPreferenceKey:@"SBLocation" withValue:activeTheme andPost:NO];
            
            // Widget data
            NSString *key = @"SBBackground";
            
            NSArray *widgetArray = @[ activeTheme ];
            NSDictionary *widgetMetadata = @{ activeTheme: [XENHResources rawMetadataForHTMLFile:activeTheme] };
            
            NSMutableDictionary *existingWidgets = [XENHResources getPreferenceKey:@"widgets"];
            [existingWidgets setObject:@{ @"widgetArray": widgetArray, @"widgetMetadata": widgetMetadata } forKey:key];
            [XENHResources setPreferenceKey:@"widgets" withValue:existingWidgets andPost:YES];
            
            break;
        }
        default:
            break;
    }
    
    [XENHResources reloadSettings];
}

// This will either be the user selected cell, or whatever is currently checkmarked.
-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    return [[XENHSetupFinalController alloc] init];
}

-(BOOL)shouldSegueToNewControllerAfterSelectingCell {
    return YES;
}

@end
