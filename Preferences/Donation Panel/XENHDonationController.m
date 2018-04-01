//
//  XENHDonationController.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 24/02/2018.
//

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

-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[[s objectAtIndex: i] name] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] table:nil] forKey: key];
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
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Xen HTML" message:[XENHResources localisedStringForKey:@"Address was copied to the clipboard!" value:@"Address was copied to the clipboard!"] delegate:self cancelButtonTitle:[XENHResources localisedStringForKey:@"OK" value:@"OK"] otherButtonTitles:nil];
    
    [av show];
}

@end
