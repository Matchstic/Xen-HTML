//
//  XENDWidgetManager.m
//  libwidgetdata
//
//  Created by Matt Clarke on 15/09/2019.
//

#import "XENDWidgetManager.h"
#import "../Data Providers/XENDBaseDataProvider.h"

// Provider imports
#import "../Data Providers/XENDSystemDataProvider.h"

@interface XENDWidgetManager ()
@property (nonatomic, strong) NSMutableArray<WKWebView*> *managedWebViews;
@property (nonatomic, strong) XENDWidgetMessageHandler *messageHandler;

@property (nonatomic, strong) NSDictionary<NSString*, XENDBaseDataProvider*> *dataProviders;
@end

@implementation XENDWidgetManager

+ (instancetype)sharedInstance {
    static XENDWidgetManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[XENDWidgetManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.managedWebViews = [NSMutableArray array];
        self.messageHandler = [[XENDWidgetMessageHandler alloc] initWithDelegate:self];
        
        self.dataProviders = [self _loadDataProviders];
    }
    
    return self;
}

- (void)registerWebView:(WKWebView*)webView {
    if (![self.managedWebViews containsObject:webView]) {
        [self.managedWebViews addObject:webView];
    }
}

- (void)deregisterWebView:(WKWebView*)webView {
    if ([self.managedWebViews containsObject:webView]) {
        [self.managedWebViews removeObject:webView];
    }
}

- (void)notifyWebViewLoaded:(WKWebView*)webView {
    // Inject cached data
    
    NSString *updateString = @"";
    for (NSString *providerNamespace in self.dataProviders.allKeys) {
        XENDBaseDataProvider *provider = [self.dataProviders objectForKey:providerNamespace];
        
        NSDictionary *data = [provider cachedData];
        NSDictionary *payload = @{ @"namespace": providerNamespace, @"payload": data };
        NSDictionary *retval = @{ @"type": @"dataupdate", @"data": payload };
        
        NSString *innerUpdateString = [NSString stringWithFormat:@"WidgetInfo._middleware.onInternalNativeMessage(%@);\n",
                                  [self _parseToJSON:retval]];
        updateString = [updateString stringByAppendingString:innerUpdateString];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:updateString completionHandler:^(id object, NSError *error) {}];
    });
}

- (void)injectRuntime:(WKUserContentController*)contentController {
#if TARGET_IPHONE_SIMULATOR==0
    NSString *scriptLocation = @"/Library/Application Support/Xen HTML/libwidgetinfo.js";
#else
    NSString *scriptLocation = @"/Users/matt/iOS/Projects/Xen-HTML/deps/libwidgetdata/lib/Middleware/build/libwidgetinfo.js";
#endif
    
    NSString *content = [NSString stringWithContentsOfFile:scriptLocation encoding:NSUTF8StringEncoding error:NULL];
    WKUserScript *runtimeScript = [[WKUserScript alloc] initWithSource:content injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    [contentController addUserScript:runtimeScript];
    
    // Setup message handler
    [contentController addScriptMessageHandler:self.messageHandler name:@"libwidgetinfo"];
}

//////////////////////////////////////////////////////////////
// Message handler delegate
//////////////////////////////////////////////////////////////

- (void)onMessageReceivedWithPayload:(NSDictionary*)payload forWebView:(WKWebView*)webview {
    // Payload is an NSDictionary conforming to NativeInterfaceMessage
    
    // Validate initial payload
    if (!payload || ![payload isKindOfClass:[NSDictionary class]]) {
        NSLog(@"libwidgetinfo :: Received a malformed webview message, ignoring");
        return;
    }
    
    // Validate webview
    if (![self.managedWebViews containsObject:webview]) {
        NSLog(@"libwidgetinfo :: Received a webview message that we don't currently manage, ignoring");
        return;
    }
    
    id callbackId = [payload objectForKey:@"callbackId"];
    NSDictionary *innerPayload = [payload objectForKey:@"payload"];
    
    if (!callbackId || !innerPayload) {
        NSLog(@"libwidgetinfo :: Received a malformed webview message, ignoring");
        return;
    }
    
    NSString *namespace = [innerPayload objectForKey:@"namespace"];
    NSString *functionDefinition = [innerPayload objectForKey:@"functionDefinition"];
    NSDictionary *data = [innerPayload objectForKey:@"data"];
    
    XENDBaseDataProvider *provider = [self.dataProviders objectForKey:namespace];
    if (provider) {
        [provider didReceiveWidgetMessage:data
                       functionDefinition:functionDefinition
                                 callback:^(NSDictionary *result) {
                                     
            if (!result)
                result = @{};
            
            NSDictionary *retval = @{ @"type": @"callback", @"data": result, @"callbackId": callbackId };
            
            NSString *updateString = [NSString stringWithFormat:@"WidgetInfo._middleware.onInternalNativeMessage(%@)",
                                      [self _parseToJSON:retval]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [webview evaluateJavaScript:updateString
                          completionHandler:^(id res, NSError * _Nullable error) {}];
            });
        }];
    } else {
        NSLog(@"libwidgetinfo :: Could not find provider for namespace: %@", namespace);
    }
}

-(NSString*)_parseToJSON:(NSDictionary*)dict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"%s: error: %@", __func__, error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

/////////////////////////////////////////////////////////////
// Data provider handling
/////////////////////////////////////////////////////////////

- (void)updateWidgetsWithNewData:(NSDictionary*)data forNamespace:(NSString*)providerNamespace {
    NSDictionary *payload = @{ @"namespace": providerNamespace, @"payload": data };
    NSDictionary *retval = @{ @"type": @"dataupdate", @"data": payload };
    
    NSString *updateString = [NSString stringWithFormat:@"WidgetInfo._middleware.onInternalNativeMessage(%@)",
                              [self _parseToJSON:retval]];
    
    // Loop over widget array, and call update as required.
    for (WKWebView *widget in self.managedWebViews) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [widget evaluateJavaScript:updateString completionHandler:^(id object, NSError *error) {}];
        });
    }
}

- (NSDictionary*)_loadDataProviders {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    XENDSystemDataProvider *system = [[XENDSystemDataProvider alloc] init];
    [system registerDelegate:self];
    [result setObject:system forKey:[XENDSystemDataProvider providerNamespace]];
    
    return result;
}

@end
