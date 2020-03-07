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
#include <dlfcn.h>

#import "../../../deps/libwidgetinfo/lib/Internal/XENDWidgetManager.h"

@interface XENDWidgetWeatherURLHandler  : NSObject
+ (void)setHandlerEnabled:(BOOL)enabled;
@end

#pragma mark Disable components of XenInfo that are superseded

%hook XIWidgetManager

-(NSMutableDictionary*)_populateWidgetSettings {
	NSMutableDictionary *dict = %orig();
	
	// Disable Weather API
	[dict setObject:@NO forKey:@"weather"];
	
	NSLog(@"Xen HTML (widgetinfo) :: Disabled XenInfo's Weather API");
	
	return dict;
}

%end

%ctor {
	NSLog(@"Xen HTML (widgetinfo) :: Loading widget info");
	
	// TODO: Load settings, and apply widgetweather config
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/XenInfo.dylib"]) {
		dlopen("/Library/MobileSubstrate/DynamicLibraries/XenInfo.dylib", RTLD_NOW);
	}
	
	[XENDWidgetManager initialiseLibrary];
	
	%init();
}
