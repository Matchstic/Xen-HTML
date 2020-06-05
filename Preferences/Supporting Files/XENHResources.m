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

#import "XENHPResources.h"
#include <notify.h>
#import <UIKit/UIKit.h>
#import "XENHFauxIconsViewController.h"
#import "XENHFauxLockViewController.h"
#import <sys/utsname.h>

static NSBundle *strings;
static NSDictionary *settings;
static NSMutableArray *controllers;
static NSMapTable *previewCellObservers;
static int mainVariant = 0;

@implementation XENHResources

+(CGRect)boundedRectForFont:(UIFont*)font andText:(NSString*)text width:(CGFloat)width {
    if (!text || !font) {
        return CGRectZero;
    }
    
    if (![text isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font}];
        CGRect rect = [attributedText boundingRectWithSize:(CGSize){width, CGFLOAT_MAX}
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
        return rect;
    } else {
        return [(NSAttributedString*)text boundingRectWithSize:(CGSize){width, CGFLOAT_MAX}
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                       context:nil];
    }
}

+(void)reloadSettings {
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xenhtml"));
    
    CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keyList) {
        NSLog(@"There's been an error getting the key list!");
        return;
    }
    
    CFDictionaryRef dictionary = CFPreferencesCopyMultiple(keyList, CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    
    settings = nil;
    settings = [(__bridge NSDictionary *)dictionary copy];
    
    CFRelease(dictionary);
    CFRelease(keyList);
}

+ (NSArray*)allPreferenceKeys {
    return [settings allKeys];
}

+(NSDictionary*)widgetPrefs {
    return settings[@"widgetPrefs"];
}

+(NSString*)foregroundLocation {
    id value = settings[@"foregroundLocation"];
    return (value ? value : @"");
}

+(NSString*)backgroundLocation {
    id value = settings[@"backgroundLocation"];
    return (value ? value : @"");
}

+(NSString*)SBLocation {
    id value = settings[@"SBLocation"];
    return (value ? value : @"");
}

+(CGFloat)editorGetWidgetSize {
    id value = [XENHResources getPreferenceKey:(mainVariant ? @"SBEditorWidgetSize" : @"LSEditorWidgetSize")];
    return (value ? [value floatValue] : 3.0);
}

// From: https://stackoverflow.com/a/47297734
+ (NSString*)_fallbackStringForKey:(NSString*)key {
    NSString *fallbackBundlePath = [strings pathForResource:@"en" ofType:@"lproj"];
    NSBundle *fallbackBundle = [NSBundle bundleWithPath:fallbackBundlePath];
    NSString *fallbackString = [fallbackBundle localizedStringForKey:key value:key table:nil];
    
    return fallbackString;
}

