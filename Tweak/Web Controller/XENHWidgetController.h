//
//  XENHWidgetController.h
//  Tweak
//
//  Created by Matt Clarke on 30/04/2018.
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

@interface XENHWidgetController : UIViewController <WKNavigationDelegate>

// Internal webviews
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIWebView *legacyWebView;

// Widget-specific data
@property (nonatomic, strong) NSString *widgetIndexFile;
@property (nonatomic, strong) NSDictionary *widgetMetadata;
@property (nonatomic, readwrite) BOOL usingLegacyWebView;

// Initialisation
- (instancetype)init;

// Configuration
- (void)configureWithWidgetIndexFile:(NSString*)widgetIndexFile andMetadata:(NSDictionary*)metadata;

// Orientation handling
-(void)rotateToOrientation:(int)orient;

// Pause handling
-(void)setPaused:(BOOL)paused;
-(void)setPaused:(BOOL)paused animated:(BOOL)animated;

// Lifecycle handling
- (void)unloadWidget;
- (void)reloadWidget;

// Touch forwarding
- (BOOL)isWidgetTrackingTouch;
- (void)forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
