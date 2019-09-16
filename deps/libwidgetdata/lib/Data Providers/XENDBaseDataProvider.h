//
//  XENDBaseDataProvider.h
//  libwidgetdata
//
//  Created by Matt Clarke on 16/09/2019.
//

#import <Foundation/Foundation.h>
#import "../Internal/XENDWidgetManager-Protocol.h"

@interface XENDBaseDataProvider : NSObject

// Delegate is stored to communicate data back to widgets
@property (nonatomic, weak) id<XENDWidgetManagerDelegate> delegate;

@property (nonatomic, strong) NSDictionary *cachedStaticProperties;
@property (nonatomic, strong) NSMutableDictionary *cachedDynamicProperties;

/**
 * The data namespace provided by the data provider
 */
+ (NSString*)providerNamespace;

/**
 * Called when the device enters sleep mode
 */
- (void)noteDeviceDidEnterSleep;

/**
 * Called when the device leaves sleep mode
 */
- (void)noteDeviceDidExitSleep;

/**
 * Register a delegate object to call upon when new data becomes available.
 * @param delegate The delegate to register
 */
- (void)registerDelegate:(id<XENDWidgetManagerDelegate>)delegate;

/**
 * Called when a new widget is added, and it needs to be provided new data on load.
 * @return Cached data for the provider
 */
- (NSDictionary*)cachedData;

/**
 * Called when a widget message has been received for this provider
 * The callback MUST always be called into
 * @param data The data of the message received
 * @param definition The function definition that this message should be routed to
 * @param callback The callback to be notified when then the message has been handled
 */
- (void)didReceiveWidgetMessage:(NSDictionary*)data functionDefinition:(NSString*)definition callback:(void(^)(NSDictionary*))callback;

/**
 * Called when network access is lost
 */
- (void)networkWasDisconnected;

/**
 * Called when network access is restored
 */
- (void)networkWasConnected;

/**
 * URL escapes the provided input
 */
- (NSString*)escapeString:(NSString*)input;

@end
