//
//  XENDHijackedWebViewDelegate.h
//  libwidgetdata
//
//  Created by Matt Clarke on 05/09/2019.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

/**
 Used to intercept various navigation messages from the underlying webview.
 These are used to drive registering it with the internal widget manager
 */

@interface XENDHijackedWebViewDelegate : NSObject <WKNavigationDelegate>

- (instancetype)initWithOriginalDelegate:(id)delegate;

@end
