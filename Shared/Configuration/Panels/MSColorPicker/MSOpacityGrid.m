//
//  MSOpacityGrid.m
//  Xen HTML
//
//  Created by Matt Clarke on 06/03/2021.
//

#import "MSOpacityGrid.h"

@implementation MSOpacityGrid

- (void)drawRect:(CGRect)rect {
    // Draws a grid effect to represent opacity being zero
    
    UIColor *background = [UIColor colorWithWhite:250.0 / 255.0 alpha:1.0];
    UIColor *item = [UIColor colorWithWhite:218.0 / 255.0 alpha:1.0];
    CGFloat size = 5;
    
    CGFloat columns = ceil(rect.size.width / size);
    CGFloat rows = ceil(rect.size.height / size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Background
    CGContextSetFillColorWithColor(context, background.CGColor);
    CGContextFillRect(context, rect);
    
    // Items
    CGContextSetFillColorWithColor(context, item.CGColor);
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
            // Draw grid item
            BOOL isDark = j % 2 == (i % 2);
            if (!isDark) continue;
            
            CGRect gridRect = CGRectMake(size * j, size * i, size, size);
            CGContextFillRect(context, gridRect);
        }
    }
}

@end
