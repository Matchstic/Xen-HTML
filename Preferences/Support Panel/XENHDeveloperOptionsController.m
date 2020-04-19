//
//  XENHDeveloperOptionsController.m
//  Preferences
//
//  Created by Matt Clarke on 19/04/2020.
//

#import "XENHDeveloperOptionsController.h"
#import "XENHPResources.h"

@interface XENHDeveloperOptionsController ()

@end

@implementation XENHDeveloperOptionsController

- (id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"DevOptions" target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

// From: https://stackoverflow.com/a/47297734
- (NSString*)_fallbackStringForKey:(NSString*)key {
    NSString *fallbackLanguage = @"en";
    NSString *fallbackBundlePath = [[NSBundle mainBundle] pathForResource:fallbackLanguage ofType:@"lproj"];
    NSBundle *fallbackBundle = [NSBundle bundleWithPath:fallbackBundlePath];
    NSString *fallbackString = [fallbackBundle localizedStringForKey:key value:key table:nil];
    
    return fallbackString;
}

- (NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[self _fallbackStringForKey:[[s objectAtIndex: i] name]] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[self _fallbackStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key]] table:nil] forKey: key];
            }
            [[s objectAtIndex: i] setTitleDictionary: newTitles];
        }
    }
    
    return s;
}

- (void)respring:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Xen HTML" message:[XENHResources localisedStringForKey:@"SUPPORT_RESPRING_NOTIFY"] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/wantsrespring";
        if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }];
    
    [alertController addAction:okAction];
    
    [self.navigationController presentViewController:alertController animated:YES completion:^{}];
}

@end
