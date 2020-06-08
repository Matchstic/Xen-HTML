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

#import "XENHResources.h"
#import "XENHWidgetLayerController.h"
#import "XENHHomescreenForegroundViewController.h"
#import <objc/runtime.h>

@interface XENResources : NSObject
+(BOOL)enabled;
+(BOOL)useGroupedNotifications;
+(NSString*)currentlyShownNotificationAppIdentifier;
@end

@interface PHContainerView : UIView
+(id)_xenhtml_sharedPH;
@property (readonly) NSString* selectedAppID;
@end

@interface SBLockScreenNotificationListController : NSObject
- (unsigned long long)count;
@end

@interface SBDashBoardNotificationListViewController : NSObject
@property(readonly, nonatomic) _Bool hasContent;
@end

@interface SBDashBoardMainPageContentViewController : UIViewController
@property(readonly, nonatomic) SBDashBoardNotificationListViewController *notificationListViewController;
@end

@interface SBDashBoardMainPageViewController : UIViewController
@property(readonly, nonatomic) SBDashBoardMainPageContentViewController *contentViewController;
@end

@interface SBDashBoardViewController : UIViewController
@property(retain, nonatomic) SBDashBoardMainPageViewController *mainPageViewController;
@end

@interface SBLockScreenManager : NSObject
+(instancetype)sharedInstance;
- (id)lockScreenViewController;
@end

static NSDictionary *settings;
static NSBundle *strings;
static int currentOrientation = 1;
static BOOL phIsVisible;
static BOOL xenIsVisible;
static BOOL displayState = YES;
static bool hasSeenFirstUnlock = NO;
static bool hasSeenSpringBoardLaunch = NO;
static NSUserDefaults *PHDefaults;
static SBLockScreenNotificationListController * __weak cachedLSNotificationController;
static int iOS10NotificationCount;

@implementation XENHResources

void XenHTMLLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
    // Type to hold information about variable arguments.
    
    if (![XENHResources debugLogging]) {
        return;
    }
    
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    if (![format hasSuffix:@"\n"]) {
        format = [format stringByAppendingString:@"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    // End using variable argument list.
    va_end(ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    NSLog(@"Xen HTML :: (%s:%d) %s",
          [fileName UTF8String],
          lineNumber, [body UTF8String]);
}

+ (BOOL)debugLogging {
    return YES;
}

// From: https://stackoverflow.com/a/47297734
+ (NSString*)_fallbackStringForKey:(NSString*)key withBundle:(NSBundle*)bundle {
    NSString *fallbackLanguage = @"en";
    NSString *fallbackBundlePath = [bundle pathForResource:fallbackLanguage ofType:@"lproj"];
    NSBundle *fallbackBundle = [NSBundle bundleWithPath:fallbackBundlePath];
    NSString *fallbackString = [fallbackBundle localizedStringForKey:key value:key table:nil];
    
    return fallbackString;
}

+(NSString*)localisedStringForKey:(NSString*)key {
    if (!strings) {
        strings = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle"];
    }
    
    if (!strings) {
        // might be in the Electra bootstrap?
        strings = [NSBundle bundleWithPath:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle"];
    }
    
    if (!strings) {
        // Just return the key as a failsafe.
        return key;
    }
    
    return [strings localizedStringForKey:key value:[self _fallbackStringForKey:key withBundle:strings] table:nil];
}

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

+(CGSize)getSizeForText:(NSString *)text maxWidth:(CGFloat)width font:(NSString *)fontName fontSize:(float)fontSize {
    CGSize constraintSize;
    constraintSize.height = MAXFLOAT;
    constraintSize.width = width;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:fontName size:fontSize], NSFontAttributeName,
                                          nil];
    
    CGRect frame = [text boundingRectWithSize:constraintSize
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:attributesDictionary
                                      context:nil];
    
    CGSize stringSize = frame.size;
    return stringSize;
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

#pragma mark Load up HTML

+ (XENHWidgetLayerController*)widgetLayerControllerForLocation:(XENHLayerLocation)location {
    if (location == kLocationSBForeground) {
        return [[XENHHomescreenForegroundViewController alloc] initWithLayerLocation:location];
    } else {
        return [[XENHWidgetLayerController alloc] initWithLayerLocation:location];
    }
}

+ (BOOL)widgetLayerHasContentForLocation:(XENHLayerLocation)location {
    NSString *layerPreferenceKey = @"";
    
    switch (location) {
        case kLocationLSBackground:
            layerPreferenceKey = @"LSBackground";
            break;
        case kLocationLSForeground:
            layerPreferenceKey = @"LSForeground";
            break;
        case kLocationSBBackground:
            layerPreferenceKey = @"SBBackground";
            break;
        case kLocationSBForeground:
            layerPreferenceKey = @"SBForeground";
            break;
            
        default:
            break;
    }
    
    NSArray *array = [[[XENHResources getPreferenceKey:@"widgets"] objectForKey:layerPreferenceKey] objectForKey:@"widgetArray"];
    
    return array.count > 0;
}

+ (NSDictionary*)widgetPreferencesForLocation:(XENHLayerLocation)location {
    NSString *layerPreferenceKey = @"";
    
    switch (location) {
        case kLocationLSBackground:
            layerPreferenceKey = @"LSBackground";
            break;
        case kLocationLSForeground:
            layerPreferenceKey = @"LSForeground";
            break;
        case kLocationSBBackground:
            layerPreferenceKey = @"SBBackground";
            break;
        case kLocationSBForeground:
            layerPreferenceKey = @"SBForeground";
            break;
            
        default:
            break;
    }
    
    return [[XENHResources getPreferenceKey:@"widgets"] objectForKey:layerPreferenceKey];
}

+(BOOL)_recursivelyCheckForGroovyAPI:(NSString*)folder {
    NSError *error;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:&error];
    
    BOOL output = NO;
    
    for (NSString *item in contents) {
        NSString *fullpath = [NSString stringWithFormat:@"%@/%@", folder, item];
        
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:fullpath isDirectory:&isDir];
        
        if (isDir) {
            output = [self _recursivelyCheckForGroovyAPI:fullpath];
            
            if (output)
                break;
        } else {
            // Check for groovyAPI if suffix is .js
            
            if ([item hasSuffix:@".js"]) {
                XENlog(@"Checking %@ for groovyAPI", item);
                
                NSError *error;
                
                NSString *string = [NSString stringWithContentsOfFile:fullpath encoding:NSUTF8StringEncoding error:&error];
                
                if (!error && [string rangeOfString:@"groovyAPI."].location != NSNotFound) {
                    output = YES;
                    break;
                }
            }
        }
    }
    
    return output;
}

+(BOOL)useFallbackForHTMLFile:(NSString*)filePath {
    if ([XENHResources isAtLeastiOSVersion:10 subversion:0])
        return NO;
    
    BOOL value = NO;
    NSError *error;
    
    NSString *string = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (!error && [string rangeOfString:@"text/cycript"].location != NSNotFound) {
        value = YES;
    }
    
    // Handle groovyAPI.

    // We will also iterate recursively through this widget, and check if it needs groovyAPI.
    // Docs: https://web.archive.org/web/20150910231544/http://www.groovycarrot.co.uk/groovyapi/
    // First, we will check the incoming .html.
        
    BOOL hasgAPI = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/groovyAPI.dylib" isDirectory:nil]) {
        if (!error && [string rangeOfString:@"groovyAPI."].location != NSNotFound) {
            hasgAPI = YES;
        } else {
            NSString *topHeirarchy = [filePath stringByDeletingLastPathComponent];
            
            hasgAPI = [self _recursivelyCheckForGroovyAPI:topHeirarchy];
            XENlog(@"Has groovyAPI: %d", hasgAPI);
        }
    }
    
    if (hasgAPI)
        value = YES;
    
    return value;
}

