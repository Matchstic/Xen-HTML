//
//  XENBMResources.m
//  BatteryManager
//
//  Created by Matt Clarke on 20/05/2019.
//

#import "XENBMResources.h"

static NSDictionary *settings;

@implementation XENBMResources

#pragma mark Settings handling

+(void)reloadSettings {
    CFPreferencesAppSynchronize(CFSTR("com.matchstic.xenhtml.batterymanager"));
    
    CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.matchstic.xenhtml.batterymanager"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keyList) {
        settings = [NSMutableDictionary dictionary];
    } else {
        CFDictionaryRef dictionary = CFPreferencesCopyMultiple(keyList, CFSTR("com.matchstic.xenhtml.batterymanager"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        
        settings = [(__bridge NSDictionary *)dictionary copy];
        CFRelease(dictionary);
        CFRelease(keyList);
    }
}

@end
