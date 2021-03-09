#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/DenyInjection/DenyInjection/DenyInjection.xm"




























 
#import <Foundation/Foundation.h>

#include <string.h>
#include <libgen.h>
#include <crt_externs.h>

#include <dlfcn.h>
#include <substrate.h>

static BOOL hasPrefix(const char *string, const char *prefix) {
    return strncmp(prefix, string, strlen(prefix)) == 0;
}

MSHook(void *, dlopen, const char *path, int mode, void *lr) {
    if (path == NULL || (mode & RTLD_NOLOAD) == RTLD_NOLOAD) return _dlopen(path, mode, lr);
    
    @try {
        if (hasPrefix(path, "/Library/MobileSubstrate/DynamicLibraries") || hasPrefix(path, "/usr/lib/TweakInject")) {
        
            
            
            
            NSString *plistPath = [NSString stringWithUTF8String:path];
            plistPath = [plistPath stringByReplacingOccurrencesOfString:@".dylib" withString:@".plist"];
            
            NSDictionary *filterPlist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            
            
            if (!filterPlist) {
                return _dlopen(path, mode, lr);
            }
            
            NSDictionary *filter = [filterPlist objectForKey:@"Filter"];
            if (!filter) {
                return _dlopen(path, mode, lr);
            }
            
            NSArray *bundles = [filter objectForKey:@"Bundles"];
            NSArray *executables = [filter objectForKey:@"Executables"];
            
            char **args = *_NSGetArgv();
            NSString *processName = [NSString stringWithUTF8String:basename(args[0])];
            
            
            if ([bundles containsObject:@"com.apple.UIKit"] && ![executables containsObject:processName]) {
                return NULL;
            }
        }
    } @catch (NSException *e) {
        
    }
        
    return _dlopen(path, mode, lr);
}

static __attribute__((constructor)) void _logosLocalCtor_8ad2e004(int __unused argc, char __unused **argv, char __unused **envp) {    
    char **args = *_NSGetArgv();
    const char *processName = args[0];
    
    if ((hasPrefix(processName, "/usr") ||
         hasPrefix(processName, "/System") ||
         strstr(".framework/", processName) != NULL)
         && strstr(processName, "SpringBoard") == NULL 
         && strstr(processName, ".appex") == NULL 
         && !hasPrefix(processName, "/System/Library/CoreServices") 
         && !hasPrefix(processName, "/System/Library/SpringBoardPlugins") 
    ) {
        decltype(_dlopen) dlopen$(nullptr);
        if (MSImageRef libdyld = MSGetImageByName("/usr/lib/system/libdyld.dylib")) {
            MSHookSymbol(dlopen$, "__ZL15dlopen_internalPKciPv", libdyld);
        }
        MSHookFunction(dlopen$ ?: reinterpret_cast<decltype(dlopen$)>(&dlopen), MSHake(dlopen));
    }
}
