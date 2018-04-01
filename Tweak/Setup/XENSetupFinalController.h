//
//  XENSetupFinalController.h
//  
//
//  Created by Matt Clarke on 10/07/2016.
//
//

#import <UIKit/UIKit.h>
#import "XENSFinalTickView.h"

@interface XENHSetupFinalController : UIViewController {
    BOOL _finishedFauxUI;
}

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *restartText;
@property (nonatomic, strong) UIButton *doneButton;

// Tick views.
@property (nonatomic, strong) UIView *tickCentraliser;
//@property (nonatomic, strong) XENHSFinalTickView *viewPages;
@property (nonatomic, strong) XENHSFinalTickView *viewSettings;
@property (nonatomic, strong) XENHSFinalTickView *viewCoffee;
@property (nonatomic, strong) XENHSFinalTickView *viewCleaningUp;

@end
