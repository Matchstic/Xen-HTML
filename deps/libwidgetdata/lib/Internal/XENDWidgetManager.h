//
//  XENDWidgetManager.h
//  libwidgetdata
//
//  Created by Matt Clarke on 15/09/2019.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "XENDWidgetMessageHandler.h"
#import "XENDWidgetManager-Protocol.h"

@interface XENDWidgetManager : NSObject <XENDWidgetMessageHandlerDelegate, XENDWidgetManagerDelegate>

+ (instancetype)sharedInstance;

- (void)registerWebView:(WKWebView*)webView;
- (void)deregisterWebView:(WKWebView*)webView;

- (void)injectRuntime:(WKUserContentController*)contentController;
- (void)notifyWebViewLoaded:(WKWebView*)webView;

@end
