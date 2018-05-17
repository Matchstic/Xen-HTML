//
//  XENWidgetLayerTouchStealingView.h
//  Tweak
//
//  Created by Matt Clarke on 09/05/2018.
//

#import <UIKit/UIKit.h>

@protocol XENWidgetLayerTouchStealingViewDelegate
- (void)forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end

@interface XENWidgetLayerTouchStealingView : UIView

@property (nonatomic, weak) id<XENWidgetLayerTouchStealingViewDelegate> delegate;

- (instancetype)initWithWidgetController:(id)controller;

@end
