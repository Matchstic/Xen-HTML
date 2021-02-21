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

#import "XENDWidgetConfigurationColorController.h"
#import "MSColorPicker/MSColorSelectionView.h"

#import "XENHResources.h"
#import "MSColorUtils.h"
#import "MSColorPicker.h"

@interface XENDWidgetConfigurationColorController ()
@property (nonatomic, strong) UISegmentedControl *segmentControl;
@property (nonatomic, strong) MSColorSelectionView *colorSelectionView;
@property (nonatomic, strong) UIView *displayView;
@property (nonatomic, strong) UIView *splitter;
@property (nonatomic, strong) UIColor *internalColour;
@property (nonatomic, strong) XENDWidgetConfigurationCell *cell;
@property (nonatomic, weak) XENDWidgetConfigurationBaseTableCell *initiator;

@property (nonatomic, strong) UITextField *editingTextField;
@end

@implementation XENDWidgetConfigurationColorController

- (instancetype)initWithCell:(XENDWidgetConfigurationCell*)cell initiator:(XENDWidgetConfigurationBaseTableCell *)initiator {
    self = [super init];
    
    if (self) {
        self.cell = cell;
        self.initiator = initiator;
        
        NSString *hexColour = cell.value;
        self.internalColour = MSColorFromHexString(hexColour);
        
        if (!self.internalColour) {
            self.internalColour = [UIColor whiteColor];
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerForKeyboardNotifications];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)loadView {
    // UI comprises of a segmented control, and the selection views
    self.view = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [(UIScrollView*)self.view setContentInset:UIEdgeInsetsZero];
    
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    // Segmented control
    self.segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Spectrum", @"Sliders"]];
    [self.segmentControl addTarget:self action:@selector(segmentControlDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    self.segmentControl.selectedSegmentIndex = 0;
    
    [self.view addSubview:self.segmentControl];
    
    // Selection view
    self.colorSelectionView = [[MSColorSelectionView alloc] initWithFrame:CGRectZero];
    self.colorSelectionView.delegate = self;
    
    // Initial colour
    self.colorSelectionView.color = self.internalColour;
    
    [self.view addSubview:self.colorSelectionView];
    
    self.displayView = [[UIView alloc] initWithFrame:CGRectZero];
    self.displayView.layer.cornerRadius = 7;
    self.displayView.backgroundColor = self.internalColour;
    if (@available(iOS 13.0, *)) {
        self.displayView.layer.borderColor = [UIColor separatorColor].CGColor;
    } else {
        self.displayView.layer.borderColor = [UIColor grayColor].CGColor;
    }
    self.displayView.layer.borderWidth = 1.0;
    
    [self.view addSubview:self.displayView];
    
    self.splitter = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 13.0, *)) {
        self.splitter.backgroundColor = [UIColor separatorColor];
    } else {
        self.splitter.backgroundColor = [UIColor grayColor];
    }
    [self.view addSubview:self.splitter];
}

- (void)segmentControlDidChangeValue:(UISegmentedControl *)segmentedControl {
    [self.colorSelectionView setSelectedIndex:segmentedControl.selectedSegmentIndex animated:YES];
    [self.view endEditing:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Layout views
    CGFloat padding = 16;
    
    CGFloat y = padding + self.navigationController.navigationBar.bounds.size.height;
    CGFloat width = self.view.bounds.size.width - (padding * 2);
    
    self.segmentControl.frame = CGRectMake(padding, y, width, 32);
    y += 32 + padding;
    
    self.displayView.frame = CGRectMake(padding, y, width, 48);
    y += 48 + (padding * 2);
    
    self.splitter.frame = CGRectMake(padding, y, width, 1);
    y += 1 + padding;
    
    self.colorSelectionView.frame = CGRectMake(padding, y, width, MSColorSelectionViewHeight);
    y += MSColorSelectionViewHeight;
    
    [(UIScrollView*)self.view setContentSize:CGSizeMake(self.view.bounds.size.width, y)];
}

#pragma mark - MSColorViewDelegate

- (void)colorView:(id<MSColorView>)colorView didChangeColor:(UIColor *)color {
    // Handle new colour being set
    NSString *hex = MSHexStringFromColor(color);
    [self.cell setValue:hex];
    
    self.displayView.backgroundColor = color;
    [self.initiator update];
}

#pragma mark - Keyboard handling

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(keyboardWasShown:)
            name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
             selector:@selector(keyboardWillBeHidden:)
             name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
             selector:@selector(textFieldDidStartEditing:)
             name:MSColorTextFieldDidStartEditing object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIScrollView *scrollView = (UIScrollView*)self.view;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0,
                                                  0.0,
                                                  kbSize.height,
                                                  0.0);
    
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect rect = [self.editingTextField convertRect:self.editingTextField.bounds toView:scrollView];
    [scrollView scrollRectToVisible:rect animated:YES];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIScrollView *scrollView = (UIScrollView*)self.view;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.bounds.size.height)) {
        [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    
    [scrollView setNeedsLayout];
    [scrollView setNeedsDisplay];
}

- (void)textFieldDidStartEditing:(NSNotification*)notification {
    self.editingTextField = [notification.userInfo objectForKey:@"field"];
}

@end
