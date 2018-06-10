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

#import "XENHDonationController.h"
#import "XENHResources.h"

@interface XENHDonationController ()

@end

@implementation XENHDonationController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Donate" target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

// From: https://stackoverflow.com/a/47297734
- (NSString*)_fallbackStringForKey:(NSString*)key {
    NSString *fallbackLanguage = @"en";
    NSString *fallbackBundlePath = [[NSBundle mainBundle] pathForResource:fallbackLanguage ofType:@"lproj"];
    NSBundle *fallbackBundle = [NSBundle bundleWithPath:fallbackBundlePath];
    NSString *fallbackString = [fallbackBundle localizedStringForKey:key value:key table:nil];
    
    return fallbackString;
}

-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[self _fallbackStringForKey:[[s objectAtIndex: i] name]] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[self _fallbackStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key]] table:nil] forKey:key];
            }
            [[s objectAtIndex: i] setTitleDictionary: newTitles];
        }
    }
    
    return s;
}

- (void)copyBitcoinLink:(id)sender {
    // Shove the BTC public address onto the clipboard
    // bc1qstlxmkhep037w8cpsqmmks0qh0zmwwhnxgstx3
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = @"bc1qstlxmkhep037w8cpsqmmks0qh0zmwwhnxgstx3";
    
    [self _alertCopied];
}

- (void)copyEthereumLink:(id)sender {
    // Shove the BTC public address onto the clipboard
    // 0xEfEC3E45F5Ae04b7Caf0937086C88dc94c078307
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = @"0xEfEC3E45F5Ae04b7Caf0937086C88dc94c078307";
    
    [self _alertCopied];
}

- (void)copyPayPalLink:(id)sender {
    // Shove the PayPal link onto clipboard
    // matt@incendo.ws
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = @"matt@incendo.ws";
    
    [self _alertCopied];
}

- (void)_alertCopied {
    // Alert the user
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Xen HTML" message:[XENHResources localisedStringForKey:@"DONATE_ADDRESS_COPIED"] delegate:self cancelButtonTitle:[XENHResources localisedStringForKey:@"OK"] otherButtonTitles:nil];
    
    [av show];
}

@end
