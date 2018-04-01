//
//  XENHSupportController.h
//  
//
//  Created by Matt Clarke on 03/04/2016.
//
//

#import <Preferences/PSListController.h>
#import <MessageUI/MessageUI.h>

@interface XENHSupportController : PSListController <MFMailComposeViewControllerDelegate, UIAlertViewDelegate> {
    BOOL _showingRespring;
}

@end
