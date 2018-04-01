//
//  XENHLockscreenPreferenceController.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import "XENHLockscreenPreferenceController.h"

@interface XENHLockscreenPreferenceController ()

@end

@implementation XENHLockscreenPreferenceController

- (NSString*)titleForController {
    return @"Lockscreen";
}

// Same as wallpaper variant really; 0 == LS, 1 == SB
- (int)variant {
    return 0;
}

- (NSArray*)additionalSettingsSpecifiers {
    // This will be overriden in subclasses to provide settings for each section
    NSArray *specifiers = [self loadSpecifiersFromPlistName:@"LSSettings" target:self];
    
    return specifiers;
}

- (NSString*)preferenceKeyForEnabledState {
    return @"enabled";
}

@end