+ (NSDictionary*)widgetMetadataForHTMLFile:(NSString*)filePath {
    NSDictionary *lsBackgroundMetadata = [[self widgetPreferencesForLocation:kLocationLSBackground] objectForKey:@"widgetMetadata"];
    
    if ([lsBackgroundMetadata.allKeys containsObject:filePath]) {
        return [lsBackgroundMetadata objectForKey:filePath];
    }
    
    NSDictionary *lsForegroundMetadata = [[self widgetPreferencesForLocation:kLocationLSForeground] objectForKey:@"widgetMetadata"];
    
    if ([lsForegroundMetadata.allKeys containsObject:filePath]) {
        return [lsForegroundMetadata objectForKey:filePath];
    }
    
    NSDictionary *sbBackgroundMetadata = [[self widgetPreferencesForLocation:kLocationSBBackground] objectForKey:@"widgetMetadata"];
    
    if ([sbBackgroundMetadata.allKeys containsObject:filePath]) {
        return [sbBackgroundMetadata objectForKey:filePath];
    }
    
    NSDictionary *sbForegroundMetadata = [[self widgetPreferencesForLocation:kLocationSBForeground] objectForKey:@"widgetMetadata"];
    
    if ([sbForegroundMetadata.allKeys containsObject:filePath]) {
        return [sbForegroundMetadata objectForKey:filePath];
    }
    
    return [NSDictionary dictionary];
}