+(NSString*)localisedStringForKey:(NSString*)key {
    if (!strings) {
        strings = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle"];
    }
    
    if (!strings) {
        // might be in bootstrap?
        strings = [NSBundle bundleWithPath:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle"];
    }
    
    if (!strings) {
        // Just go for main bundle.
        strings = [NSBundle mainBundle];
    }
    
    return [strings localizedStringForKey:key value:[self _fallbackStringForKey:key] table:nil];
}

+(NSString*)imageSuffix {
    NSString *suffix = @"";
    switch ((int)[UIScreen mainScreen].scale) {
        case 2:
            suffix = @"@2x";
            break;
        case 3:
            suffix = @"@3x";
            break;
            
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"%@.png", suffix];
}

+(void)setPreferenceKey:(NSString*)key withValue:(id)value {
    if (!key || !value) {
        NSLog(@"Not setting value, as one of the arguments is null");
        return;
    }
    
    [self reloadSettings]; // Update just in case
    
    NSMutableDictionary *mutableSettings = [settings mutableCopy];
    [mutableSettings setObject:value forKey:key];
    
    // Write to CFPreferences
    CFPreferencesSetValue ((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    [mutableSettings writeToFile:@"/var/mobile/Library/Preferences/com.matchstic.xenhtml.plist" atomically:YES];
    
    // Notify that we've changed!
    CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/settingschanged";
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/settingschanged" object:nil];
    }
    
    [self reloadSettings]; // Update just in case
}

+(id)getPreferenceKey:(NSString*)key {
    [self reloadSettings]; // Reload just in case
    return [settings objectForKey:key];
}

/* Preview cell shenanigans */

+ (void)addPreviewObserverForStateChanges:(id<XENHPreviewCellStateDelegate>)observer identifier:(NSString*)identifer {
    if (!previewCellObservers) {
        previewCellObservers = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
    }
    
    [previewCellObservers setObject:observer forKey:identifer];
}

+ (void)removePreviewObserverWithIdentifier:(NSString*)identifier {
    [previewCellObservers removeObjectForKey:identifier];
}

+ (BOOL)getPreviewStateForVariant:(int)variant {
    id value = [XENHResources getPreferenceKey:variant == 0 ? @"enabled" : @"SBEnabled"];
    BOOL on = (value ? [value boolValue] : YES);
    
    return on;
}

+ (void)setPreviewState:(BOOL)state forVariant:(int)variant {
    // Just update observers
    for (NSString *key in previewCellObservers.keyEnumerator) {
        id<XENHPreviewCellStateDelegate> item = [previewCellObservers objectForKey:key];
        [item didChangeEnabledState:state forVariant:variant];
    }
}

+ (CGFloat)getPreviewSkewPercentageForVariant:(int)variant {
    id value = [XENHResources getPreferenceKey:variant == 0 ? @"previewSkewLS" : @"previewSkewSB"];
    return (value ? [value floatValue] : 0.75);
}

+ (void)setPreviewSkewPercentage:(CGFloat)skewPercentage forVariant:(int)variant {
    // Set pref
    NSString *prefkey = variant == 0 ? @"previewSkewLS" : @"previewSkewSB";
    [XENHResources setPreferenceKey:prefkey withValue:[NSNumber numberWithFloat:skewPercentage]];
    
    // update observers
    for (NSString *key in previewCellObservers.keyEnumerator) {
        id<XENHPreviewCellStateDelegate> item = [previewCellObservers objectForKey:key];
        [item didChangeSkewPercentage:skewPercentage forVariant:variant];
    }
}

+ (void)updatePreviewSkewPercentage:(CGFloat)skewPercentage forVariant:(int)variant {
    // update observers
    for (NSString *key in previewCellObservers.keyEnumerator) {
        id<XENHPreviewCellStateDelegate> item = [previewCellObservers objectForKey:key];
        [item didChangeSkewPercentage:skewPercentage forVariant:variant];
    }
}

+ (BOOL)isCurrentDeviceD22 {
    
    static BOOL isD22 = NO;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
#if TARGET_IPHONE_SIMULATOR
        NSString *model = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
#else
        
        struct utsname systemInfo;
        uname(&systemInfo);
        
        NSString *model = [NSString stringWithCString:systemInfo.machine
                                             encoding:NSUTF8StringEncoding];
#endif
        
        isD22 = ![[self _nonD22Devices] containsObject:model];
    });
    
    return isD22;
}

+ (NSArray*)_nonD22Devices {
    return @[
      @"i386",
      @"x86_64",
      @"iPhone1,1",
      @"iPhone1,2",
      @"iPhone2,1",
      @"iPhone3,1",
      @"iPhone3,2",
      @"iPhone3,3",
      @"iPhone4,1",
      @"iPhone5,1",
      @"iPhone5,2",
      @"iPhone5,3",
      @"iPhone5,4",
      @"iPhone6,1",
      @"iPhone6,2",
      @"iPhone7,1",
      @"iPhone7,2",
      @"iPhone8,1",
      @"iPhone8,2",
      @"iPhone8,4",
      @"iPhone9,1",
      @"iPhone9,2",
      @"iPhone9,3",
      @"iPhone9,4",
      @"iPhone10,1",
      @"iPhone10,4",
      @"iPhone10,2",
      @"iPhone10,5",
      
      @"iPad1,1",
      @"iPad2,1",
      @"iPad2,2",
      @"iPad2,3",
      @"iPad2,4",
      @"iPad3,1",
      @"iPad3,2",
      @"iPad3,3",
      @"iPad3,4",
      @"iPad3,5",
      @"iPad3,6",
      @"iPad4,1",
      @"iPad4,2",
      @"iPad4,3",
      @"iPad5,3",
      @"iPad5,4",
      
      @"iPad2,5",
      @"iPad2,6",
      @"iPad2,7",
      @"iPad4,4",
      @"iPad4,5",
      @"iPad4,6",
      @"iPad4,7",
      @"iPad4,8",
      @"iPad4,9",
      @"iPad5,1",
      @"iPad5,2",
      
      @"iPod1,1",
      @"iPod2,1",
      @"iPod3,1",
      @"iPod4,1",
      @"iPod5,1",
      @"iPod7,1",
    ];
}

@end
