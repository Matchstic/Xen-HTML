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

#import "XENSetupFinalController.h"
#import "XENSetupWindow.h"
#import "XENHResources.h"

@interface XENHSetupFinalController ()

@end

@implementation XENHSetupFinalController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _finishedFauxUI = NO;
    
    self.headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    self.headerLabel.text = [XENHResources localisedStringForKey:@"SETUP_FINAL_TITLE"];
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    self.headerLabel.textColor = [UIColor blackColor];
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightLight];
    
    [self.view addSubview:self.headerLabel];
    
    self.restartText = [[UILabel alloc] initWithFrame:CGRectZero];
    self.restartText.backgroundColor = [UIColor clearColor];
    self.restartText.text = [XENHResources localisedStringForKey:@"SETUP_FINAL_RESTART_TITLE"];
    self.restartText.textAlignment = NSTextAlignmentCenter;
    self.restartText.textColor = [UIColor blackColor];
    self.restartText.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.restartText.numberOfLines = 0;
    self.restartText.hidden = YES;
    
    [self.view addSubview:self.restartText];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.doneButton setTitle:[XENHResources localisedStringForKey:@"SETUP_FINAL_RESTART_BUTTON"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.titleLabel.font = [UIFont systemFontOfSize:26];
    self.doneButton.hidden = YES;
    self.doneButton.alpha = 0.0;
    
    [self.view addSubview:self.doneButton];
    
    CGFloat centraliserWidth = SCREEN_WIDTH*0.8;
    self.tickCentraliser = [[UIView alloc] initWithFrame:CGRectMake(0, 0, centraliserWidth, 220)];
    
    [self.view addSubview:self.tickCentraliser];
    
    self.viewSettings = [[XENHSFinalTickView alloc] initWithFrame:CGRectZero];
    [self.viewSettings setupWithText:[XENHResources localisedStringForKey:@"SETUP_FINAL_APPLYING_SETTINGS"]];
    
    [self.tickCentraliser addSubview:self.viewSettings];
    
    self.viewCoffee = [[XENHSFinalTickView alloc] initWithFrame:CGRectZero];
    [self.viewCoffee setupWithText:[XENHResources localisedStringForKey:@"SETUP_FINAL_COFFEE"]];
    
    [self.tickCentraliser addSubview:self.viewCoffee];
    
    self.viewCleaningUp = [[XENHSFinalTickView alloc] initWithFrame:CGRectZero];
    [self.viewCleaningUp setupWithText:[XENHResources localisedStringForKey:@"SETUP_FINAL_CLEANUP"]];
    
    [self.tickCentraliser addSubview:self.viewCleaningUp];
}

-(void)doneButtonWasPressed:(id)sender {
    [XENHSetupWindow finishSetupMode];
}

/*-(void)reconfigureContentPages {
    //[XENHSetupWindow relayoutXenForSetupFinished];
    [self.viewPages transitionToBegin];
    [self.viewPages performSelector:@selector(transitionToTick) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(drinkingACoffee) withObject:nil afterDelay:1.5];
}*/

-(void)applySettings {
    [self.viewSettings transitionToBegin];
    [self.viewSettings performSelector:@selector(transitionToTick) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(drinkingACoffee) withObject:nil afterDelay:1.0];
}

-(void)drinkingACoffee {
    [self.viewCoffee transitionToBegin];
    [self.viewCoffee performSelector:@selector(transitionToTick) withObject:nil afterDelay:2.0];
    [self performSelector:@selector(cleaningUp) withObject:nil afterDelay:2.5];
}

