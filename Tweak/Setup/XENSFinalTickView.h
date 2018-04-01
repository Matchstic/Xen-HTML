//
//  XENSFinalTickView.h
//  
//
//  Created by Matt Clarke on 11/07/2016.
//
//

#import <UIKit/UIKit.h>

@interface XENHSFinalTickView : UIView

@property (nonatomic, strong) UIImageView *tickImageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

-(void)setupWithText:(NSString*)text;
-(void)reset;
-(void)transitionToTick;
-(void)transitionToBegin;

@end
