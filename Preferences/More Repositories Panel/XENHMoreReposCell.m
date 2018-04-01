//
//  XENHMoreReposCell.m
//  
//
//  Created by Matt Clarke on 20/09/2016.
//
//

#import "XENHMoreReposCell.h"

@implementation XENHMoreReposCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews {
    self.imageView.frame = CGRectMake(10, 10, 50, 50);
    
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(10, 10, 50, 50);
    self.textLabel.frame = CGRectMake(80, self.textLabel.frame.origin.y, self.contentView.frame.size.width - 80 - self.accessoryView.frame.size.width, self.textLabel.frame.size.height);
    self.detailTextLabel.frame = CGRectMake(80, self.detailTextLabel.frame.origin.y, self.contentView.frame.size.width - 80 - self.accessoryView.frame.size.width, self.detailTextLabel.frame.size.height);
}

@end
