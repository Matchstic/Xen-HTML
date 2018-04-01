//
//  XENHResources.h
//  
//
//  Created by Matt Clarke on 13/12/2015.
//
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kLocationBackground,
    kLocationForeground,
    kLocationWidgets,
    kLocationSBHTML
} XENHViewLocation;

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

static BOOL didEndGraceMode = NO;
static BOOL shownGraceEnded = NO;

@interface XENHResources : NSObject

// Load up views as required.
+(id)configuredHTMLViewControllerForLocation:(XENHViewLocation)location;
+(BOOL)useFallbackForHTMLFile:(NSString*)filePath;
+(NSDictionary*)widgetMetadataForHTMLFile:(NSString*)filePath;
+(NSDictionary*)widgetMetadataForLocation:(int)location;
+(NSDictionary*)rawMetadataForHTMLFile:(NSString*)filePath;
+(NSString*)indexHTMLFileForLocation:(XENHViewLocation)location;

// Settings handling
+(void)reloadSettings;

+(NSString*)localisedStringForKey:(NSString*)key value:(NSString*)val;
+(CGRect)boundedRectForFont:(UIFont*)font andText:(NSString*)text width:(CGFloat)width;
+(CGSize)getSizeForText:(NSString *)text maxWidth:(CGFloat)width font:(NSString *)fontName fontSize:(float)fontSize;
+(NSString*)imageSuffix;
+(void)setPreferenceKey:(NSString*)key withValue:(id)value andPost:(BOOL)post;
+(id)getPreferenceKey:(NSString*)key;

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

//////////////////////////////////////////////////////
// iPhone X only

+(BOOL)LSHideTorchAndCamera;
+(BOOL)LSHideHomeBar;
+(BOOL)LSHideFaceIDPadlock;

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

+(BOOL)LSBGAllowTouch;

+(BOOL)LSWidgetScrollPriority;

#pragma mark SB stuff

+(BOOL)SBEnabled;
+(BOOL)hideBlurredDockBG;
+(BOOL)hideBlurredFolderBG;
+(BOOL)SBHideIconLabels;
+(BOOL)SBHidePageDots;
+(BOOL)SBAllowTouch;
+(BOOL)SBUseLegacyMode;

// Extra shit
+(void)setCurrentOrientation:(int)orient;
+(int)getCurrentOrientation;

+(BOOL)hasDisplayedSetupUI;

@end
