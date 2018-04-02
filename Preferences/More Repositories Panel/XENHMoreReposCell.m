/*
 Copyright (C) 2018  Matt Clarke
 
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
