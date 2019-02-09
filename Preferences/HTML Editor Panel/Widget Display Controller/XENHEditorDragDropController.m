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

#import "XENHEditorDragDropController.h"
#import "XENHPResources.h"

@interface XENHEditorDragDropController ()

@property (nonatomic, strong) UILabel *dragAndDropLabel;
@property (nonatomic, strong) UIVisualEffectView *dragAndDropSuperview;

@end

@implementation XENHEditorDragDropController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
    [super loadView];
    
    self.view.userInteractionEnabled = NO;
    
    self.dragAndDropLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    if (IS_IPAD) {
        self.dragAndDropLabel.text = [XENHResources localisedStringForKey:@"WIDGET_EDITOR_DRAGDROP_IPAD"];
        self.dragAndDropLabel.numberOfLines = 0;
        self.dragAndDropLabel.font = [UIFont systemFontOfSize:20];
    } else {
        self.dragAndDropLabel.text = [XENHResources localisedStringForKey:@"WIDGET_EDITOR_DRAGDROP"];
            self.dragAndDropLabel.font = [UIFont systemFontOfSize:16];
    }
    self.dragAndDropLabel.textColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    self.dragAndDropLabel.textAlignment = NSTextAlignmentCenter;
    self.dragAndDropLabel.userInteractionEnabled = NO;
    
    self.dragAndDropSuperview = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.dragAndDropSuperview.layer.cornerRadius = 6.25;
    self.dragAndDropSuperview.layer.masksToBounds = YES;
    self.dragAndDropSuperview.hidden = YES;
    
    [self.dragAndDropSuperview.contentView addSubview:_dragAndDropLabel];
    [self.view addSubview:self.dragAndDropSuperview];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = [XENHResources boundedRectForFont:_dragAndDropLabel.font andText:_dragAndDropLabel.text width:self.view.bounds.size.width*0.8];
    
    self.dragAndDropLabel.frame = CGRectMake(10, 10, rect.size.width, rect.size.height);
    
    self.dragAndDropSuperview.frame = CGRectMake(0, 0, rect.size.width+20, rect.size.height+20);
    self.dragAndDropSuperview.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
}

#pragma mark Actually useful stuff

-(void)_hideDragAndDrop {
    [UIView animateWithDuration:0.3 animations:^{
        self.dragAndDropSuperview.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.dragAndDropSuperview.hidden = YES;
    }];
}

- (void)showDragAndDropHint {
    self.dragAndDropSuperview.alpha = 0.0;
    self.dragAndDropSuperview.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.dragAndDropSuperview.alpha = 1.0;
    }];
    
    [self performSelector:@selector(_hideDragAndDrop) withObject:nil afterDelay:3.0];
}

@end
