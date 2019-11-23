//
//  XENHCloseButton.m
//  Tweak
//
//  Created by Matt Clarke on 05/04/2019.
//

#import "XENHCloseButton.h"

@interface XENHCloseButton ()

@property (nonatomic, strong) UIImageView *iconView;

@end

static CGFloat BUTTON_HEIGHT = 28.0;

@implementation XENHCloseButton

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithTitle:@""];
    
    if (self) {
        // Cleanup from base class
        [self.textLabel removeFromSuperview];
        
        // Setup image view. Going for asset with name, IconCloseBoxX
        // Available on at least iOS 9.0 and up
        UIImage *icon = nil;
        
        if (@available(iOS 13.0, *)) {
            icon = [UIImage imageNamed:@"IconCloseBoxX"
                              inBundle:[NSBundle bundleWithIdentifier:@"com.apple.SpringBoardHome"]
                     withConfiguration:nil];
        } else {
            icon = [UIImage imageNamed:@"IconCloseBoxX"];
        }
        
        self.iconView = [[UIImageView alloc] initWithImage:icon];
        self.iconView.backgroundColor = [UIColor clearColor];
        self.iconView.userInteractionEnabled = NO;
        
        [self.backgroundView insertSubview:self.iconView belowSubview:self.highlightOverlayView];
        
        // Then, setup frame of self
        self.frame = CGRectMake(0, 0, BUTTON_HEIGHT, BUTTON_HEIGHT);
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
    self.highlightOverlayView.frame = self.backgroundView.bounds;
    self.iconView.center = CGPointMake(BUTTON_HEIGHT/2, BUTTON_HEIGHT/2);
}

@end
