/*
 Copyright (C) 2020 Matt Clarke
 
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
#import <UIKit/UIKit.h>
#include <dlfcn.h>

inline BOOL isAtLeastiOSVersion(NSInteger major, NSInteger minor) {
    NSOperatingSystemVersion version;
    version.majorVersion = major;
    version.minorVersion = minor;
    version.patchVersion = 0;
    
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
}


%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    
    /*
     * Notify user about any disabled helpers
     */
    
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
    
    // Only warn the user when not running in Rootless jailbreaks
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

%end

%ctor {
    %init;
    
    // Load correct Xen HTML dylib based upon the iOS version
    if (isAtLeastiOSVersion(13, 0)) {
        dlopen("/Library/MobileSubstrate/DynamicLibraries/XenHTML/XenHTML_13.dylib", RTLD_NOW);
    } else if (isAtLeastiOSVersion(9, 0)) {
        dlopen("/Library/MobileSubstrate/DynamicLibraries/XenHTML/XenHTML_9to12.dylib", RTLD_NOW);
    } else {
        NSLog(@"Xen HTML :: Loader :: CANNOT LOAD Xen HTML ON THIS iOS VERSION");
    }
}

