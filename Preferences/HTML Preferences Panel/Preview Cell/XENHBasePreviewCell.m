//
//  XENHBasePreviewCell.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import "XENHBasePreviewCell.h"
#import "XENHPreviewScaledController.h"

@interface XENHBasePreviewCell ()
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, strong) UIView *viewControllersSuperview;
@property (nonatomic, readwrite) CGFloat currentSkew;
@end

@implementation XENHBasePreviewCell

#pragma mark Override this

- (void)didRecieveSettingsChange {
    // nop.
}

- (NSArray*)viewControllersToDisplay {
    UIViewController *controller1 = [[UIViewController alloc] init];
    controller1.view.backgroundColor = [UIColor greenColor];
    
    UIViewController *controller2 = [[UIViewController alloc] init];
    controller2.view.backgroundColor = [UIColor redColor];
    
    UIViewController *controller3 = [[UIViewController alloc] init];
    controller3.view.backgroundColor = [UIColor blueColor];
    
    UIViewController *controller4 = [[UIViewController alloc] init];
    controller4.view.backgroundColor = [UIColor purpleColor];
    
    return @[controller1, controller2, controller3, controller4];
}

- (int)variant {
    return -1;
}

#pragma mark Private

- (instancetype)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        // Setup...
        self.viewControllersSuperview = [[UIView alloc] initWithFrame:CGRectZero];
        self.viewControllersSuperview.backgroundColor = [UIColor clearColor];
        self.viewControllersSuperview.userInteractionEnabled = NO;
        
        [self.contentView addSubview:self.viewControllersSuperview];
        
        self.contentView.clipsToBounds = YES;
        
        NSArray *viewControllers = [self viewControllersToDisplay];
        for (UIViewController *controller in viewControllers) {
            NSLog(@"Controller: %@ bounds: %@ frame: %@", controller, NSStringFromCGRect(controller.view.bounds), NSStringFromCGRect(controller.view.frame));
            controller.view.clipsToBounds = YES;
            [self.viewControllersSuperview addSubview:controller.view];
        }
        
        [self _configureWithViewControllers:viewControllers];
        
        // Update ourself with past saved state
        [self didChangeEnabledState:[XENHResources getPreviewStateForVariant:[self variant]] forVariant:[self variant]];
        [self didChangeSkewPercentage:[XENHResources getPreviewSkewPercentageForVariant:[self variant]] forVariant:[self variant]];
        
        // Register as an observer for changes
        [XENHResources addPreviewObserverForStateChanges:self identifier:[NSString stringWithFormat:@"%d", [self variant]]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:@"com.matchstic.xenhtml/settingschanged" object:nil];
    }
    
    return self;
}

- (void)dealloc {
    // Remove change observer
    [XENHResources removePreviewObserverWithIdentifier:[NSString stringWithFormat:@"%d", [self variant]]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)settingsChanged:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self didRecieveSettingsChange];
    });
}

- (void)didChangeEnabledState:(BOOL)state forVariant:(int)variant {
    if (variant != [self variant])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.viewControllersSuperview.alpha = state ? 1.0 : 0.5;
        [self setNeedsDisplay];
    });
}

- (void)didChangeSkewPercentage:(CGFloat)percent forVariant:(int)variant {
    if (variant != [self variant])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _recievedSkewPercent:percent];
        [self setNeedsDisplay];
    });
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    // Return a custom cell height.
    return 280.f;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.clipsToBounds = YES;
    self.viewControllersSuperview.frame = self.contentView.bounds;
    
    for (UIViewController *controller in self.viewControllers) {
        int index = (int)[self.viewControllers indexOfObject:controller];
        
        controller.view.center = CGPointMake(
                                             [self centroidForIndex:index controllerCount:(int)self.viewControllers.count withWidth:self.bounds.size.width skewPercent:self.currentSkew],
                                             self.contentView.bounds.size.height/2);
        
        if ([controller respondsToSelector:@selector(fitToSize)]) {
            [(XENHPreviewScaledController*)controller fitToSize];
        }
    }
}

- (CGFloat)centroidForIndex:(int)index controllerCount:(int)count withWidth:(CGFloat)width skewPercent:(CGFloat)skew {
    CGFloat centroidPosition = 0.0;
    CGFloat centerpoint = width/2;
    
    CGFloat centerOfArray = ((CGFloat)(count-1))/2.0;
    
    // Split the width into chunks, and move that far away from center relative to the skew.
    CGFloat unitSize = width/((CGFloat)count+0.75);
    unitSize *= skew;
        
    centroidPosition = unitSize * (index - centerOfArray);
    
    return centerpoint + centroidPosition;
}

- (void)_configureWithViewControllers:(NSArray*)viewControllers {
    /*
     * Each view controller is assumed to be the height of the user's display. So, we need to scale them down
     * to fit snugly into our preview cell, with some margin free
     */
    
    self.viewControllers = viewControllers;
    
    // TODO: Anything?
}

- (void)_recievedSkewPercent:(CGFloat)percent {
    self.currentSkew = percent;
    
    /*
     We allow the user to effectively "spin" the view controller stack around 90 (?) degrees
     i.e., from 0 to 85.
     
     Therefore, we find the angle of rotation, and apply that to our view controllers.
     
     The end result is a perspective shift to the controllers giving the impression that they are
     rotated horizontally around a central point in the view.
     
     So, we apply an affine transformation of:
     - Translation relative to centerpoint and relative to the magnitude of the percent
            if to left of array, move more left
            if to right of array, move more right
            if center, no move
     - Scaling down of right edge relative to the magnitude of the angle
     - Compressing width-wide relative to the magnitude of the angle
     */
    
    CGFloat angle = percent * 45.0;
    
    for (UIViewController *controller in self.viewControllers) {
        
        CALayer *layer = controller.view.layer;
        CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
        rotationAndPerspectiveTransform.m34 = 1.0 / -400;
        rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, angle * M_PI / 180.0f, 0.0f, 1.0f, 0.0f);
        
        CGFloat scale = 1.15f;
        if (percent <= 0.15f) {
            scale += (0.15f - percent);
        }
        
        rotationAndPerspectiveTransform = CATransform3DScale(rotationAndPerspectiveTransform, scale, scale, scale);
        layer.transform = rotationAndPerspectiveTransform;
        
        [self setNeedsLayout];
    }
}

@end