-(void)cleaningUp {
    [self.viewCleaningUp transitionToBegin];
    [self.viewCleaningUp performSelector:@selector(transitionToTick) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(transitionToWelcome) withObject:nil afterDelay:2.0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //[self.viewPages reset];
    [self.viewSettings reset];
    [self.viewCoffee reset];
    [self.viewCleaningUp reset];
    
    _finishedFauxUI = NO;
    
    CGFloat yOrigin = self.navigationController.navigationBar.frame.size.height + [XENHSetupWindow sharedInstance].bar.frame.size.height;
    self.headerLabel.frame = CGRectMake(0, yOrigin, self.view.frame.size.width, 50);
    self.headerLabel.text = [XENHResources localisedStringForKey:@"SETUP_FINAL_TITLE"];
    
    self.tickCentraliser.hidden = NO;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self applySettings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews {
    CGFloat yOrigin = self.navigationController.navigationBar.frame.size.height + [XENHSetupWindow sharedInstance].bar.frame.size.height;
    
    if (_finishedFauxUI) {
        yOrigin = self.view.frame.size.height/2 - self.headerLabel.frame.size.height - 20;
        
        self.headerLabel.frame = CGRectMake(0, yOrigin, self.view.frame.size.width, self.headerLabel.frame.size.height);
        
        self.restartText.frame = CGRectMake(0, 0, self.view.frame.size.width*0.775, 0);
        [self.restartText sizeToFit];
        self.restartText.frame = CGRectMake((self.view.frame.size.width/2) - (self.restartText.frame.size.width/2), self.headerLabel.frame.origin.y + self.headerLabel.frame.size.height + 20, self.restartText.frame.size.width, self.restartText.frame.size.height);
        
        self.doneButton.frame = CGRectMake(0, self.restartText.frame.origin.y + self.restartText.frame.size.height + 40, self.view.frame.size.width, 30);
    } else {
        CGFloat height = 0.0;
        
        if (SCREEN_MAX_LENGTH < 568) {
            height = 50.0;
        } else if (SCREEN_MAX_LENGTH < 667) {
            height = 75.0;
        } else {
            height = 100.0;
        }
        
        self.headerLabel.frame = CGRectMake(0, yOrigin + height/2.0, self.view.frame.size.width, 50);
        
        CGFloat centraliserWidth = SCREEN_WIDTH*0.8;
        if (IS_IPAD) {
            centraliserWidth = SCREEN_WIDTH*0.4;
        }
        
        CGFloat longestText = 0;
        CGFloat settingsLength = [XENHResources getSizeForText:self.viewSettings.textLabel.text maxWidth:centraliserWidth - 40 font:self.viewSettings.textLabel.font.fontName fontSize:20].width;
        //CGFloat pagesLength = [XENHResources getSizeForText:self.viewPages.textLabel.text maxWidth:centraliserWidth - 40 font:self.viewSettings.textLabel.font.fontName fontSize:20].width;
        CGFloat coffeeLength = [XENHResources getSizeForText:self.viewCoffee.textLabel.text maxWidth:centraliserWidth - 40 font:self.viewSettings.textLabel.font.fontName fontSize:20].width;
        CGFloat cleaningLength = [XENHResources getSizeForText:self.viewCleaningUp.textLabel.text maxWidth:centraliserWidth - 40 font:self.viewSettings.textLabel.font.fontName fontSize:20].width;
        
        if (settingsLength > longestText) {
            longestText = settingsLength;
        }
        
        //if (pagesLength > longestText) {
        //    longestText = pagesLength;
        //}
        
        if (coffeeLength > longestText) {
            longestText = coffeeLength;
        }
        
        if (cleaningLength > longestText) {
            longestText = cleaningLength;
        }
        
        self.tickCentraliser.frame = CGRectMake(0, 0, longestText + 40, 180);
        
        self.tickCentraliser.center = CGPointMake(self.view.frame.size.width/2 + 10, self.view.frame.size.height/2);
        
        // Each view is 40px, gap of 20px.
        self.viewSettings.frame = CGRectMake(0, 0, self.tickCentraliser.frame.size.width, 40);
        //self.viewPages.frame = CGRectMake(0, 60, self.tickCentraliser.frame.size.width, 40);
        self.viewCoffee.frame = CGRectMake(0, 60, self.tickCentraliser.frame.size.width, 40);
        self.viewCleaningUp.frame = CGRectMake(0, 120, self.tickCentraliser.frame.size.width, 40);
    }
}

-(void)transitionToWelcome {
    _finishedFauxUI = YES;
    
    self.doneButton.hidden = NO;
    self.restartText.hidden = NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.headerLabel.alpha = 0.0;
        self.viewSettings.alpha = 0.0;
        //self.viewPages.alpha = 0.0;
        self.viewCoffee.alpha = 0.0;
        self.viewCleaningUp.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.viewSettings.hidden = YES;
        //self.viewPages.hidden = YES;
        self.viewCleaningUp.hidden = YES;
        self.viewCoffee.hidden = YES;
        self.tickCentraliser.hidden = YES;
        
        self.headerLabel.text = [XENHResources localisedStringForKey:@"SETUP_FINAL_TITLE_POST_WORK"];
        [self.headerLabel sizeToFit];
        self.headerLabel.frame = CGRectMake(0, self.view.frame.size.height/2 - self.headerLabel.frame.size.height - 20, self.view.frame.size.width, self.headerLabel.frame.size.height);
    
        self.restartText.frame = CGRectMake(0, 0, self.view.frame.size.width*0.775, 0);
        [self.restartText sizeToFit];
        self.restartText.frame = CGRectMake((self.view.frame.size.width/2) - (self.restartText.frame.size.width/2), self.headerLabel.frame.origin.y + self.headerLabel.frame.size.height + 20, self.restartText.frame.size.width, self.restartText.frame.size.height);
        
        self.doneButton.frame = CGRectMake(0, self.restartText.frame.origin.y + self.restartText.frame.size.height + 40, self.view.frame.size.width, 30);
        
        [UIView animateWithDuration:0.3 animations:^{
            self.headerLabel.alpha = 1.0;
            self.doneButton.alpha = 1.0;
            self.restartText.alpha = 1.0;
        }];
    }];
}

-(void)dealloc {
    [self.headerLabel removeFromSuperview];
    self.headerLabel = nil;
    
    [self.doneButton removeFromSuperview];
    self.doneButton = nil;
}

@end
