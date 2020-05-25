#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WidgetInfo/WidgetInfo/WidgetInfo.xm"


















#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <notify.h>
#include <dlfcn.h>

#import "../../../deps/libwidgetinfo/lib/Internal/XENDWidgetManager.h"
#import "../../../deps/libwidgetinfo/lib/URL Handlers/XENDWidgetWeatherURLHandler.h"
#import "../../../deps/libwidgetinfo/Shared/XENDLogger.h"

static int springboardLaunchToken;

#pragma mark - Fix XenInfo JS bugs


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class WKWebView; @class SpringBoard; @class XIWidgetManager; 
static void (*_logos_orig$_ungrouped$WKWebView$evaluateJavaScript$completionHandler$)(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL, NSString *, void (^)(id, NSError *error)); static void _logos_method$_ungrouped$WKWebView$evaluateJavaScript$completionHandler$(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL, NSString *, void (^)(id, NSError *error)); static NSMutableDictionary* (*_logos_orig$_ungrouped$XIWidgetManager$_populateWidgetSettings)(_LOGOS_SELF_TYPE_NORMAL XIWidgetManager* _LOGOS_SELF_CONST, SEL); static NSMutableDictionary* _logos_method$_ungrouped$XIWidgetManager$_populateWidgetSettings(_LOGOS_SELF_TYPE_NORMAL XIWidgetManager* _LOGOS_SELF_CONST, SEL); 

#line 32 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WidgetInfo/WidgetInfo/WidgetInfo.xm"


static void _logos_method$_ungrouped$WKWebView$evaluateJavaScript$completionHandler$(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * javaScriptString, void (^completionHandler)(id, NSError *error)) {
    
    if ([javaScriptString hasPrefix:@"mainUpdate"]) {
        javaScriptString = [NSString stringWithFormat:@"if (window.mainUpdate !== undefined) { %@ } ", javaScriptString];
    }
    
    _logos_orig$_ungrouped$WKWebView$evaluateJavaScript$completionHandler$(self, _cmd, javaScriptString, completionHandler);
}



#pragma mark - Disable components of XenInfo that are superseded



static NSMutableDictionary* _logos_method$_ungrouped$XIWidgetManager$_populateWidgetSettings(_LOGOS_SELF_TYPE_NORMAL XIWidgetManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
	NSMutableDictionary *dict = _logos_orig$_ungrouped$XIWidgetManager$_populateWidgetSettings(self, _cmd);
	
	
	[dict setObject:@NO forKey:@"weather"];
	NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's Weather API");
    
    
    [dict setObject:@NO forKey:@"battery"];
    NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's Battery/Memory API");
    
    
    [dict setObject:@NO forKey:@"system"];
    NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's System API");
    
    
    [dict setObject:@NO forKey:@"music"];
    NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's Music API");
	
	return dict;
}



#pragma mark - Notify daemon of SpringBoard launch

static void (*_logos_orig$SpringBoard$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SpringBoard$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); 


static void _logos_method$SpringBoard$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    _logos_orig$SpringBoard$SpringBoard$applicationDidFinishLaunching$(self, _cmd, arg1);
    
    notify_set_state(springboardLaunchToken, getpid());
    notify_post("com.matchstic.widgetinfo/springboardLaunch");
}




#pragma mark - Constructor

static __attribute__((constructor)) void _logosLocalCtor_07b3768c(int __unused argc, char __unused **argv, char __unused **envp) {
	NSLog(@"Xen HTML (widgetinfo) :: Loading widget info");
	
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion <= 9) {
        
        return;
    }
    
    
    
    NSDictionary *settings;
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
    
    BOOL forceWidgetWeatherOverride = [settings objectForKey:@"forceWidgetWeatherOverride"] ?
        [[settings objectForKey:@"forceWidgetWeatherOverride"] boolValue] :
        NO;
    BOOL widgetsLogToFilesystem = [settings objectForKey:@"widgetsLogToFilesystem"] ?
        [[settings objectForKey:@"widgetsLogToFilesystem"] boolValue] :
        NO;
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/WWRefresh.dylib"] && !forceWidgetWeatherOverride) {
        
        [XENDWidgetWeatherURLHandler setHandlerEnabled:NO];
    }
    
    
    
    [XENDLogger setFilesystemLoggingEnabled:widgetsLogToFilesystem];
    
    
	
    BOOL isSpringBoard = [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"];
    
	if (isSpringBoard && [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/XenInfo.dylib"]) {
		dlopen("/Library/MobileSubstrate/DynamicLibraries/XenInfo.dylib", RTLD_NOW);
	}
    
    
    if (isSpringBoard) {
        int status = notify_register_check("com.matchstic.widgetinfo/springboardLaunch", &springboardLaunchToken);
        if (status != NOTIFY_STATUS_OK) {
            NSLog(@"Xen HTML (widgetinfo) :: registration failed (%u)", status);
            return;
        }
    }
    
    
	
	[XENDWidgetManager initialiseLibrary];
	
	{Class _logos_class$_ungrouped$WKWebView = objc_getClass("WKWebView"); MSHookMessageEx(_logos_class$_ungrouped$WKWebView, @selector(evaluateJavaScript:completionHandler:), (IMP)&_logos_method$_ungrouped$WKWebView$evaluateJavaScript$completionHandler$, (IMP*)&_logos_orig$_ungrouped$WKWebView$evaluateJavaScript$completionHandler$);Class _logos_class$_ungrouped$XIWidgetManager = objc_getClass("XIWidgetManager"); MSHookMessageEx(_logos_class$_ungrouped$XIWidgetManager, @selector(_populateWidgetSettings), (IMP)&_logos_method$_ungrouped$XIWidgetManager$_populateWidgetSettings, (IMP*)&_logos_orig$_ungrouped$XIWidgetManager$_populateWidgetSettings);}
    
    if (isSpringBoard) {
        {Class _logos_class$SpringBoard$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$SpringBoard$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$SpringBoard$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$SpringBoard$SpringBoard$applicationDidFinishLaunching$);}
    }
}
