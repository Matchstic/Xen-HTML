//
//  XENHFauxIconsViewController.m
//  
//
//  Created by Matt Clarke on 07/09/2016.
//
//

#import "XENHFauxIconsViewController.h"
#import "XENHResources.h"

@interface CPDistributedMessagingCenter : NSObject
+(CPDistributedMessagingCenter*)centerNamed:(NSString*)serverName;
-(BOOL)sendMessageName:(NSString*)name userInfo:(NSDictionary*)info;
- (id)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info;
@end

// RocketBootstrap
#ifdef __OBJC__
@class CPDistributedMessagingCenter;
void rocketbootstrap_distributedmessagingcenter_apply(CPDistributedMessagingCenter *messaging_center);
#endif

@interface XENHFauxIconsViewController ()
/*@property (nonatomic, strong) CPDistributedMessagingCenter *c;
@property (nonatomic, strong) UIImageView *imageView;*/
@end

@implementation XENHFauxIconsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadView {
    // Startup the RocketBootstrap server
    /*self.c = [CPDistributedMessagingCenter centerNamed:@"com.matchstic.xenhtml.previewsnapshot.listener"];
    
    // Not needed on iOS 6
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/librocketbootstrap.dylib"])
        rocketbootstrap_distributedmessagingcenter_apply(self.c);*/
    
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.userInteractionEnabled = NO;
    
    // Fill up the ui with icons.
    _iconViews = [NSMutableArray array];
    
    // We will have 4 per row, as expected, and have 14 of the buggers.
    CGRect iconFrame = CGRectMake(0, 0, (IS_IPAD ? 72 : 60), (IS_IPAD ? 72 : 60));
    for (int i = 0; i < 14; i++) {
        UIView *icon = [[UIView alloc] initWithFrame:iconFrame];
        icon.layer.cornerRadius = 12.5;
        icon.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
        
        [self.view addSubview:icon];
        
        [_iconViews addObject:icon];
    }
    
    // And add the dock view.
    //_dockView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, (IS_IPAD ? 90 : 80))];
    //_dockView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
    
    //[self.view addSubview:_dockView];
    
    /*self.imageView = [[UIImageView alloc] initWithImage:nil];
    [self.view addSubview:self.imageView];
    
    // Get snapshot from SpringBoard
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSDictionary *reply = [self.c sendMessageAndReceiveReplyName:@"com.matchstic.xenhtml/previewsnapshot" userInfo:nil];
        
        NSData *snapshot = [reply objectForKey:@"snapshot"];
        
        [self.imageView setImage:[UIImage imageWithData:snapshot]];
    });*/
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Layout the icons. First, figure out the left margin, and then the inter-icon margins.
    
    CGFloat dockHeight = (IS_IPAD ? 124 : 96);
    
    CGFloat iconsPerRow = 4;
    
    // If we're on iPad, we get 5 icons per row in landscape, so bear that in mind!
    CGFloat orient = [[UIApplication sharedApplication] statusBarOrientation];
    if (IS_IPAD && (orient == 3 || orient == 4)) {
        iconsPerRow = 5;
    }
    
    CGFloat iconWidth = (IS_IPAD ? 72 : 60);
    CGFloat marginWidth = self.view.bounds.size.width - (iconWidth*iconsPerRow);
    
    // One full margin is used as the left/right insets.
    marginWidth /= iconsPerRow;
    
    CGFloat leftInset = marginWidth/2;
    
    // Now, handle the vertical margins.
    CGFloat iconsPerColumn = 0;
    
    // If iPad, 4 in landscape, 5 in portrait.
    if (IS_IPAD && (orient == 3 || orient == 4)) {
        iconsPerColumn = 4;
    } else if (IS_IPAD) {
        iconsPerColumn = 5;
    } else if (SCREEN_MAX_LENGTH > 568) {
        iconsPerColumn = 6;
    } else if (SCREEN_MAX_LENGTH > 480) {
        iconsPerColumn = 5;
    } else {
        iconsPerColumn = 4;
    }
    
    CGFloat marginHeight = (self.view.bounds.size.height - dockHeight) - (iconWidth*iconsPerColumn);
    marginHeight /= iconsPerColumn;
    
    CGFloat topInset = marginHeight/2 + 20.0;
    
    int row = 0;
    int column = 0;
    
    for (int i = 0; i < _iconViews.count; i++) {
        UIView *icon = [_iconViews objectAtIndex:i];
        
        icon.frame = CGRectMake(leftInset + (column*marginWidth) + (column*iconWidth), topInset + (row*marginHeight) + (row*iconWidth), icon.frame.size.width, icon.frame.size.height);
        
        column++;
        
        if (column == iconsPerRow) {
            column = 0;
            row++;
        }
    }
    
    // Layout dock.
    _dockView.frame = CGRectMake(0, self.view.bounds.size.height - dockHeight, self.view.bounds.size.width, dockHeight);
    
    //self.imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

@end
