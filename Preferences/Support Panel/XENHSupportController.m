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

#import "XENHSupportController.h"
#import <sys/utsname.h>
#import <libMobileGestalt.h>
#include <sys/stat.h>
#import "XENHResources.h"
#import <libGitHubIssues.h>
#include <spawn.h>

extern char **environ;

@interface XENHSupportController ()

@end

@implementation XENHSupportController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Support" target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[[s objectAtIndex: i] name] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] table:nil] forKey: key];
            }
            [[s objectAtIndex: i] setTitleDictionary: newTitles];
        }
    }
    
    return s;
}

-(void)_actuallyNukeAllSettings {
    NSArray *allKeys = @[@"widgetPrefs",
                         @"hideClock",
                         @"hideClock10",
                         @"hideSTU",
                         @"sameSizedStatusBar",
                         @"hideStatusBar",
                         @"hideTopGrabber",
                         @"hideBottomGrabber",
                         @"hideCameraGrabber",
                         @"hidePageControlDots",
                         @"disableCameraGrabber",
                         @"lockScreenIdleTime",
                         @"LSUseLegacyMode",
                         @"LSHideTorchAndCamera",
                         @"LSHideHomeBar",
                         @"LSHideFaceIDPadlock",
                         @"LSFadeForegroundForMedia",
                         @"LSFadeForegroundForArtwork",
                         @"LSUseBatteryManagement",
                         @"LSFadeForegroundForNotifications",
                         @"LSWidgetFadeOpacity",
                         @"LSFullscreenNotifications",
                         @"LSShowClockInStatusBar",
                         @"LSBGAllowTouch",
                         @"LSWidgetScrollPriority",
                         @"LSHideArtwork",
                         @"SBEnabled",
                         @"SBHideDockBlur",
                         @"SBUseLegacyMode",
                         @"SBAllowTouch",
                         @"backgroundLocation",
                         @"foregroundLocation",
                         @"SBLocation",
                         @"hasDisplayedSetupUI",
                         @"SBHideIconLabels",
                         @"SBHidePageDots",
                         @"SBHideFolderBlur"
                         ];
    
    NSDictionary *newSettings = [NSDictionary dictionary];
    
    // Write to CFPreferences
    //CFPreferencesSetValue ((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    CFPreferencesSetMultiple(NULL, (__bridge CFArrayRef)allKeys, CFSTR("com.matchstic.xenhtml"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    [newSettings writeToFile:@"/var/mobile/Library/Preferences/com.matchstic.xenhtml.plist" atomically:YES];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Xen HTML" message:[XENHResources localisedStringForKey:@"Your device will now respring to apply changes" value:@"Your device will now respring to apply changes"] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Respring on OK!
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/wantsrespring";
        if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }];
    
    [alertController addAction:okAction];
    
    [self.navigationController presentViewController:alertController animated:YES completion:^{}];
}

-(void)nukeAllSettings:(id)sender {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:[XENHResources localisedStringForKey:@"Warning" value:@"Warning"] message:[XENHResources localisedStringForKey:@"This will clear all Xen HTML settings.\n\nDo you wish to continue?" value:@"This will clear all Xen HTML settings.\n\nDo you wish to continue?"] delegate:self cancelButtonTitle:[XENHResources localisedStringForKey:@"Cancel" value:@"Cancel"] otherButtonTitles:[XENHResources localisedStringForKey:@"Go Nuclear" value:@"Go Nuclear"], nil];
    
    [av show];
}

-(void)openInTwitter:(id)sender {
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *tweetbot = [NSURL URLWithString:@"tweetbot:///user_profile/_Matchstic"];
    if ([app canOpenURL:tweetbot])
        [app openURL:tweetbot];
    else {
        NSURL *twitterapp = [NSURL URLWithString:@"twitter:///user?screen_name=_Matchstic"];
        if ([app canOpenURL:twitterapp])
            [app openURL:twitterapp];
        else {
            NSURL *twitterweb = [NSURL URLWithString:@"http://twitter.com/_Matchstic"];
            [app openURL:twitterweb];
        }
    }
}

-(void)openInCydia:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/com.matchstic.xenhtml"]];
}

-(void)composeSupportEmail:(id)sender {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    
    NSString *messageBody = [NSString stringWithFormat:@"%@ %@ :: %@", machineName, [[UIDevice currentDevice] systemVersion], (NSString*)CFBridgingRelease(MGCopyAnswer(kMGUniqueDeviceID))];
    NSArray *toRecipents = [NSArray arrayWithObject:@"matt@incendo.ws"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:@"Xen HTML Feedback"];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    // We also want the dpkg log
    
    // TODO: Seems to not work on iOS 11!
    NSString *temporaryDirectory = [UIDevice currentDevice].systemVersion.floatValue < 11 ? @"/tmp" : NSTemporaryDirectory();
    NSString *dpkgLogPath = [temporaryDirectory stringByAppendingString:@"/dpkgl.log"];
    
    pid_t pid;
    char *argv[] = {
        "/usr/bin/dpkg",
        "-l",
        (char*)[[@">" stringByAppendingString:dpkgLogPath] UTF8String],
        NULL
    };
    
    posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);
    waitpid(pid, NULL, 0);
    
    //system("/usr/bin/dpkg -l >/tmp/dpkgl.log");
    NSData *dpkgLog = [NSData dataWithContentsOfFile:dpkgLogPath];
    if (dpkgLog)
        [mc addAttachmentData:dpkgLog mimeType:@"text/plain" fileName:@"dpkgl.txt"];
    
    // Present mail view controller on screen
    [self.navigationController presentViewController:mc animated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)openGitHubIssues:(id)sender {
    GIRootViewController *rootModal = [[GIRootViewController alloc] init];
    
    [GIRootViewController registerClientID:@"604b0348c13943dc28fd" andSecret:@"a885c24a81a98d2dae25f64274a267b8f1188daf"];
    [GIRootViewController registerCurrentRepositoryName:@"Xen-HTML" andOwner:@"Matchstic"];
    
    if (IS_IPAD) {
        rootModal.providesPresentationContextTransitionStyle = YES;
        rootModal.definesPresentationContext = YES;
        rootModal.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self.navigationController presentViewController:rootModal animated:YES completion:nil];
}

#pragma mark UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // Request Xen HTML to respring.
    if (_showingRespring) {
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/wantsrespring";
        if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    } else if (buttonIndex == 1) {
        [self _actuallyNukeAllSettings];
    }
}

@end
