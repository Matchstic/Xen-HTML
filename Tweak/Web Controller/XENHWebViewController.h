//
//  XENHWebViewController.h
//  
//
//  Created by Matt Clarke on 13/12/2015.
//
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface XENHWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, readwrite) int variant;

-(instancetype)initWithBaseString:(NSString*)string;
-(void)rotateToOrientation:(int)orient;
-(void)reloadToNewLocation:(NSString*)newLocation;
-(void)unloadView;
-(void)setPaused:(BOOL)paused;
-(void)setPaused:(BOOL)paused animated:(BOOL)animated;

-(void)_recieveWebTouchGesture:(id)sender;
-(id)_webTouchDelegate;
- (void)_forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)_forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)_forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)_forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

- (void)addGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer;
- (void)removeGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer;

-(CGPoint)currentWebViewPosition;

-(BOOL)isTrackingTouch;

@end
