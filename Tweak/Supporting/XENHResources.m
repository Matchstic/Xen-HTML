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
    
    // Append to log file
    /*NSString *txtFileName = @"/var/mobile/Documents/XenHTMLDebug.txt";
    NSString *final = [NSString stringWithFormat:@"(%s:%d) %s", [fileName UTF8String],
     lineNumber, [body UTF8String]];
     
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:txtFileName];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[final dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        [final writeToFile:txtFileName
                atomically:NO
                  encoding:NSStringEncodingConversionAllowLossy
                     error:nil];
    }*/
}

+(BOOL)debugLogging {
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
    return [[XENHWidgetLayerController alloc] initWithLayerLocation:location];
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
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/groovyAPI.dylib" isDirectory:NO]) {
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

+ (NSDictionary*)rawMetadataForHTMLFile:(NSString*)filePath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // First, check if this is an iWidget.
    // If so, we can fill in the size from Widget.plist
    // Also, we can fill in default values from Options.plist if available, and then re-populate with user set values.
    NSString *path = [filePath stringByDeletingLastPathComponent];
    NSString *lastPathComponent = [filePath lastPathComponent];
    
    NSString *widgetPlistPath = [path stringByAppendingString:@"/Widget.plist"];
    NSString *widgetInfoPlistPath = [path stringByAppendingString:@"/WidgetInfo.plist"];
    NSString *optionsPath = [path stringByAppendingString:@"/Options.plist"];
    
    // Only check Widget.plist if we're loading an iWidget
    if ([lastPathComponent isEqualToString:@"Widget.html"] && [[NSFileManager defaultManager] fileExistsAtPath:widgetPlistPath]) {
        [dict setValue:@NO forKey:@"isFullscreen"];
        
        NSDictionary *widgetPlist = [NSDictionary dictionaryWithContentsOfFile:widgetPlistPath];
        NSDictionary *size = [widgetPlist objectForKey:@"size"];
        
        if (size) {
            [dict setValue:[size objectForKey:@"width"] forKey:@"width"];
            [dict setValue:[size objectForKey:@"height"] forKey:@"height"];
        } else {
            [dict setValue:[NSNumber numberWithFloat:SCREEN_WIDTH] forKey:@"width"];
            [dict setValue:[NSNumber numberWithFloat:SCREEN_HEIGHT] forKey:@"height"];
        }
        
        // Ignore the initial position of the widget, as it's fundamentally not compatible with
        // how we do positioning. Plus, I'm lazy and it's close to release day.
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"x"];
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"y"];
        
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath]) {
        // Handle WidgetInfo.plist
        // This can be loaded for ANY HTML widget, which is neat.
        
        
        NSDictionary *widgetPlist = [NSDictionary dictionaryWithContentsOfFile:widgetInfoPlistPath];
        NSDictionary *size = [widgetPlist objectForKey:@"size"];
        id isFullscreenVal = [widgetPlist objectForKey:@"isFullscreen"];
        
        // Fullscreen.
        BOOL isFullscreen = (isFullscreenVal ? [isFullscreenVal boolValue] : YES);
        [dict setValue:[NSNumber numberWithBool:isFullscreen] forKey:@"isFullscreen"];
        
        if (size && !isFullscreen) {
            [dict setValue:[size objectForKey:@"width"] forKey:@"width"];
            [dict setValue:[size objectForKey:@"height"] forKey:@"height"];
        } else {
            [dict setValue:[NSNumber numberWithFloat:SCREEN_WIDTH] forKey:@"width"];
            [dict setValue:[NSNumber numberWithFloat:SCREEN_HEIGHT] forKey:@"height"];
        }
        
        // Default widget position
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"x"];
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"y"];
    } else {
        [dict setValue:@YES forKey:@"isFullscreen"];
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"x"];
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"y"];
        [dict setValue:[NSNumber numberWithFloat:SCREEN_WIDTH] forKey:@"width"];
        [dict setValue:[NSNumber numberWithFloat:SCREEN_HEIGHT] forKey:@"height"];
    }
    
    // Next, we handle default options.
    // If Widget.html is being loaded, or WidgetInfo.plist exists, load up the Options.plist and add into metadata.
    
    if (([lastPathComponent isEqualToString:@"Widget.html"] || [[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath]) && [[NSFileManager defaultManager] fileExistsAtPath:optionsPath]) {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        
        NSArray *optionsPlist = [NSArray arrayWithContentsOfFile:optionsPath];
        
        for (NSDictionary *option in optionsPlist) {
            NSString *name = [option objectForKey:@"name"];
            
            // Options.plist will contain the following types:
            // edit
            // select
            // switch
            
            id value = nil;
            
            NSString *type = [option objectForKey:@"type"];
            if ([type isEqualToString:@"select"]) {
                NSString *defaultKey = [option objectForKey:@"default"];
                
                value = [[option objectForKey:@"options"] objectForKey:defaultKey];
            } else if ([type isEqualToString:@"switch"]) {
                value = [option objectForKey:@"default"];
            } else {
                value = [option objectForKey:@"default"];
            }
            
            [options setValue:value forKey:name];
        }
        
        [dict setValue:options forKey:@"options"];
    } else {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [dict setValue:options forKey:@"options"];
    }
    
    return dict;
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
    
    return [NSDictionary dictionary];
}

