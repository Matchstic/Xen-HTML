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
#import "XENHPResources.h"

@interface XENHDonationController ()

@end

@implementation XENHDonationController

- (NSString*)plistName {
    return @"Donate";
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
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Xen HTML" message:[XENHResources localisedStringForKey:@"DONATE_ADDRESS_COPIED"] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    
    [controller addAction:okAction];
    
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

@end
