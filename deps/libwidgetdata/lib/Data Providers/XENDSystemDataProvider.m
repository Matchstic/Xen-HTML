//
//  XENDSystemDataProvider.m
//  libwidgetdata
//
//  Created by Matt Clarke on 16/09/2019.
//

#import "XENDSystemDataProvider.h"
#import <UIKit/UIKit.h>

#import <sys/utsname.h> //device models

@implementation XENDSystemDataProvider

// The data topic provided by the data provider
+ (NSString*)providerNamespace {
    return @"system";
}

- (void)didReceiveWidgetMessage:(NSDictionary*)data functionDefinition:(NSString*)definition callback:(void(^)(NSDictionary*))callback {
    
    if ([definition isEqualToString:@"log"]) {
        callback([self handleLogMessage:data]);
    }
    
}

///////////////////////////////////////////////////////////////
// Message handlers
///////////////////////////////////////////////////////////////

- (NSDictionary*)handleLogMessage:(NSDictionary*)data {
    if (!data || ![data objectForKey:@"message"]) {
        NSLog(@"libwidgetinfo :: Malformed log message, ignoring");
        return @{};
    }
    
    NSLog(@"libwidgetinfo :: LOG :: %@", [data objectForKey:@"message"]);
    
    return @{};
}

///////////////////////////////////////////////////////////////
// Private initialisation
///////////////////////////////////////////////////////////////

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self _setupStaticProperties];
        
        // TODO: Do initial load for dynamics, and setup watchers
    }
    
    return self;
}

- (void)_setupStaticProperties {
    NSMutableDictionary *statics = [NSMutableDictionary dictionary];
    
    [statics setObject:[self _deviceName] forKey:@"deviceName"];
    [statics setObject:[self _deviceType] forKey:@"deviceType"];
    [statics setObject:[self _machineName] forKey:@"deviceModel"];
    [statics setObject:[self _deviceModel] forKey:@"deviceModelPromotional"];
    [statics setObject:[self _systemVersion] forKey:@"systemVersion"];
    
    [statics setObject:[NSNumber numberWithFloat:[self _screenMaxLength]] forKey:@"deviceDisplayHeight"];
    [statics setObject:[NSNumber numberWithFloat:[self _screenMinLength]] forKey:@"deviceDisplayWidth"];
    
    self.cachedStaticProperties = statics;
}

- (NSString*)_machineName {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

// From: http://theiphonewiki.com/wiki/Models
- (NSString*)_deviceModel {
    NSString *machineName = [self _machineName];
    
    NSDictionary *commonNamesDictionary =
    @{
      @"i386":     @"i386 Simulator",
      @"x86_64":   @"x86_64 Simulator",
      
      @"iPhone1,1":    @"iPhone",
      @"iPhone1,2":    @"iPhone 3G",
      @"iPhone2,1":    @"iPhone 3GS",
      @"iPhone3,1":    @"iPhone 4",
      @"iPhone3,2":    @"iPhone 4",
      @"iPhone3,3":    @"iPhone 4",
      @"iPhone4,1":    @"iPhone 4S",
      @"iPhone5,1":    @"iPhone 5",
      @"iPhone5,2":    @"iPhone 5",
      @"iPhone5,3":    @"iPhone 5c",
      @"iPhone5,4":    @"iPhone 5c",
      @"iPhone6,1":    @"iPhone 5s",
      @"iPhone6,2":    @"iPhone 5s",
      @"iPhone7,1":    @"iPhone 6+",
      @"iPhone7,2":    @"iPhone 6",
      @"iPhone8,1":    @"iPhone 6S",
      @"iPhone8,2":    @"iPhone 6S+",
      @"iPhone8,4":    @"iPhone SE",
      @"iPhone9,1":    @"iPhone 7",
      @"iPhone9,2":    @"iPhone 7+",
      @"iPhone9,3":    @"iPhone 7",
      @"iPhone9,4":    @"iPhone 7+",
      @"iPhone10,1":   @"iPhone 8",
      @"iPhone10,4":   @"iPhone 8",
      @"iPhone10,2":   @"iPhone 8+",
      @"iPhone10,5":   @"iPhone 8+",
      @"iPhone10,3":   @"iPhone X",
      @"iPhone10,6":   @"iPhone X",
      @"iPhone11,2":   @"iPhone XS",
      @"iPhone11,4":   @"iPhone XS Max",
      @"iPhone11,6":   @"iPhone XS Max",
      @"iPhone11,8":   @"iPhone XR",
      
      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2",
      @"iPad2,2":  @"iPad 2",
      @"iPad2,3":  @"iPad 2",
      @"iPad2,4":  @"iPad 2",
      @"iPad3,1":  @"iPad 3",
      @"iPad3,2":  @"iPad 3",
      @"iPad3,3":  @"iPad 3",
      @"iPad3,4":  @"iPad 4",
      @"iPad3,5":  @"iPad 4",
      @"iPad3,6":  @"iPad 4",
      @"iPad4,1":  @"iPad Air",
      @"iPad4,2":  @"iPad Air",
      @"iPad4,3":  @"iPad Air",
      @"iPad5,3":  @"iPad Air 2",
      @"iPad5,4":  @"iPad Air 2",
      
      @"iPad2,5":  @"iPad mini",
      @"iPad2,6":  @"iPad mini",
      @"iPad2,7":  @"iPad mini",
      @"iPad4,4":  @"iPad mini 2",
      @"iPad4,5":  @"iPad mini 2",
      @"iPad4,6":  @"iPad mini 2",
      @"iPad4,7":  @"iPad mini 3",
      @"iPad4,8":  @"iPad mini 3",
      @"iPad4,9":  @"iPad mini 3",
      @"iPad5,1":  @"iPad mini 4",
      @"iPad5,2":  @"iPad mini 4",
      
      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",
      @"iPod7,1":  @"iPod 6th Gen",
      };
    
    NSString *deviceName = commonNamesDictionary[machineName];
    
    if (deviceName == nil) {
        deviceName = machineName;
    }
    
    return deviceName;
}

- (NSString*)_deviceType {
    NSString *machineName = [self _machineName];
    
    if ([machineName rangeOfString:@"iPod"].location != NSNotFound) {
        return @"iPod Touch";
    } else if ([machineName rangeOfString:@"iPad"].location != NSNotFound) {
        return @"iPad";
    } else if ([machineName rangeOfString:@"iPhone"].location != NSNotFound){
        return @"iPhone";
    } else if ([machineName rangeOfString:@"x86_64"].location != NSNotFound){
        return @"Simulator";
    } else {
        return @"Unknown";
    }
}

- (NSString*)_systemVersion {
    return [UIDevice currentDevice].systemVersion;
}

- (NSString*)_deviceName {
    return [self escapeString:[[UIDevice currentDevice] name]];
}

- (BOOL)_using24h {
    NSString *formatStringForHours = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    NSRange containsA = [formatStringForHours rangeOfString:@"a"];
    
    return containsA.location == NSNotFound;
}

- (CGFloat)_screenMaxLength {
    return MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

- (CGFloat)_screenMinLength {
    return MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

@end
