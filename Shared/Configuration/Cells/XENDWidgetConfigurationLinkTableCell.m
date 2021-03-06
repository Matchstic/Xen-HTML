//
//  XENDWidgetConfigurationLinkTableCell.m
//  Xen HTML
//
//  Created by Matt Clarke on 28/02/2021.
//

#import "XENDWidgetConfigurationLinkTableCell.h"

@implementation XENDWidgetConfigurationLinkTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (void)setup {
    NSString *title = self.cell.text;
    NSString *link = [self.cell.properties objectForKey:@"url"];
    
    self.textLabel.text = title;
    self.detailTextLabel.text = link ? link : @"Missing URL";
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

@end
