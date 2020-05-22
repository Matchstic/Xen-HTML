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
#import <objc/runtime.h>
#import <notify.h>
#include <dlfcn.h>

#import "../../../deps/libwidgetinfo/lib/Internal/XENDWidgetManager.h"
#import "../../../deps/libwidgetinfo/lib/URL Handlers/XENDWidgetWeatherURLHandler.h"
#import "../../../deps/libwidgetinfo/Shared/XENDLogger.h"

static int springboardLaunchToken;

#pragma mark - Fix XenInfo JS bugs

%hook WKWebView

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *error))completionHandler {
    
    if ([javaScriptString hasPrefix:@"mainUpdate"]) {
        javaScriptString = [NSString stringWithFormat:@"if (window.mainUpdate !== undefined) { %@ } ", javaScriptString];
    }
    
    %orig(javaScriptString, completionHandler);
}

%end

#pragma mark - Disable components of XenInfo that are superseded

%hook XIWidgetManager

-(NSMutableDictionary*)_populateWidgetSettings {
	NSMutableDictionary *dict = %orig();
	
	// Disable Weather API
	[dict setObject:@NO forKey:@"weather"];
	NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's Weather API");
    
    // Disable battery/memory API
    [dict setObject:@NO forKey:@"battery"];
    NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's Battery/Memory API");
    
    // Disable system API
    [dict setObject:@NO forKey:@"system"];
    NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's System API");
    
    // Disable music API
    [dict setObject:@NO forKey:@"music"];
    NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's Music API");
	
	return dict;
}

%end

#pragma mark - Notify daemon of SpringBoard launch

%group SpringBoard
%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    
    notify_set_state(springboardLaunchToken, getpid());
    notify_post("com.matchstic.widgetinfo/springboardLaunch");
}

%end
%end

#pragma mark - Constructor

%ctor {
	NSLog(@"Xen HTML (widgetinfo) :: Loading widget info");
	
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion <= 9) {
        // Do not initialise anything
        return;
    }
    
    // Load settings, and apply widgetweather config
    
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
    
    // If WidgetWeather is present, defer to it
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/WWRefresh.dylib"] && !forceWidgetWeatherOverride) {
        
        [XENDWidgetWeatherURLHandler setHandlerEnabled:NO];
    }
    
    // Set filesystem logging as required
    
    [XENDLogger setFilesystemLoggingEnabled:widgetsLogToFilesystem];
    
    // Load XenInfo first to enable hooking into it
	
    BOOL isSpringBoard = [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"];
    
	if (isSpringBoard && [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/XenInfo.dylib"]) {
		dlopen("/Library/MobileSubstrate/DynamicLibraries/XenInfo.dylib", RTLD_NOW);
	}
    
    // Setup notifying of SpringBoard launch
    if (isSpringBoard) {
        int status = notify_register_check("com.matchstic.widgetinfo/springboardLaunch", &springboardLaunchToken);
        if (status != NOTIFY_STATUS_OK) {
            NSLog(@"Xen HTML (widgetinfo) :: registration failed (%u)", status);
            return;
        }
    }
    
    // Initialise library
	
	[XENDWidgetManager initialiseLibrary];
	
	%init();
    
    if (isSpringBoard) {
        %init(SpringBoard);
    }
}
