#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/DenyInjection/DenyInjection/DenyInjection.xm"




























 
#import <Foundation/Foundation.h>

#include <string.h>
#include <libgen.h>
#include <crt_externs.h>

static BOOL hasPrefix(const char *string, const char *prefix) {
    return strncmp(prefix, string, strlen(prefix)) == 0;
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




#line 40 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/DenyInjection/DenyInjection/DenyInjection.xm"
__unused static void * (*_logos_orig$_ungrouped$dlopen)(const char *path, int mode); __unused static void * _logos_function$_ungrouped$dlopen(const char *path, int mode) {
    if (hasPrefix(path, "/Library/MobileSubstrate/DynamicLibraries") || hasPrefix(path, "/usr/lib/TweakInject")) {
    
        
        
        
        NSString *plistPath = [NSString stringWithUTF8String:path];
        plistPath = [plistPath stringByReplacingOccurrencesOfString:@".dylib" withString:@".plist"];
        
        NSDictionary *filterPlist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        
        
        if (!filterPlist) {
            return _logos_orig$_ungrouped$dlopen(path, mode);
        }
        
        NSArray *bundles = [[filterPlist objectForKey:@"Filter"] objectForKey:@"Bundles"];
        NSArray *executables = [[filterPlist objectForKey:@"Filter"] objectForKey:@"Executables"];
        
        char **args = *_NSGetArgv();
        NSString *processName = [NSString stringWithUTF8String:basename(args[0])];
        
        
        if ([bundles containsObject:@"com.apple.UIKit"] && ![executables containsObject:processName]) {
            return NULL;
        }
    }
        
    return _logos_orig$_ungrouped$dlopen(path, mode);
}

static __attribute__((constructor)) void _logosLocalCtor_7e2484d5(int __unused argc, char __unused **argv, char __unused **envp) {
    char **args = *_NSGetArgv();
    const char *processName = args[0];
    
    if ((hasPrefix(processName, "/usr") ||
         hasPrefix(processName, "/System") ||
         strstr(".framework/", processName) != NULL)
        && strstr(processName, "SpringBoard") == NULL 
        && strstr(processName, ".appex") == NULL 
        && !hasPrefix(processName, "/System/Library/CoreServices") 
        && !hasPrefix(processName, "/System/Library/SpringBoardPlugins")) 
    {
        { MSHookFunction((void *)dlopen, (void *)&_logos_function$_ungrouped$dlopen, (void **)&_logos_orig$_ungrouped$dlopen);}
    }
}
