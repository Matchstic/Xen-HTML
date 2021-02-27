/*
 Copyright (C) 2021 Matt Clarke
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#import "XENDWidgetConfigurationSliderTableCell.h"
#import "XENHResources.h"

@interface XENDWidgetConfigurationSliderTableCell ()
@property (nonatomic, strong) UILabel *currentValueLabel;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *minLabel;
@property (nonatomic, strong) UILabel *maxLabel;
@end

@implementation XENDWidgetConfigurationSliderTableCell

- (void)setup {
    if (!self.currentValueLabel) {
        self.currentValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.currentValueLabel.text = @"";
        self.currentValueLabel.textAlignment = NSTextAlignmentRight;
        self.currentValueLabel.userInteractionEnabled = NO;
        
        if (@available(iOS 13.0, *)) {
            self.currentValueLabel.font = [UIFont monospacedSystemFontOfSize:18 weight:UIFontWeightRegular];
            self.currentValueLabel.textColor = [UIColor secondaryLabelColor];
        } else {
            self.currentValueLabel.textColor = [UIColor grayColor];
        }
        
        self.accessoryView = self.currentValueLabel;
    }
    
    if (!self.slider) {
        self.slider = [[UISlider alloc] initWithFrame:CGRectZero];
        self.slider.continuous = YES;
        [self.slider addTarget:self action:@selector(sliderDidChange:) forControlEvents:UIControlEventValueChanged];
        
        [self.contentView addSubview:self.slider];
    }
    
    if (!self.minLabel) {
        self.minLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.minLabel.font = [UIFont systemFontOfSize:12];
        self.minLabel.textAlignment = NSTextAlignmentLeft;
        self.minLabel.userInteractionEnabled = NO;
        
        if (@available(iOS 13.0, *)) {
            self.minLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
            self.minLabel.textColor = [UIColor tertiaryLabelColor];
        } else {
            self.minLabel.textColor = [UIColor lightGrayColor];
            self.minLabel.font = [UIFont systemFontOfSize:12];
        }
        
        [self.contentView addSubview:self.minLabel];
    }
    
    if (!self.maxLabel) {
        self.maxLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.maxLabel.textAlignment = NSTextAlignmentRight;
        self.maxLabel.userInteractionEnabled = NO;
        
        if (@available(iOS 13.0, *)) {
            self.maxLabel.textColor = [UIColor tertiaryLabelColor];
            self.maxLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
        } else {
            self.maxLabel.textColor = [UIColor lightGrayColor];
            self.maxLabel.font = [UIFont systemFontOfSize:12];
        }
        
        [self.contentView addSubview:self.maxLabel];
    }
    
    // Apply configuration
    NSNumber *currentValue = self.cell.value;
    NSNumber *min = [self.cell.properties objectForKey:@"min"];
    NSNumber *max = [self.cell.properties objectForKey:@"max"];
    
    if (currentValue) {
        self.slider.value = [currentValue floatValue];
        
        if (!min || !max) {
            self.slider.minimumValue = 0.0;
            self.slider.maximumValue = 1.0;
            
            self.textLabel.text = @"Missing min or max";
            self.slider.alpha = 0.5;
            self.slider.userInteractionEnabled = NO;
            
            self.minLabel.text = @"?";
            self.maxLabel.text = @"?";
            self.currentValueLabel.text = @"?";
        } else {
            self.slider.minimumValue = [min floatValue];
            self.slider.maximumValue = [max floatValue];
            self.slider.alpha = 1.0;
            self.slider.userInteractionEnabled = YES;
            
            self.minLabel.text = [NSString stringWithFormat:@"%.2f", min.floatValue];
            self.maxLabel.text = [NSString stringWithFormat:@"%.2f", max.floatValue];
            self.currentValueLabel.text = [NSString stringWithFormat:@"%.2f", currentValue.floatValue];
        }
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = self.textLabel.frame.origin.x;
    CGFloat width = self.bounds.size.width - (padding * 2);
    CGFloat height = 44.0;
    
    // Figure out the accessoryWidth
    [(UILabel*)self.accessoryView sizeToFit];
    CGFloat accessoryWidth = MAX(self.accessoryView.frame.size.width, self.contentView.frame.size.width * 0.5);
    
    // Get min/max label width
    CGRect sliderLabelFrame = [XENHResources boundedRectForFont:self.maxLabel.font andText:self.maxLabel.text width:60];
    CGFloat sliderLabelWidth = sliderLabelFrame.size.width + 12;
    
    // Top row
    self.textLabel.frame = CGRectMake(padding, 0, width - accessoryWidth - padding, height);
    self.accessoryView.frame = CGRectMake(self.bounds.size.width - accessoryWidth - padding, 6, accessoryWidth, height - 12);
    
    // Slider row
    self.minLabel.frame = CGRectMake(padding, height, sliderLabelWidth, height);
    self.slider.frame = CGRectMake(padding + sliderLabelWidth, height, width - (sliderLabelWidth * 2), height);
    self.maxLabel.frame = CGRectMake(self.bounds.size.width - padding - sliderLabelWidth, height, sliderLabelWidth, height);
}

- (void)sliderDidChange:(UISlider*)sender {
    // Save value, and update currentValueLabel
    NSString *value = [NSString stringWithFormat:@"%.2f", sender.value];
    self.currentValueLabel.text = value;
    
    [self.cell setValue:[NSNumber numberWithFloat:sender.value]];
}

@end
