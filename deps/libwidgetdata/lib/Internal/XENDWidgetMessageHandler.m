//
//  XENDWidgetMessageHandler.m
//  libwidgetdata
//
//  Created by Matt Clarke on 15/09/2019.
//

#import "XENDWidgetMessageHandler.h"

@interface XENDWidgetMessageHandler ()
@property (nonatomic, weak) id<XENDWidgetMessageHandlerDelegate> delegate;
@end

@implementation XENDWidgetMessageHandler

- (instancetype)initWithDelegate:(id<XENDWidgetMessageHandlerDelegate>)delegate {
    self = [super init];
    
    if (self) {
        self.delegate = delegate;
    }
    
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    
    // Validate message handler
    if (![message.name isEqualToString:@"libwidgetinfo"]) {
        return;
    }
    
    // Handle message - conforms to NativeInterfaceMessage
    if (self.delegate) {
        [self.delegate onMessageReceivedWithPayload:message.body forWebView:message.webView];
    } else {
        NSLog(@"libwidgetinfo :: Received message, but no delegate is available to handle it");
    }
}

@end
