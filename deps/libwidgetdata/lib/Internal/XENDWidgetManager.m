//
//  XENDWidgetManager.m
//  libwidgetdata
//
//  Created by Matt Clarke on 15/09/2019.
//

#import "XENDWidgetManager.h"

@interface XENDWidgetManager ()
@property (nonatomic, strong) NSMutableArray<WKWebView*> *managedWebViews;
@property (nonatomic, strong) XENDWidgetMessageHandler *messageHandler;
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
    
    NSLog(@"GOT MESSAGE PAYLOAD: %@", payload);
}

@end
