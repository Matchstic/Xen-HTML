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

#import "XENHMoreReposController.h"
#import "XENHPResources.h"
#import "XENHMoreReposCell.h"

#define REUSE @"repoCell"

@interface XENHMoreReposController ()
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, strong) UIView *tableOverlayView;
@end

static NSString *listFile;

@implementation XENHMoreReposController

/*-(instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        //[self.tableView registerClass:[BVAvailableTableCell class] forCellReuseIdentifier:REUSE];
    }
    
    return self;
}*/

- (int)tableViewStyle {
    return UITableViewStyleGrouped;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[self navigationItem] setTitle:[XENHResources localisedStringForKey:@"MORE_REPOS_WIDGETS"]];
    
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"MORE_REPOS_REFRESH"] style:UIBarButtonItemStyleDone target:self action:@selector(refreshButtonPressed:)];
    [[self navigationItem] setRightBarButtonItem:refresh];
    
    // Pull data for items from the asscoiated .plist
    [self loadManifestFromServer];
}

-(void)refreshButtonPressed:(id)sender {
    self.tableOverlayView.hidden = NO;
    [self.spinner startAnimating];
    
    [self.view addSubview:self.tableOverlayView];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableOverlayView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self loadManifestFromServer];
    }];
}

-(void)loadManifestFromServer {
    // Setup UI for refreshing.
    [self.spinner startAnimating];
    
    _items = nil;
    [self.table reloadData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        NSString *urlstr = @"http://incendo.ws/private/XenHTML/MoreRepos.plist";
        
        if (urlstr && ![urlstr isEqualToString:@""]) {
            NSArray *manifest = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:urlstr]];
            
            if (!manifest) {
                // TODO: ERROR HANDLING!
                NSLog(@"Something terribly bad has just happened.");
            }
            
            NSMutableArray *mutable = [manifest mutableCopy];
            
            NSUInteger count = [manifest count];
            for (NSUInteger i = 0; i < count; ++i) {
                // Select a random element between i and end of array to swap with.
                int nElements = (int)(count - i);
                int n = (int)((arc4random() % nElements) + i);
                [mutable exchangeObjectAtIndex:i withObjectAtIndex:n];
            }
            
            self->_items = mutable;
            
            [self finishLoadingData];
        }
    });
}

-(void)finishLoadingData {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.table reloadData];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.tableOverlayView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.tableOverlayView.hidden = YES;
        }];
    });
}

-(void)loadView {
    [super loadView];
    
    self.tableOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if (@available(iOS 13.0, *)) {
        self.tableOverlayView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        // Fallback on earlier versions
        self.tableOverlayView.backgroundColor = [UIColor whiteColor];
    }
    
    [self.view addSubview:self.tableOverlayView];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    if (@available(iOS 13.0, *)) {
        self.spinner.color = [UIColor labelColor];
    } else {
        self.spinner.tintColor = [UIColor darkTextColor];
    }
    [self.tableOverlayView addSubview:self.spinner];
    
    self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.loadingLabel.textAlignment = NSTextAlignmentCenter;
    if (@available(iOS 13.0, *)) {
        self.loadingLabel.textColor = [UIColor labelColor];
    } else {
        self.loadingLabel.textColor = [UIColor darkTextColor];
    }
    self.loadingLabel.font = [UIFont systemFontOfSize:18];
    self.loadingLabel.numberOfLines = 0;
    self.loadingLabel.text = [XENHResources localisedStringForKey:@"MORE_REPOS_CONTACTING_SERVER"];
    
    [self.tableOverlayView addSubview:self.loadingLabel];
    
    [self.table registerClass:[XENHMoreReposCell class] forCellReuseIdentifier:REUSE];
}

-(void)viewWillAppear:(BOOL)view {
    [super viewWillAppear:view];
    
    listFile = nil;
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.spinner.frame = CGRectMake(0, 0, 60, 60);
    self.spinner.center = CGPointMake(self.view.center.x, self.view.center.y);
    
    CGRect rect = [XENHResources boundedRectForFont:self.loadingLabel.font andText:self.loadingLabel.text width:self.view.frame.size.width*0.8];
    
    self.loadingLabel.frame = CGRectMake(self.view.frame.size.width*0.1, self.spinner.frame.size.height + self.spinner.frame.origin.y, self.view.frame.size.width*0.8, rect.size.height);
    
    self.tableOverlayView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*)titleForIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row >= _items.count) {
        return @"";
    }
    
    NSDictionary *dict = [_items objectAtIndex:indexPath.row];
    
    return [dict objectForKey:@"name"];
}

