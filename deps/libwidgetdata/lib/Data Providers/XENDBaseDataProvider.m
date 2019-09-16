//
//  XENDBaseDataProvider.m
//  libwidgetdata
//
//  Created by Matt Clarke on 16/09/2019.
//

#import "XENDBaseDataProvider.h"

@implementation XENDBaseDataProvider

// The data topic provided by the data provider
+ (NSString*)providerNamespace {
    return @"_base_";
}

- (void)noteDeviceDidEnterSleep {}
- (void)noteDeviceDidExitSleep {}

// Register a delegate object to call upon when new data becomes available.
- (void)registerDelegate:(id<XENDWidgetManagerDelegate>)delegate {
    self.delegate = delegate;
}

// Called when a new widget is added, and it needs to be provided new data on load.
- (NSDictionary*)cachedData {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result addEntriesFromDictionary:self.cachedDynamicProperties];
    [result addEntriesFromDictionary:self.cachedStaticProperties];
    return result;
}

// Called when a widget message has been received for this provider
// The callback MUST always be called into
- (void)didReceiveWidgetMessage:(NSDictionary*)data functionDefinition:(NSString*)definition callback:(void(^)(NSDictionary*))callback {
    callback(@{});
}

// Called when network access is lost
- (void)networkWasDisconnected {
    
}

// Called when network access is restored
- (void)networkWasConnected {
    
}

- (NSString*)escapeString:(NSString*)input {
    if (!input)
        return @"";
    
    input = [input stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    input = [input stringByReplacingOccurrencesOfString: @"\"" withString:@"\\\""];
    
    return input;
}

@end
