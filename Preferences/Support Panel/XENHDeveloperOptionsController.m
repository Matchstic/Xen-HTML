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

- (NSString*)plistName {
    return @"DevOptions";
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
