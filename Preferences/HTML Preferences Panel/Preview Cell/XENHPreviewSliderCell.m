//
//  XENHPreviewSliderCell.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 26/01/2018.
//

#import "XENHPreviewSliderCell.h"
#import "XENHResources.h"

@interface XENHPreviewSliderCell ()
@property (nonatomic, readwrite) int variant;

@property (nonatomic, strong) UISlider *slider;
@end

@implementation XENHPreviewSliderCell

- (instancetype)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        // Setup...
        
        self.variant = [[specifier propertyForKey:@"variant"] intValue];
        
        // Add slider with value 1.0 to 0.0
        
        self.slider = [[UISlider alloc] initWithFrame:CGRectZero];
        self.slider.maximumValue = 1.0;
        self.slider.minimumValue = 0.0;
        self.slider.continuous = YES;
        
        // Images
        NSString *skewHighPath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/SkewHigh%@", [XENHResources imageSuffix]];
        NSString *skewLowPath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/SkewLow%@", [XENHResources imageSuffix]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:skewHighPath]) {
            // Oh for crying out loud CoolStar
            skewHighPath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/SkewHigh%@", [XENHResources imageSuffix]];
            skewLowPath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/SkewLow%@", [XENHResources imageSuffix]];
        }
        
        UIImage *skewHigh = [UIImage imageWithContentsOfFile:skewHighPath];
        UIImage *skewLow = [UIImage imageWithContentsOfFile:skewLowPath];
        
        NSLog(@"XenHTML :: IMAGES, HIGH: %@, low: %@", skewHigh, skewLow);
        
        self.slider.maximumValueImage = skewLow;
        self.slider.minimumValueImage = skewHigh;
        
        [self.slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.slider addTarget:self action:@selector(sliderEnded:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
        
        // Set initial value.
        CGFloat skewPercent = [XENHResources getPreviewSkewPercentageForVariant:self.variant];
        [self.slider setValue:skewPercent];
        
        [self.contentView addSubview:self.slider];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.slider.frame = CGRectMake(self.layoutMargins.left, 0, self.contentView.bounds.size.width - self.layoutMargins.left - self.layoutMargins.right, self.contentView.bounds.size.height);
}

- (void)sliderEnded:(UISlider*)sender {
    [XENHResources setPreviewSkewPercentage:sender.value forVariant:self.variant];
}

-(void)sliderChanged:(UISlider*)sender {
    [XENHResources updatePreviewSkewPercentage:sender.value forVariant:self.variant];
}

@end
