//
//  XENHWallpaperViewController.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import "XENHWallpaperViewController.h"
#import "XENHResources.h"
#import <objc/runtime.h>

/* Internal headers */
@interface _UILegibilitySettings : NSObject
@property (nonatomic, retain) UIColor *contentColor;
@property (nonatomic) CGFloat imageOutset;
@property (nonatomic) CGFloat minFillHeight;
@property (nonatomic, retain) UIColor *primaryColor;
@property (nonatomic, retain) UIColor *secondaryColor;
@property (nonatomic) CGFloat shadowAlpha;
@property (nonatomic, retain) UIColor *shadowColor;
@property (nonatomic, copy) NSString *shadowCompositingFilterName;
@property (nonatomic) CGFloat shadowRadius;
@property (nonatomic) int style;
- (id)initWithContentColor:(id)arg1 contrast:(double)arg2;
@end

@interface SBSUIWallpaperPreviewViewController : UIViewController
@property (nonatomic, readonly, retain) _UILegibilitySettings *legibilitySettings;
- (id)initWithWallpaperVariant:(int)arg1;
- (id)_wallpaperView;
@end

@interface SBFScrollableStaticWallpaperView : UIView
- (void)setCropRect:(struct CGRect)arg1 zoomScale:(float)arg2;
-(id)_scrollView;
@end

@interface XENHWallpaperViewController ()
@property (nonatomic, strong) SBSUIWallpaperPreviewViewController *previewController;
@end

@implementation XENHWallpaperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)initWithVariant:(int)wallpaperVariant {
    self = [super init];
    
    if (self) {
        // Doesn't break the status bar!
        self.previewController = [[objc_getClass("SBSUIWallpaperPreviewViewController") alloc] initWithWallpaperVariant:wallpaperVariant];
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIView *wallpaperView = [self.previewController _wallpaperView];
    wallpaperView.clipsToBounds = YES;
    wallpaperView.userInteractionEnabled = NO;
    wallpaperView.opaque = YES;
    
    [self.view addSubview:wallpaperView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIView *wallpaperView = [self.previewController _wallpaperView];
    if ([wallpaperView isKindOfClass:[objc_getClass("SBFScrollableStaticWallpaperView") class]]) {
        // Get the scroll view.
        UIScrollView *scrollView = [(SBFScrollableStaticWallpaperView*)wallpaperView _scrollView];
        
        // Sort out the content offset
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0)];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIView *wallpaperView = [self.previewController _wallpaperView];
    wallpaperView.frame = self.view.bounds;
    
    // Sort out weird bits if needed for oversized/undersized wallpapers
    if ([wallpaperView isKindOfClass:[objc_getClass("SBFScrollableStaticWallpaperView") class]]) {
        // Get the scroll view.
        UIScrollView *scrollView = [(SBFScrollableStaticWallpaperView*)wallpaperView _scrollView];
        
        // Sort out the content offset
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0)];
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

-(BOOL)isWallpaperImageDark {
    _UILegibilitySettings *settings = self.previewController.legibilitySettings;
    
    UIColor *colour = settings.primaryColor;
    
    CGFloat red, blue, green, alpha;
    
    [colour getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CGFloat brightness = red * 0.3 + green * 0.59 + blue * 0.11;
    
    return brightness < 0.5;
}

- (void)cacheWallpaperImageToFilesystem {
    // Render to img file.
    UIImage *wallpaperImage = [self _imageWithView:[self.previewController _wallpaperView]];
    [UIImagePNGRepresentation(wallpaperImage) writeToFile:@"/var/mobile/Library/Caches/com.apple.Preferences/xen_wallpaperCache.png" atomically:YES];
}

-(UIImage *)_imageWithView:(UIView *)view {
    [view setNeedsDisplay];
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

-(UIView*)_traverseHierarchyForClass:(Class)cl andView:(UIView*)toTraverse {
    UIView *found = nil;
    
    for (UIView *view in toTraverse.subviews) {
        if (!found) {
            if ([view.class isEqual:cl]) {
                found = view;
                break;
            } else {
                found = [self _traverseHierarchyForClass:cl andView:view];
            }
        } else {
            break;
        }
    }
    
    return found;
}

@end
