#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WidgetInfo/WidgetInfo/WidgetInfo.xm"


















#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <dlfcn.h>

#import "../../../deps/libwidgetinfo/lib/Internal/XENDWidgetManager.h"

@interface XENDWidgetWeatherURLHandler  : NSObject
+ (void)setHandlerEnabled:(BOOL)enabled;
@end

#pragma mark Disable components of XenInfo that are superseded


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

@class XIWidgetManager; 
static NSMutableDictionary* (*_logos_orig$_ungrouped$XIWidgetManager$_populateWidgetSettings)(_LOGOS_SELF_TYPE_NORMAL XIWidgetManager* _LOGOS_SELF_CONST, SEL); static NSMutableDictionary* _logos_method$_ungrouped$XIWidgetManager$_populateWidgetSettings(_LOGOS_SELF_TYPE_NORMAL XIWidgetManager* _LOGOS_SELF_CONST, SEL); 

#line 31 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WidgetInfo/WidgetInfo/WidgetInfo.xm"


static NSMutableDictionary* _logos_method$_ungrouped$XIWidgetManager$_populateWidgetSettings(_LOGOS_SELF_TYPE_NORMAL XIWidgetManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
	NSMutableDictionary *dict = _logos_orig$_ungrouped$XIWidgetManager$_populateWidgetSettings(self, _cmd);
	
	
	[dict setObject:@NO forKey:@"weather"];
	
	NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's Weather API");
	
	return dict;
}



static __attribute__((constructor)) void _logosLocalCtor_9e60c2ca(int __unused argc, char __unused **argv, char __unused **envp) {
	NSLog(@"Xen HTML (widgetinfo) :: Loading widget info");
	
	
	
    BOOL isSpringBoard = [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"];
    
	if (isSpringBoard && [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/XenInfo.dylib"]) {
		dlopen("/Library/MobileSubstrate/DynamicLibraries/XenInfo.dylib", RTLD_NOW);
	}
	
	[XENDWidgetManager initialiseLibrary];
	
	{Class _logos_class$_ungrouped$XIWidgetManager = objc_getClass("XIWidgetManager"); MSHookMessageEx(_logos_class$_ungrouped$XIWidgetManager, @selector(_populateWidgetSettings), (IMP)&_logos_method$_ungrouped$XIWidgetManager$_populateWidgetSettings, (IMP*)&_logos_orig$_ungrouped$XIWidgetManager$_populateWidgetSettings);}
}