-(NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row >= _items.count) {
        return @"";
    }
    
    NSDictionary *dict = [_items objectAtIndex:indexPath.row];
    
    return [dict objectForKey:@"repo"];
}

-(UIImage*)imageForIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row >= _items.count) {
        return nil;
    }
    
    NSDictionary *dict = [_items objectAtIndex:indexPath.row];
    
    NSString *imageURL = @"http://incendo.ws/private/XenHTML";
    imageURL = [imageURL stringByAppendingFormat:@"/Icons/%@.png", [dict objectForKey:@"uniqueid"]];
    
    if (imageURL && ![imageURL isEqualToString:@""]) {
        
        NSURL *url = [NSURL URLWithString:imageURL];
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        return [UIImage imageWithData:data];
    } else return nil;
}

-(BOOL)isInstalledAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row >= _items.count) {
        return NO;
    }
    
    NSDictionary *dict = [_items objectAtIndex:indexPath.row];
    
    NSString *repoAddr = [dict objectForKey:@"repo"];
    
    // Check the .list files for this repo.
    if (!listFile) {
        listFile = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/cydia.list" encoding:NSUTF8StringEncoding error:nil];
    }
    
    if (!listFile) {
        return NO;
    }
    
    if ([listFile rangeOfString:repoAddr].location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Table view data source

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [XENHResources localisedStringForKey:@"MORE_REPOS_TITLE"];
}

- (id)tableView:(UITableView*)arg1 titleForFooterInSection:(NSInteger)arg2 {
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [_items count]; // -1 for title.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSE];
    if (!cell) {
        cell = [[XENHMoreReposCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:REUSE];
    }
    
    // Configure the cell...
    cell.textLabel.text = [self titleForIndexPath:indexPath];
    cell.detailTextLabel.text = [self subtitleForIndexPath:indexPath];
    cell.accessoryType = [self isInstalledAtIndexPath:indexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryDisclosureIndicator;
    
    NSString *imagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Blank%@", [XENHResources imageSuffix]];
    
    cell.imageView.image = [UIImage imageWithContentsOfFile:imagePath];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        UIImage *icon = [self imageForIndexPath:indexPath];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            if (icon) {
                cell.imageView.image = icon;
                cell.imageView.bounds = CGRectMake(0, 0, 50, 50);
            }
        });
    });
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

-(CGFloat)tableView:(UITableView*)arg1 heightForFooterInSection:(NSInteger)arg2 {
    return 0.0;
}

-(CGFloat)tableView:(UITableView*)arg1 heightForHeaderInSection:(NSInteger)arg2 {
    return UITableViewAutomaticDimension;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Open this link in Cydia.
    _selectedRepo = [self subtitleForIndexPath:indexPath];
    BOOL isInstalled = [self isInstalledAtIndexPath:indexPath];
    
    NSString *message = [XENHResources localisedStringForKey:@"MORE_REPOS_ADD_TO_CYDIA"];
    if (isInstalled) {
        message = [XENHResources localisedStringForKey:@"MORE_REPOS_OPEN_IN_CYDIA"];
    }
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Xen HTML" message:[XENHResources localisedStringForKey:@"DONATE_ADDRESS_COPIED"] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *urlPath = [NSString stringWithFormat:@"cydia://url/https://cydia.saurik.com/api/share#?source=%@", _selectedRepo];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlPath]];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"CANCEL"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    
    [controller addAction:okAction];
    [controller addAction:cancelAction];
    
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView*)arg1 canEditRowAtIndexPath:(id)arg2 {
    return NO;
}

- (id)tableView:(UITableView*)arg1 detailTextForHeaderInSection:(int)arg2 {
    return nil;
}

- (void)tableView:(UITableView*)arg1 didEndDisplayingCell:(id)arg2 forRowAtIndexPath:(id)arg3 {
    
}

- (int)tableView:(UITableView*)arg1 titleAlignmentForFooterInSection:(int)arg2 {
    return 0;
}
- (int)tableView:(UITableView*)arg1 titleAlignmentForHeaderInSection:(int)arg2 {
    return 0;
}

- (id)tableView:(UITableView*)arg1 viewForFooterInSection:(NSInteger)arg2 {
    return nil;
}

- (id)tableView:(UITableView*)arg1 viewForHeaderInSection:(NSInteger)arg2 {
    return nil;
}

@end
