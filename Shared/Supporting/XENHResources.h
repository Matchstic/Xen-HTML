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

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kLocationLSBackground,
    kLocationLSForeground,
    kLocationSBBackground,
    kLocationSBForeground
} XENHLayerLocation;

#define orient3 [XENHResources getCurrentOrientation]

#define SCREEN_MAX_LENGTH (MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height))
#define SCREEN_MIN_LENGTH (MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height))

#define SCREEN_HEIGHT (orient3 == 1 || orient3 == 2 ? SCREEN_MAX_LENGTH : SCREEN_MIN_LENGTH)
#define SCREEN_WIDTH (orient3 == 1 || orient3 == 2 ? SCREEN_MIN_LENGTH : SCREEN_MAX_LENGTH)

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#if defined __cplusplus
extern "C" {
#endif
    
void XenHTMLLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
    
#if defined __cplusplus
};
#endif

@interface UITouchesEvent : UIEvent
- (NSSet*)_allTouches;
@end

@interface XENHResources : NSObject

// Load up views as required.
+ (id)widgetLayerControllerForLocation:(XENHLayerLocation)location;
+ (BOOL)widgetLayerHasContentForLocation:(XENHLayerLocation)location;
+ (NSDictionary*)widgetPreferencesForLocation:(XENHLayerLocation)location;

// Metadata
+ (NSDictionary*)widgetMetadataForHTMLFile:(NSString*)filePath;
+ (BOOL)useFallbackForHTMLFile:(NSString*)filePath;

// Settings handling
+(void)reloadSettings;

+(NSString*)localisedStringForKey:(NSString*)key;

+(CGRect)boundedRectForFont:(UIFont*)font andText:(NSString*)text width:(CGFloat)width;
+(CGSize)getSizeForText:(NSString *)text maxWidth:(CGFloat)width font:(NSString *)fontName fontSize:(float)fontSize;
+(NSString*)imageSuffix;
+(void)setPreferenceKey:(NSString*)key withValue:(id)value andPost:(BOOL)post;
+(id)getPreferenceKey:(NSString*)key;
+ (void)setWidgetPreferences:(NSDictionary*)layerPreferences forLocation:(XENHLayerLocation)location;

+ (BOOL)showUnsupportedAlertForCurrentVersion;
+ (void)userRequestsForceSupportForCurrentVersion;

+ (BOOL)requiresHomescreenForegroundAlert;
+ (void)setHomescreenForegroundAlertSeen:(BOOL)seen;

#pragma mark Lockscreen stuff

+(BOOL)lsenabled;
+(BOOL)xenInstalledAndGroupingIsMinimised;
+(BOOL)hideClock;
+(int)_hideClock10;
+(BOOL)hideSTU;
+(BOOL)useSameSizedStatusBar;
+(BOOL)hideStatusBar;
+(BOOL)LSShowClockInStatusBar;
+(BOOL)hidePageControlDots;
+(BOOL)hideTopGrabber;
+(BOOL)hideBottomGrabber;
+(BOOL)hideCameraGrabber;
+(BOOL)disableCameraGrabber;

+ (void)setDisplayState:(BOOL)state;
+ (BOOL)displayState; // YES == on, NO == off, used by battery manager helper

//////////////////////////////////////////////////////
// iPhone X only

+(BOOL)LSHideTorchAndCamera;
+(BOOL)LSHideHomeBar;
+(BOOL)LSHideFaceIDPadlock;
+(BOOL)LSHideD22CCGrabber;

//////////////////////////////////////////////////////

+(BOOL)LSUseLegacyMode;
+(double)lockScreenIdleTime;

+(BOOL)LSFadeForegroundForMedia;
+(BOOL)LSFadeForegroundForArtwork;
+(BOOL)LSHideArtwork;
+(CGFloat)LSWidgetFadeOpacity;

+(BOOL)LSUseBatteryManagement;

+(BOOL)LSFadeForegroundForNotifications;
+(BOOL)LSInStateNotificationsHidden;
+(void)cacheNotificationListController:(id)controller;
+(void)cachePriorityHubVisibility:(BOOL)visible;
+(void)cacheXenGroupingVisibility:(BOOL)visible;
+(void)addNewiOS10Notification;
+(void)removeiOS10Notification;

+(BOOL)LSFullscreenNotifications;
+ (BOOL)LSUseCustomNotificationsPosition;

+(BOOL)LSWidgetScrollPriority;

+ (BOOL)LSPersistentWidgets;

#pragma mark SB stuff

+(BOOL)SBEnabled;
+(BOOL)hideBlurredDockBG;
+(BOOL)hideBlurredFolderBG;
+(BOOL)SBHideIconLabels;
+(BOOL)SBHidePageDots;
+(BOOL)SBAllowTouch;
+(BOOL)SBUseLegacyMode;

+(BOOL)SBForegroundEditingSnapToYAxis;
+(BOOL)SBOnePageWidgetMode;
+(BOOL)SBPerPageHTMLWidgetMode;

#pragma mark Compatiblity checks

+ (BOOL)isPageBarAvailable;
+ (BOOL)isHarbour2Available;

#pragma mark Developer options

+ (BOOL)developerOptionsEnabled;
+ (BOOL)showResourceUsageInWidgets;
+ (BOOL)showCompositingBordersInWidgets;

#pragma mark Extra stuff

+ (int)currentPauseStrategy;

+ (void)setCurrentOrientation:(int)orient;
+ (int)getCurrentOrientation;

+ (BOOL)hasDisplayedSetupUI;
+ (BOOL)hasSeenFirstUnlock;
+ (BOOL)hasSeenSpringBoardLaunch;
+ (void)setHasSeenSpringBoardLaunch:(BOOL)state;
+ (void)setHasSeenFirstUnlock:(BOOL)state;

+ (BOOL)isInstalledFromOfficialRepository;

+ (BOOL)isAtLeastiOSVersion:(long long)major subversion:(long long)minor;
+ (BOOL)isBelowiOSVersion:(long long)major subversion:(long long)minor;

@end
