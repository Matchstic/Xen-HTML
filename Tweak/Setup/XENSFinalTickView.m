//
//  XENSFinalTickView.m
//  
//
//  Created by Matt Clarke on 11/07/2016.
//
//

#import "XENSFinalTickView.h"
#import "XENHResources.h"

@implementation XENHSFinalTickView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.clipsToBounds = NO;
        
        NSString *imagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Setup/Tick%@", [XENHResources imageSuffix]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            // Oh for crying out loud CoolStar
            imagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Setup/Tick%@", [XENHResources imageSuffix]];
        }
        
        UIImage *tick = [UIImage imageWithContentsOfFile:imagePath];
        self.tickImageView = [[UIImageView alloc] initWithImage:[tick imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.tickImageView.backgroundColor = [UIColor clearColor];
        self.tickImageView.frame = CGRectMake(0, 0, 20, 20);
        
        [self addSubview:self.tickImageView];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel.text = @"";
        self.textLabel.textAlignment = NSTextAlignmentLeft;
        self.textLabel.textColor = [UIColor blackColor];
        self.textLabel.font = [UIFont systemFontOfSize:18];
        self.textLabel.numberOfLines = 0;
        
        [self addSubview:self.textLabel];
        
        self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        self.activityView.tintColor = [UIColor blackColor];
        self.activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        
        [self addSubview:self.activityView];
    }
    
    return self;
}

-(void)setupWithText:(NSString*)text {
    self.textLabel.text = text;
}

-(void)reset {
    self.tickImageView.alpha = 0.0;
    self.tickImageView.hidden = YES;
    
    self.activityView.alpha = 1.0;
    self.activityView.hidden = NO;
    [self.activityView stopAnimating];
    
    self.alpha = 0.0;
    self.hidden = NO;
}

-(void)transitionToBegin {
    [self.activityView startAnimating];
    
    self.textLabel.frame = CGRectMake(self.frame.size.width*0.6, 0, self.textLabel.frame.size.width, self.textLabel.frame.size.height);
    
    CGFloat textInset = self.tickImageView.frame.size.width + self.tickImageView.frame.origin.x;
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationCurveEaseOut  animations:^{
        self.textLabel.frame = CGRectMake(textInset, 0, self.frame.size.width - textInset, self.frame.size.height);
        self.alpha = 1.0;
    } completion:nil];
}

-(void)transitionToTick {
    self.tickImageView.hidden = NO;
    
    [UIView animateWithDuration:0.15 animations:^{
        self.tickImageView.alpha = 1.0;
        self.activityView.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [self.activityView stopAnimating];
            self.activityView.hidden = YES;
        }
    }];
}

-(void)layoutSubviews {
    self.tickImageView.center = CGPointMake(self.tickImageView.frame.size.width/2, self.frame.size.height/2);
    CGFloat textInset = self.tickImageView.frame.size.width + self.tickImageView.frame.origin.x + 20;
    self.textLabel.frame = CGRectMake(textInset, 0, self.frame.size.width - textInset, self.frame.size.height);
    self.activityView.frame = self.tickImageView.frame;
}

@end