+(void)setPreferenceKey:(NSString*)key withValue:(id)value andPost:(BOOL)post {
    if (!key || !value) {
        NSLog(@"Not setting value, as one of the arguments is null");
        return;
    }
    
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xenhtml"));
    NSMutableDictionary *settings = [(__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost) mutableCopy];
    
    [settings setObject:value forKey:key];
    
    // Write to CFPreferences
    CFPreferencesSetValue ((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    [settings writeToFile:@"/var/mobile/Library/Preferences/com.matchstic.xenhtml.plist" atomically:YES];
    
    if (post) {
        // Notify that we've changed!
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/settingschanged";
        if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

+(id)getPreferenceKey:(NSString*)key {
    return [settings objectForKey:key];
}

#pragma mark Settings handling

+(void)reloadSettings {
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xenhtml"));
    settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    
    // Convert iOS 10 clock hiding if needed.
    id value = settings[@"hideClockTransferred10"];
    BOOL hideTransferred = (value ? [value boolValue] : NO);
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10 && !hideTransferred) {
        BOOL hideClock = [self hideClock];
        
        [self setPreferenceKey:@"hideClock10" withValue:[NSNumber numberWithInt:hideClock ? 2 : 0] andPost:YES];
        [self setPreferenceKey:@"hideClockTransferred10" withValue:[NSNumber numberWithBool:YES] andPost:YES];
        
        CFPreferencesAppSynchronize(CFSTR("com.matchstic.xenhtml"));
        settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    }
    
    [self _migrateWidgetSettingsToRC5OrHigher];
}

+ (void)_migrateWidgetSettingsToRC5OrHigher {
    id widgets = settings[@"widgets"];
    
    if (!widgets) {
        // We need to migrate the widget settings through to the new format.
        
        // Load from old settings
        NSString *backgroundLocation = settings[@"backgroundLocation"] != nil ? settings[@"backgroundLocation"] : @"";
        NSString *foregroundLocation = settings[@"foregroundLocation"] != nil ? settings[@"foregroundLocation"] : @"";
        NSString *sbLocation = settings[@"SBLocation"] != nil ? settings[@"SBLocation"] : @"";
        
        BOOL lsForceLegacy = [self LSUseLegacyMode];
        BOOL sbForceLegacy = [self SBUseLegacyMode];
        
        NSMutableDictionary *backgroundMetadata = [[settings[@"widgetPrefs"] objectForKey:@"LSBackground"] mutableCopy];
        if (!backgroundMetadata)
            backgroundMetadata = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *foregroundMetadata = [[settings[@"widgetPrefs"] objectForKey:@"LSForeground"] mutableCopy];
        if (!foregroundMetadata)
            foregroundMetadata = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *sbMetadata = [[settings[@"widgetPrefs"] objectForKey:@"SBBackground"] mutableCopy];
        if (!sbMetadata)
            sbMetadata = [NSMutableDictionary dictionary];
        
        // Update metadata for fallback per-widget
        [backgroundMetadata setObject:[NSNumber numberWithBool:lsForceLegacy] forKey:@"useFallback"];
        [foregroundMetadata setObject:[NSNumber numberWithBool:lsForceLegacy] forKey:@"useFallback"];
        [sbMetadata setObject:[NSNumber numberWithBool:sbForceLegacy] forKey:@"useFallback"];
        
        // Create new dictionary
        NSMutableDictionary *newWidgetPreferences = [NSMutableDictionary dictionary];
        
        // LSBackground
        NSMutableDictionary *newLSBackgroundPreferences = [NSMutableDictionary dictionary];
        if (backgroundLocation && ![backgroundLocation isEqualToString:@""]) {
            [newLSBackgroundPreferences setObject:@[ backgroundLocation ] forKey:@"widgetArray"];
            [newLSBackgroundPreferences setObject:@{ backgroundLocation: backgroundMetadata } forKey:@"widgetMetadata"];
        }
        [newWidgetPreferences setObject:newLSBackgroundPreferences forKey:@"LSBackground"];
        
        // LSForeground
        NSMutableDictionary *newLSForegroundPreferences = [NSMutableDictionary dictionary];
        if (foregroundLocation && ![foregroundLocation isEqualToString:@""]) {
            [newLSForegroundPreferences setObject:@[ foregroundLocation ] forKey:@"widgetArray"];
            [newLSForegroundPreferences setObject:@{ foregroundLocation: foregroundMetadata } forKey:@"widgetMetadata"];
        }
        [newWidgetPreferences setObject:newLSForegroundPreferences forKey:@"LSForeground"];
        
        // SBBackground
        NSMutableDictionary *newSBBackgroundPreferences = [NSMutableDictionary dictionary];
        if (sbLocation && ![sbLocation isEqualToString:@""]) {
            [newSBBackgroundPreferences setObject:@[ sbLocation ] forKey:@"widgetArray"];
            [newSBBackgroundPreferences setObject:@{ sbLocation: sbMetadata } forKey:@"widgetMetadata"];
        }
        [newWidgetPreferences setObject:newSBBackgroundPreferences forKey:@"SBBackground"];
        
        // Save new dictionary!
        [self setPreferenceKey:@"widgets" withValue:newWidgetPreferences andPost:YES];
        
        // And, reload!
        CFPreferencesAppSynchronize(CFSTR("com.matchstic.xenhtml"));
        settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        
        XENlog(@"Migrated settings!");
    }
}

+ (BOOL)_isOnSupportedIOSVersion {
    CGFloat minVersion = 9.0;
    CGFloat maxVersion = 11.1;
    
    return [UIDevice currentDevice].systemVersion.floatValue <= maxVersion && [UIDevice currentDevice].systemVersion.floatValue >= minVersion;
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

+ (BOOL)userForcedSupportedForCurrentVersion {
    NSString *versionCheckKey = [NSString stringWithFormat:@"unsupportedOverride%@", [UIDevice currentDevice].systemVersion];
    [self setPreferenceKey:versionCheckKey withValue:@1 andPost:NO];
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
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        return NO;
    }
    
    id value = settings[@"LSFadeForegroundForArtwork"];
    return (value ? [value boolValue] : YES);
}

+(BOOL)LSHideArtwork {
    id value = settings[@"LSHideArtwork"];
    return (value ? [value boolValue] : NO);
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

//////////////////////////////////////////////////////

+(BOOL)LSUseBatteryManagement {
    id value = settings[@"LSUseBatteryManagement"];
    return (value ? [value boolValue] : YES);
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
    
    if ([UIDevice currentDevice].systemVersion.floatValue < 10.0) {
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

/**
 * @return { <br>{ location: filename, x: 100, y: 100 },<br> { location: filename, x: 150, y: 150 }<br> }
 */
+(NSArray*)widgetLocations {
    id value = settings[@"widgetLocations"];
    return (value ? value : @{});
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

#pragma mark Developer options

+ (BOOL)developerOptionsEnabled {
    id value = settings[@"dev_optionsEnabled"];
    return (value ? [value boolValue] : NO);
}

+ (BOOL)showResourceUsageInWidgets {
    id value = settings[@"dev_showResourceUsageInWidgets"];
    return (value ? [value boolValue] : NO);
}

+ (BOOL)showCompositingBordersInWidgets {
    id value = settings[@"dev_showCompositingBordersInWidgets"];
    return (value ? [value boolValue] : NO);
}

#pragma mark Pseudo- DRM

+ (BOOL)isInstalledFromOfficialRepository {
    // check .list and status files.
    
    BOOL listExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/com.matchstic.xenhtml.list"];
    
    BOOL presentInStatusFile = NO;
    NSString *statusFile = [NSString stringWithContentsOfFile:@"/var/lib/dpkg/status" encoding:NSUTF8StringEncoding error:nil];
    
    presentInStatusFile = [statusFile containsString:@"com.matchstic.xenhtml"];
    
    return listExists && presentInStatusFile;
}

@end
