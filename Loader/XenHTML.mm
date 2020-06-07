#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Loader/XenHTML.xm"


















#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>

inline BOOL isAtLeastiOSVersion(NSInteger major, NSInteger minor) {
    NSOperatingSystemVersion version;
    version.majorVersion = major;
    version.minorVersion = minor;
    version.patchVersion = 0;
    
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
}



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

@class SpringBoard; 
static void (*_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); 

#line 33 "/Users/matt/iOS/Projects/Xen-HTML/Loader/XenHTML.xm"


static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    _logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$(self, _cmd, arg1);
    
    


    
    void (^presentAlert)(NSString *) = ^(NSString *message) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Xen HTML"
                                     message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
               
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
       
        [alert addAction:defaultAction];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    };
    
    BOOL isRootless = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/containers/Bundle/.installed_rootlessJB3"];
    
    BOOL hasBatteryManager = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/XenHTML_ZBatteryManager.dylib"];
    BOOL hasWebGL = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/XenHTML_WebGL.dylib"];
    BOOL hasWidgetInfo = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/XenHTML_WidgetInfo.dylib"];
    
    
    if (!isRootless) {
        if (!hasBatteryManager) {
            presentAlert(@"\"Battery Management\" has been disabled.\n\nThis will result in greatly increased battery drainage by widgets");
        }
        
        if (!hasWebGL) {
            presentAlert(@"\"WebGL Rendering\" has been disabled.\n\nSome widgets will fail to render correctly on the Lockscreen");
        }
        
        if (!hasWidgetInfo) {
            presentAlert(@"\"Widget Info\" has been disabled.\n\nWidgets will no longer be able to display information like weather, music, and so on");
        }
    }
}



static __attribute__((constructor)) void _logosLocalCtor_bdbb22fb(int __unused argc, char __unused **argv, char __unused **envp) {
    {Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$);}
    
    
    if (isAtLeastiOSVersion(13, 0)) {
        dlopen("/Library/MobileSubstrate/DynamicLibraries/XenHTML/XenHTML_13.dylib", RTLD_NOW);
    } else if (isAtLeastiOSVersion(9, 0)) {
        dlopen("/Library/MobileSubstrate/DynamicLibraries/XenHTML/XenHTML_9to12.dylib", RTLD_NOW);
    } else {
        NSLog(@"Xen HTML :: Loader :: CANNOT LOAD Xen HTML ON THIS iOS VERSION");
    }
}

