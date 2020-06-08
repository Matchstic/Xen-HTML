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

#import "XENHAdvancedController.h"
#import "XENHPResources.h"

@interface XENHAdvancedController ()

@end

@implementation XENHAdvancedController

- (NSString*)plistName {
    return @"Advanced";
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