+(void)setPreferenceKey:(NSString*)key withValue:(id)value andPost:(BOOL)post {
    if (!key || !value) {
        NSLog(@"Not setting value, as one of the arguments is null");
        return;
    }
    
    NSMutableDictionary *mutableSettings = [settings mutableCopy];

    [mutableSettings setObject:value forKey:key];
    
    // Write to CFPreferences
    CFPreferencesSetValue ((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    [mutableSettings writeToFile:@"/var/mobile/Library/Preferences/com.matchstic.xenhtml.plist" atomically:YES];
    
    settings = mutableSettings;
    
    if (post) {
        // Notify that we've changed!
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/settingschanged";
        if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

+ (void)setWidgetPreferences:(NSDictionary*)layerPreferences forLocation:(XENHLayerLocation)location {
    NSString *layerPreferenceKey = @"";
    
    switch (location) {
        case kLocationLSBackground:
            layerPreferenceKey = @"LSBackground";
            break;
        case kLocationLSForeground:
            layerPreferenceKey = @"LSForeground";
            break;
        case kLocationSBBackground:
            layerPreferenceKey = @"SBBackground";
            break;
        case kLocationSBForeground:
            layerPreferenceKey = @"SBForeground";
            break;
            
        default:
            break;
    }
    
    NSMutableDictionary *allLayerPreferences = [[XENHResources getPreferenceKey:@"widgets"] mutableCopy];
    if (!allLayerPreferences)
        allLayerPreferences = [NSMutableDictionary dictionary];
    
    [allLayerPreferences setObject:layerPreferences forKey:layerPreferenceKey];
    
    [XENHResources setPreferenceKey:@"widgets" withValue:allLayerPreferences andPost:NO];
}

+ (id)getPreferenceKey:(NSString*)key {
    if (!settings)
        [self reloadSettings];
    
    return [settings objectForKey:key];
}

#pragma mark Settings handling

+(void)reloadSettings {
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xenhtml"));
    
    CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keyList) {
        settings = [NSMutableDictionary dictionary];
    } else {
        CFDictionaryRef dictionary = CFPreferencesCopyMultiple(keyList, CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        
        settings = [(__bridge NSDictionary *)dictionary copy];
        CFRelease(dictionary);
        CFRelease(keyList);
    }
    
    // Convert iOS 10 clock hiding if needed.
    id value = settings[@"hideClockTransferred10"];
    BOOL hideTransferred = (value ? [value boolValue] : NO);
    
    if ([XENHResources isAtLeastiOSVersion:10 subversion:0] && !hideTransferred) {
        BOOL hideClock = [self hideClock];
        
        [self setPreferenceKey:@"hideClock10" withValue:[NSNumber numberWithInt:hideClock ? 2 : 0] andPost:YES];
        [self setPreferenceKey:@"hideClockTransferred10" withValue:[NSNumber numberWithBool:YES] andPost:YES];
    }
    
    // Move "Background" widgets to new location
    settings = [self migrateBackgroundWidgetsIfNecessary:settings];
}

+ (BOOL)_isOnSupportedIOSVersion {
    long long minVersion = 9;
    long long maxVersion = 14;
    
    return [XENHResources isAtLeastiOSVersion:minVersion subversion:0] && [XENHResources isBelowiOSVersion:maxVersion subversion:0];
}

+ (BOOL)showUnsupportedAlertForCurrentVersion {
    if ([self _isOnSupportedIOSVersion]) {
        return NO;
    }
    
    // Check settings if this version has been okay-ed by the user.
    NSString *versionCheckKey = [NSString stringWithFormat:@"unsupportedOverride%@", [UIDevice currentDevice].systemVersion];
    
    id overriden = settings[versionCheckKey];
    if (overriden ? [overriden boolValue] : NO) {
        return NO;
    }
    
    // Not okay-ed in advance, and not supported for certain.
    return YES;
}

+ (NSDictionary*)migrateBackgroundWidgetsIfNecessary:(NSDictionary*)settings {
    NSMutableDictionary *allLayerPreferences = [[settings objectForKey:@"widgets"] mutableCopy];
    if (!allLayerPreferences)
        return settings;
    
    BOOL didChange = NO;
    
    NSString* (^nameReplacer)(NSString *) = ^(NSString *location) {
        NSString *newLocation = [location stringByReplacingOccurrencesOfString:@"/var/mobile/Library/LockHTML/Background" withString:@"/var/mobile/Library/Widgets/Backgrounds/Background"];
        newLocation = [newLocation stringByReplacingOccurrencesOfString:@"/var/mobile/Library/SBHTML/Background" withString:@"/var/mobile/Library/Widgets/Backgrounds/Background"];
        newLocation = [newLocation stringByReplacingOccurrencesOfString:@"LockBackground.html" withString:@"index.html"];
        newLocation = [newLocation stringByReplacingOccurrencesOfString:@"Wallpaper.html" withString:@"index.html"];
        
        return newLocation;
    };
    
    for (NSString *layer in allLayerPreferences.allKeys) {
        NSMutableDictionary *layerPreferences = [[allLayerPreferences objectForKey:layer] mutableCopy];
        NSMutableArray *layerWidgets = [[layerPreferences objectForKey:@"widgetArray"] mutableCopy];
        NSMutableDictionary *layerMetadata = [[layerPreferences objectForKey:@"widgetMetadata"] mutableCopy];
        
        if (!layerWidgets || !layerMetadata)
            continue;
        
        // Handle widget path name
        for (NSString *location in layerWidgets.copy) {
            if ([location rangeOfString:@"/var/mobile/Library/LockHTML/Background"].location != NSNotFound ||
                [location rangeOfString:@"/var/mobile/Library/SBHTML/Background"].location != NSNotFound) {
                
                // Replace path components
                NSString *newLocation = nameReplacer(location);
                [layerWidgets replaceObjectAtIndex:[layerWidgets indexOfObject:location] withObject:newLocation];
                
                didChange = YES;
            }
        }
        
        // And also do the same for metadata
        for (NSString *key in layerMetadata.allKeys.copy) {
            if ([key rangeOfString:@"/var/mobile/Library/LockHTML/Background"].location != NSNotFound ||
                [key rangeOfString:@"/var/mobile/Library/SBHTML/Background"].location != NSNotFound) {
                
                NSString *newKey = nameReplacer(key);
                NSDictionary *data = [layerMetadata objectForKey:key];
                
                [layerMetadata removeObjectForKey:key];
                [layerMetadata setObject:data forKey:newKey];
                
                didChange = YES;
            }
        }
        
        // Finally, update the layerPreferences
        [layerPreferences setObject:layerWidgets forKey:@"widgetArray"];
        [layerPreferences setObject:layerMetadata forKey:@"widgetMetadata"];
        
        [allLayerPreferences setObject:layerPreferences forKey:layer];
    }
    
    // Update allLayerPreferences
    NSMutableDictionary *result = [settings mutableCopy];
    [result setObject:allLayerPreferences forKey:@"widgets"];
    
    if (didChange)
        [self setPreferenceKey:@"widgets" withValue:allLayerPreferences andPost:NO];
    
    return result;
}

+ (void)userRequestsForceSupportForCurrentVersion {
    NSString *versionCheckKey = [NSString stringWithFormat:@"unsupportedOverride%@", [UIDevice currentDevice].systemVersion];
    [self setPreferenceKey:versionCheckKey withValue:@1 andPost:NO];
}

+ (BOOL)requiresHomescreenForegroundAlert {    
    id value = settings[@"requiresHomescreenForegroundAlert"];
    return (value ? [value boolValue] : YES);
}

+ (void)setHomescreenForegroundAlertSeen:(BOOL)seen {
    [self setPreferenceKey:@"requiresHomescreenForegroundAlert" withValue:[NSNumber numberWithBool:!seen] andPost:NO];
}

#pragma mark LS

+(BOOL)lsenabled {
    id value = settings[@"enabled"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)xenInstalledAndGroupingIsMinimised {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Xen.dylib"]) {
        if ([objc_getClass("XENResources") enabled] && [objc_getClass("XENResources") useGroupedNotifications]) {
            // Check if currently minimised or not
            /*if ([[objc_getClass("XENResources") currentlyShownNotificationAppIdentifier] isEqualToString:@""] || ![objc_getClass("XENResources") currentlyShownNotificationAppIdentifier]) {
                return YES;
            }*/
            return xenIsVisible;
        }
    }
    
    return NO;
}

+(BOOL)hideClock {
    id value = settings[@"hideClock"];
    return (value ? [value boolValue] : NO);
}

+(int)_hideClock10 {
    id value = settings[@"hideClock10"];
    return value ? [value intValue] : 0;
}

+(BOOL)hideSTU {
    id value = settings[@"hideSTU"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)useSameSizedStatusBar {
    id value = settings[@"sameSizedStatusBar"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)hideStatusBar {
    id value = settings[@"hideStatusBar"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)hidePageControlDots {
    id value = settings[@"hidePageControlDots"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)hideTopGrabber {
    if ([self LSShowClockInStatusBar]) {
        return YES;
    }
    
    id value = settings[@"hideTopGrabber"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)hideBottomGrabber {
    id value = settings[@"hideBottomGrabber"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)hideCameraGrabber {
    id value = settings[@"hideCameraGrabber"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)disableCameraGrabber {
    id value = settings[@"disableCameraGrabber"];
    return (value ? [value boolValue] : NO);
}

+(double)lockScreenIdleTime {    
    id temp = settings[@"lockScreenIdleTime"];
    return (temp ? [temp doubleValue] : 10.0);
}

+(BOOL)LSUseLegacyMode {
    id value = settings[@"LSUseLegacyMode"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)LSFadeForegroundForMedia {
    id value = settings[@"LSFadeForegroundForMedia"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)LSFadeForegroundForArtwork {
    if ([XENHResources isAtLeastiOSVersion:10 subversion:0]) {
        return NO;
    }
    
    id value = settings[@"LSFadeForegroundForArtwork"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)LSHideArtwork {
    id value = settings[@"LSHideArtwork"];
    return (value ? [value boolValue] : NO);
}

+ (void)setDisplayState:(BOOL)state {
    displayState = state;
}

+ (BOOL)displayState {
    return displayState;
}

//////////////////////////////////////////////////////
// iPhone X only
//////////////////////////////////////////////////////

+(BOOL)LSHideTorchAndCamera {
    id value = settings[@"LSHideTorchAndCamera"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)LSHideHomeBar {
    id value = settings[@"LSHideHomeBar"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)LSHideFaceIDPadlock {
    id value = settings[@"LSHideFaceIDPadlock"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)LSHideD22CCGrabber {
    id value = settings[@"LSHideControlCentreIndicatorD22"];
    return (value ? [value boolValue] : NO);
}

//////////////////////////////////////////////////////

+(BOOL)LSUseBatteryManagement {
    return YES;
    
    /*id value = settings[@"LSUseBatteryManagement"];
    return (value ? [value boolValue] : YES);*/
}

+(BOOL)LSFadeForegroundForNotifications {
    id value = settings[@"LSFadeForegroundForNotifications"];
    return (value ? [value boolValue] : YES);
}

+(void)cacheNotificationListController:(id)controller {
    cachedLSNotificationController = controller;
}

+(void)cachePriorityHubVisibility:(BOOL)visible {
    phIsVisible = visible;
}

+(void)cacheXenGroupingVisibility:(BOOL)visible {
    xenIsVisible = visible;
}

+(void)addNewiOS10Notification {
    iOS10NotificationCount++;
}

+(void)removeiOS10Notification {
    iOS10NotificationCount--;
}

+(void)setiOS10NotiicationVisible:(BOOL)visible {
    iOS10NotificationCount = visible;
}

+(BOOL)isPriorityHubInstalledAndEnabled {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PriorityHub.dylib"]) {
        if (!PHDefaults) {
            PHDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
        }
        
        return [PHDefaults boolForKey:@"enabled"];
    } else {
        return NO;
    }
}

+(BOOL)isCallbarInstalledAndEnabled {
    return NO;
}

+(BOOL)LSInStateNotificationsHidden {
    // if the notification list view is of count 0, OR xenInstalledAndGroupingIsMinimised, then it's hidden.
    if (!phIsVisible && [self isPriorityHubInstalledAndEnabled]) {
        return YES;
    } else if ([self xenInstalledAndGroupingIsMinimised]) { // Xen second since PH takes priority in that tweak.
        return YES;
    }
    
    if ([XENHResources isBelowiOSVersion:10 subversion:0]) {
        if ([cachedLSNotificationController count] > 0) {
            return NO;
        }
    } else {
        SBDashBoardViewController *cont = [[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewController];
        if (![cont isKindOfClass:objc_getClass("SBDashBoardViewController")]) {
            if ([cachedLSNotificationController count] > 0) {
                return NO;
            }
        } else {
            SBDashBoardMainPageContentViewController *content = cont.mainPageViewController.contentViewController;
        
            SBDashBoardNotificationListViewController *notif = content.notificationListViewController;
        
            return !notif.hasContent;
        }
    }
    
    return YES;
}

+(CGFloat)LSWidgetFadeOpacity {
    id value = settings[@"LSWidgetFadeOpacity"];
    return (value ? [value floatValue] : 0.5);
}

+(BOOL)LSFullscreenNotifications {
    id value = settings[@"LSFullscreenNotifications"];
    return (value ? [value boolValue] : NO);
}

+ (BOOL)LSUseCustomNotificationsPosition {
    id value = settings[@"LSUseCustomNotificationsPosition"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)LSShowClockInStatusBar {
    id value = settings[@"LSShowClockInStatusBar"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)LSBGAllowTouch {
    id value = settings[@"LSBGAllowTouch"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)LSWidgetScrollPriority {
    id value = settings[@"LSWidgetScrollPriority"];
    return (value ? [value boolValue] : NO);
}

+ (BOOL)LSPersistentWidgets {
    id value = settings[@"LSPersistentWidgets"];
    return (value ? [value boolValue] : NO);
}

#pragma mark SB

+(BOOL)SBEnabled {
    id value = settings[@"SBEnabled"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)hideBlurredDockBG {
    id value = settings[@"SBHideDockBlur"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)hideBlurredFolderBG {
    id value = settings[@"SBHideFolderBlur"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)SBHideIconLabels {
    id value = settings[@"SBHideIconLabels"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)SBHidePageDots {
    id value = settings[@"SBHidePageDots"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)SBUseLegacyMode {
    id value = settings[@"SBUseLegacyMode"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)SBAllowTouch {
    id value = settings[@"SBAllowTouch"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)SBForegroundEditingSnapToYAxis {
    id value = settings[@"SBPickerSnapToYAxis"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)SBOnePageWidgetMode {
    id value = settings[@"SBOnePageWidgetMode"];
    return (value ? [value boolValue] : NO);
}

+(BOOL)SBPerPageHTMLWidgetMode {
    id value = settings[@"SBPerPageHTMLWidgetMode"];
    return (value ? [value boolValue] : NO);
}

/**
 * @return { <br>{ location: filename, x: 100, y: 100 },<br> { location: filename, x: 150, y: 150 }<br> }
 */
+(NSArray*)widgetLocations {
    id value = settings[@"widgetLocations"];
    return (value ? value : @{});
}

+ (int)currentPauseStrategy {
    id value = settings[@"widgetPauseStrategy"];
    return (value ? [value intValue] : 1); // defaults to medium
}

// Extra
+(void)setCurrentOrientation:(int)orient {
    currentOrientation = orient;
}

+(int)getCurrentOrientation {
    return currentOrientation;
}

+(BOOL)hasDisplayedSetupUI {    
    id value = settings[@"hasDisplayedSetupUI"];
    return (value ? [value boolValue] : NO);
}

+ (BOOL)hasSeenFirstUnlock {
    return hasSeenFirstUnlock;
}

+ (void)setHasSeenFirstUnlock:(BOOL)state {
    hasSeenFirstUnlock = state;
}

+ (BOOL)hasSeenSpringBoardLaunch {
    return hasSeenSpringBoardLaunch;
}

+ (void)setHasSeenSpringBoardLaunch:(BOOL)state {
    hasSeenSpringBoardLaunch = state;
}

+ (BOOL)isAtLeastiOSVersion:(long long)major subversion:(long long)minor {
    NSOperatingSystemVersion version;
    version.majorVersion = (int)major;
    version.minorVersion = (int)minor;
    version.patchVersion = 0;
    
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
}

+ (BOOL)isBelowiOSVersion:(long long)major subversion:(long long)minor {
    return ![self isAtLeastiOSVersion:major subversion:minor];
}

#pragma mark Compatiblity checks

+ (BOOL)isPageBarAvailable {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Pagebar.dylib"]) {
        static NSDictionary *pagebarPrefs;
        if (!pagebarPrefs)
            pagebarPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/live.calicocat.pagebar.plist"];
        
        id value = [pagebarPrefs objectForKey:@"dotsenabled"];
        id style = [pagebarPrefs objectForKey:@"style"];
        
        BOOL enabled = value ? [value boolValue] : YES;
        BOOL notDefault = style ? ![style isEqualToString:@"default"] : YES;
        
        return enabled && notDefault;
    } else {
        return NO;
    }
}

+ (BOOL)isHarbour2Available {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Harbor2.dylib"];
}

#pragma mark Developer options

+ (BOOL)developerOptionsEnabled {
    return [self showResourceUsageInWidgets] || [self showCompositingBordersInWidgets];
}

+ (BOOL)showResourceUsageInWidgets {
    id value = settings[@"dev_showResourceUsageInWidgets"];
    return (value ? [value boolValue] : NO);
}

+ (BOOL)showCompositingBordersInWidgets {
    id value = settings[@"dev_showCompositingBordersInWidgets"];
    return (value ? [value boolValue] : NO);
}

#pragma mark Pseudo-DRM

+ (BOOL)isInstalledFromOfficialRepository {
#if TARGET_IPHONE_SIMULATOR==1
    return YES;
#endif
    // check .list and status files.
    
    BOOL listExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/com.matchstic.xenhtml.list"];
    BOOL isRootless = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/containers/Bundle/.installed_rootlessJB3"];
    
    /*BOOL presentInStatusFile = NO;
    NSString *statusFile = [NSString stringWithContentsOfFile:@"/var/lib/dpkg/status" encoding:NSUTF8StringEncoding error:nil];
    
    presentInStatusFile = [statusFile containsString:@"com.matchstic.xenhtml"];*/
    
    return listExists || isRootless/* && presentInStatusFile*/;
}

@end
