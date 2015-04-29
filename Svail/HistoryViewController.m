//
//  HistoryViewController.m
//  Svail
//
//  Created by zhenduo zhu on 4/28/15.
//  Copyright (c) 2015 Svail. All rights reserved.
//

#import "HistoryViewController.h"
#import "PostHistoryViewController.h"
#import "ReservationHistoryViewController.h"

@interface HistoryViewController ()

@property (nonatomic) PostHistoryViewController *postHistoryVC;
@property (nonatomic) ReservationHistoryViewController *reservationHistoryVC;
@property (nonatomic) UIViewController *currentVC;

@end

@implementation HistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.postHistoryVC = self.childViewControllers.lastObject;
    self.reservationHistoryVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ReservationHistoryVC"];
    
    self.currentVC = self.postHistoryVC;
}

- (IBAction)onSegmentsTapped:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self addChildViewController:self.postHistoryVC];
            [self moveToNewController:self.postHistoryVC];
            break;
        case 1:
            [self addChildViewController:self.reservationHistoryVC];
            [self moveToNewController:self.reservationHistoryVC];
            break;
        default:
            break;
    }
    
}

-(void)moveToNewController:(UIViewController *)newController
{
    [self.currentVC willMoveToParentViewController:nil];
    [self transitionFromViewController:self.currentVC toViewController:newController duration:0.6 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil
                            completion:^(BOOL finished) {
                                [self.currentVC removeFromParentViewController];
                                [newController didMoveToParentViewController:self];
                                self.currentVC = newController;
                            }];
}

@end
