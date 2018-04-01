//
//  XENHMetadataOptionsController.m
//  
//
//  Created by Matt Clarke on 08/09/2016.
//
//

#import "XENHMetadataOptionsController.h"
#import "XENHResources.h"

@interface XENHMetadataOptionsController ()

@end

@implementation XENHMetadataOptionsController

-(instancetype)initWithOptions:(NSDictionary *)options andPlist:(NSArray *)plist {
    self = [super initForContentSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT)];
    
    if (self) {
        _options = [options mutableCopy];
        _plist = plist;
    }
    
    return self;
}

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [NSMutableArray array];
        
        // TODO: Build specifiers from _plist.
        
        /*
         * Format:
         * name
         * type - switch, edit, select
         * label
         * default
         * options (select only)
         */
        
        for (NSDictionary *item in _plist) {
            NSString *type = [item objectForKey:@"type"];
            NSString *key = [item objectForKey:@"name"];
            NSString *label = [item objectForKey:@"label"];
            id defaultValue = [item objectForKey:@"default"];
            
            NSLog(@"SETTING UP WITH:\ntype %@\nkey %@\nlabel %@\ndefaultValue %@", type, key, label, defaultValue);
            
            // Hold up. We might be seeing some weird usage of the iWidget UI on the part of the modder.
            if (!key || [key isEqualToString:@""]) {
                // Well, okay then.
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:defaultValue
                                                                        target:self
                                                                           set:nil
                                                                           get:nil
                                                                        detail:nil
                                                                          cell:PSStaticTextCell
                                                                          edit:nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                
                [testingSpecs addObject:specifier];
                
                continue;
            }
            
            // Handle from type.
            if ([type isEqualToString:@"switch"]) {
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:label
                                                                        target:self
                                                                           set:@selector(setPreferenceValue:specifier:)
                                                                           get:@selector(readPreferenceValue:)
                                                                        detail:nil
                                                                          cell:PSSwitchCell
                                                                          edit:nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                [specifier setProperty:defaultValue forKey:@"default"];
                [specifier setProperty:key forKey:@"key"];
                
                [testingSpecs addObject:specifier];
            } else if ([type isEqualToString:@"select"]) {
                // Link cell to a selector UI.
                
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:label
                                                                        target:self
                                                                           set:@selector(setPreferenceValue:specifier:)
                                                                           get:@selector(readPreferenceValue:)
                                                                        detail:NSClassFromString(@"PSListItemsController")
                                                                          cell:PSLinkListCell
                                                                          edit:Nil];
                
                [specifier setProperty:@YES forKey:@"enabled"];
                [specifier setProperty:defaultValue forKey:@"default"];
                
                NSMutableArray *values = [NSMutableArray array];
                NSMutableArray *titles = [NSMutableArray array];
                
                NSDictionary *options = [item objectForKey:@"options"];
                for (NSString *key in [options allKeys]) {
                    [titles addObject:key];
                    [values addObject:[options objectForKey:key]];
                }
                
                specifier.values = values;
                specifier.titleDictionary = [NSDictionary dictionaryWithObjects:titles forKeys:specifier.values];
                specifier.shortTitleDictionary = [NSDictionary dictionaryWithObjects:titles forKeys:specifier.values];
                [specifier setProperty:key forKey:@"key"];
                
                [testingSpecs addObject:specifier];
            } else {
                // Just an edit cell, because why not!
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:label
                                                                        target:self
                                                                           set:@selector(setPreferenceValue:specifier:)
                                                                           get:@selector(readPreferenceValue:)
                                                                        detail:nil
                                                                          cell:PSEditTextCell
                                                                          edit:nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                [specifier setProperty:@YES forKey:@"noAutoCorrect"];
                [specifier setProperty:defaultValue forKey:@"default"];
                [specifier setProperty:@0 forKey:@"alignment"];
                [specifier setProperty:key forKey:@"key"];
                
                [testingSpecs addObject:specifier];
            }
        }
        
        _specifiers = testingSpecs;
    }
    
    return _specifiers;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // If this cell has a text edit UI, force right hand alignment.
    for (UIView *view in cell.contentView.subviews) {
        if ([[view class] isSubclassOfClass:[UITextField class]]) {
            UITextField *txt = (UITextField*)view;
            
            // Set right alignment.
            txt.textAlignment = NSTextAlignmentRight;
            
            break;
        }
    }
    
    return cell;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *key = specifier.properties[@"key"];
    
    // Save new setting.
    [_options setObject:value forKey:key];
}

-(id)readPreferenceValue:(PSSpecifier*)spec {
    id value = [_options objectForKey:spec.properties[@"key"]];
    
    if (!value) {
        for (NSDictionary *item in _plist) {
            if ([[item objectForKey:@"name"] isEqualToString:spec.properties[@"key"]]) {
                value = [item objectForKey:@"default"];
                break;
            }
        }
    }
        
    return value;
}

-(void)viewWillAppear:(BOOL)view {
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[XENHResources localisedStringForKey:@"Widget Settings" value:@"Widget Settings"]];
    }
    [super viewWillAppear:view];
}

-(NSDictionary*)currentOptions {
    return _options;
}

@end
