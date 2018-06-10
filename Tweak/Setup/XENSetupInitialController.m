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

#import "XENSetupInitialController.h"
#import "XENSetupWindow.h"
#import "XENHSetupLockscreenImportController.h"
#import "XENHResources.h"

@interface XENHSetupInitialController ()

@end

@implementation XENHSetupInitialController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    
    self.centraliser = [[UIView alloc] initWithFrame:CGRectZero];
    self.centraliser.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.centraliser];
    
    self.installComplete = [[UILabel alloc] initWithFrame:CGRectZero];
    self.installComplete.backgroundColor = [UIColor clearColor];
    self.installComplete.text = [XENHResources localisedStringForKey:@"SETUP_INITIAL_TITLE"];
    self.installComplete.textAlignment = NSTextAlignmentCenter;
    self.installComplete.textColor = [UIColor blackColor];
    self.installComplete.font = [UIFont systemFontOfSize:34 weight:UIFontWeightLight];
    self.installComplete.numberOfLines = 0;
    
    [self.centraliser addSubview:self.installComplete];
    
    self.helloText = [[UILabel alloc] initWithFrame:CGRectZero];
    self.helloText.backgroundColor = [UIColor clearColor];
    self.helloText.text = [XENHResources localisedStringForKey:@"SETUP_INITIAL_FOOTER"];
    self.helloText.textAlignment = NSTextAlignmentCenter;
    self.helloText.textColor = [UIColor blackColor];
    self.helloText.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.helloText.numberOfLines = 0;
    
    [self.centraliser addSubview:self.helloText];
    
    self.getStartedButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.getStartedButton setTitle:[XENHResources localisedStringForKey:@"SETUP_INITIAL_BUTTON"] forState:UIControlStateNormal];
    [self.getStartedButton addTarget:self action:@selector(beginButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.getStartedButton.titleLabel.font = [UIFont systemFontOfSize:26];
    
    [self.centraliser addSubview:self.getStartedButton];
}

-(void)viewDidLayoutSubviews {
    // Layout everything
    self.installComplete.frame= CGRectMake(0, 0, self.view.frame.size.width*0.775, 0);
    [self.installComplete sizeToFit];
    self.installComplete.center = CGPointMake(self.view.frame.size.width/2, self.installComplete.frame.size.height/2);
    
    self.helloText.frame = CGRectMake(0, 0, self.view.frame.size.width*0.775, 0);
    [self.helloText sizeToFit];
    self.helloText.center = CGPointMake(self.view.frame.size.width/2, self.installComplete.frame.size.height + self.installComplete.frame.origin.y + self.helloText.frame.size.height/2 + 20);
    
    self.getStartedButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
    self.getStartedButton.center = CGPointMake(self.view.frame.size.width/2, self.helloText.frame.size.height + self.helloText.frame.origin.y + self.getStartedButton.frame.size.height/2 + 40);
    
    self.centraliser.frame = CGRectMake(0, 0, self.view.frame.size.width, self.getStartedButton.frame.size.height + self.getStartedButton.frame.origin.y);
    self.centraliser.center = self.view.center;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Callbacks

-(void)beginButtonWasPressed:(id)sender {
    XENHSetupLockscreenImportController *nextController = [[XENHSetupLockscreenImportController alloc] initWithStyle:UITableViewStyleGrouped];
    
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    [[self navigationController] pushViewController:nextController animated:YES];
    
    [[XENHSetupWindow sharedInstance] addSubview:[[XENHSetupWindow sharedInstance] bar]];
}

@end
