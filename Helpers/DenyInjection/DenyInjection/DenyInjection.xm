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

/**
 * The goal with this helper is to prevent other tweaks from accidentally loading
 * into any of the WebKit daemons. This typically occurs due to said tweaks using
 * the com.apple.UIKit filter, but continuing to load even in non-apps.
 *
 * In some cases, this can lead to a system freeze, which then is attibuted (incorrectly)
 * to Xen HTML.
 *
 * Implementation is heavily based upon StopCrashingPls (https://github.com/hbang/StopCrashingPls)
 */
 
#import <Foundation/Foundation.h>

#include <libgen.h>
#include <crt_externs.h>

static BOOL hasPrefix(const char *string, const char *prefix) {
    return strncmp(prefix, string, strlen(prefix)) == 0;
}

%hookf(void *, dlopen, const char *path, int mode) {
    if (hasPrefix(path, "/Library/MobileSubstrate/DynamicLibraries") || hasPrefix(path, "/usr/lib/TweakInject")) {
    
        // Check the filter plist for this path. If it whitelists the current process, then allow
        // loading.
        
        NSString *plistPath = [NSString stringWithUTF8String:path];
        plistPath = [plistPath stringByReplacingOccurrencesOfString:@".dylib" withString:@".plist"];
        
        NSDictionary *filterPlist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        
        if (!filterPlist) {
            NSLog(@"Xen HTML (DenyInjection) :: Failed to load filter plist at %@", plistPath);
            return NULL;
        }
        
        NSArray *bundles = [[filterPlist objectForKey:@"Filter"] objectForKey:@"Bundles"];
        NSArray *executables = [[filterPlist objectForKey:@"Filter"] objectForKey:@"Executables"];
        
        char **args = *_NSGetArgv();
        NSString *processName = [NSString stringWithUTF8String:basename(args[0])];
        
        if ([bundles containsObject:@"com.apple.UIKit"] && ![executables containsObject:processName]) {
            NSLog(@"Xen HTML (DenyInjection) :: Blocked loading of %s in %@", path, processName);
            return NULL;
        }
    }
        
    return %orig;
}
