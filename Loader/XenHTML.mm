#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Loader/XenHTML.xm"
#import <Foundation/Foundation.h>
#include <dlfcn.h>

inline BOOL isAtLeastiOSVersion(NSInteger major, NSInteger minor) {
    NSOperatingSystemVersion version;
    version.majorVersion = major;
    version.minorVersion = minor;
    version.patchVersion = 0;
    
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
}

static __attribute__((constructor)) void _logosLocalCtor_ee39cf58(int __unused argc, char __unused **argv, char __unused **envp) {
    {}
    
    
    if (isAtLeastiOSVersion(13, 0)) {
        dlopen("/Library/MobileSubstrate/DynamicLibraries/XenHTML/XenHTML_13.dylib", RTLD_NOW);
    } else if (isAtLeastiOSVersion(9, 0)) {
        dlopen("/Library/MobileSubstrate/DynamicLibraries/XenHTML/XenHTML_9to12.dylib", RTLD_NOW);
    } else {
        NSLog(@"Xen HTML :: Loader :: CANNOT LOAD Xen HTML ON THIS iOS VERSION");
    }
}

