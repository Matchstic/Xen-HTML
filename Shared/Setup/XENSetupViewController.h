//
//  XENSetupViewController.h
//  Tweak (Shared)
//
//  Created by Matt Clarke on 22/02/2020.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface XENSetupViewController : UIViewController <WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;

@end
