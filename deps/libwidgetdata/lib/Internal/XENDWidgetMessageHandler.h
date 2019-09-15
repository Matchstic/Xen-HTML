//
//  XENDWidgetMessageHandler.h
//  libwidgetdata
//
//  Created by Matt Clarke on 15/09/2019.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@protocol XENDWidgetMessageHandlerDelegate <NSObject>
- (void)onMessageReceivedWithPayload:(NSDictionary*)payload forWebView:(WKWebView*)webview;
@end

/**
 *
 */
@interface XENDWidgetMessageHandler : NSObject <WKScriptMessageHandler>

- (instancetype)initWithDelegate:(id<XENDWidgetMessageHandlerDelegate>)delegate;

@end
