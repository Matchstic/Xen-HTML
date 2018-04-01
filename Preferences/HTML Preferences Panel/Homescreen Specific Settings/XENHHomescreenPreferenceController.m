//
//  XENHHomescreenPreferenceController.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import "XENHHomescreenPreferenceController.h"

@interface XENHHomescreenPreferenceController ()

@end

@implementation XENHHomescreenPreferenceController

- (NSString*)titleForController {
    return @"Homescreen";
}

// Same as wallpaper variant really; 0 == LS, 1 == SB
- (int)variant {
    return 1;
}

- (NSArray*)additionalSettingsSpecifiers {
    // This will be overriden in subclasses to provide settings for each section
    NSArray *specifiers = [self loadSpecifiersFromPlistName:@"SBSettings" target:self];
    
    return specifiers;
}

- (NSString*)preferenceKeyForEnabledState {
    return @"SBEnabled";
}

@end
