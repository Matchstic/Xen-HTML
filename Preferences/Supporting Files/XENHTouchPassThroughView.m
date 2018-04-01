//
//  XENHTouchPassThroughView.m
//  Xen
//
//  Created by Matt Clarke on 08/01/2017.
//
//

#import "XENHTouchPassThroughView.h"

@implementation XENHTouchPassThroughView

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if ([view isEqual:self]) {
        view = nil;
    }
    
    return view;
}

@end
