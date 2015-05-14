//
//  UserProfileViewController.m
//  Svail
//
//  Created by Mert Akanay on 4/18/15.
//  Copyright (c) 2015 Svail. All rights reserved.
//

#import "UserProfileViewController.h"
#import "Verification.h"
#import "Report.h"

@interface UserProfileViewController () <UIGestureRecognizerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *fullnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UILabel *occupationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *safetyImageView;

@end

@implementation UserProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    self.view.backgroundColor = [UIColor colorWithRed:240/255.0 green:248/255.0 blue:255/255.0 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor orangeColor]forKey:NSForegroundColorAttributeName];

    self.fullnameLabel.text = self.selectedUser.name;
    self.emailLabel.text = self.selectedUser.username;

    self.phoneLabel.text = self.selectedUser.phoneNumber;
//    self.phoneLabel.userInteractionEnabled = YES;
//    UITapGestureRecognizer *onPhoneNumberTapped = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(callPhoneNumber)];
//    [self.phoneLabel addGestureRecognizer:onPhoneNumberTapped];

    self.stateLabel.text = self.selectedUser.state;
    self.occupationLabel.text = self.selectedUser.occupation;

    PFQuery *providerQuery = [User query];
    [providerQuery includeKey:@"verification"];
    [providerQuery getObjectInBackgroundWithId:self.selectedUser.objectId block:^(PFObject *user, NSError *error)
     {
         if (!error) {
             User *selectedUser = (User *)user;
             if ([[selectedUser.verification objectForKey:@"safetyLevel"] integerValue] >= 5) {
                 self.safetyImageView.hidden = false;
             } else {
                 self.safetyImageView.hidden = true;
             }
         } else {
             UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
             [alert show];
         }
     }];

    [self.selectedUser.profileImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            self.imageView.image = image;
            self.imageView.layer.cornerRadius = self.imageView.frame.size.height / 2;
            self.imageView.layer.masksToBounds = YES;
            self.imageView.layer.borderWidth = 1.5;
            self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
            self.imageView.clipsToBounds = YES;
        }
    }];
}


-(void)viewDidLayoutSubviews
{
    UIButton *reportButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [reportButton setImage:[UIImage imageNamed:@"exclamation1"] forState:UIControlStateNormal];
    [reportButton setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 30, self.safetyImageView.center.y - 10, 20, 20)];
    [reportButton addTarget:self action:@selector(showReportActionSheet) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reportButton];
}

-(void)showReportActionSheet
{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    [actionSheet addButtonWithTitle:@"Report Inappropriate"];
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    
    [actionSheet showInView:self.view];
}


-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        
        Report *report = [Report object];
        report.reporter = [User currentUser];
        report.userReported = self.selectedUser;
        [report handleReportWithCompletion:^(NSError *error) {
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"Your report has been submitted. Thanks!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                alert.tag = 1;
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:error.localizedDescription delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                alert.tag = 2;
                [alert show];
            }
        }];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((alertView.tag == 1 || alertView.tag == 2) && buttonIndex == 0) {
        [self returnToMainTabBarVC];
    }
}

-(void)returnToMainTabBarVC
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *mainTabBarVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"MainTabBarVC"];
    [self presentViewController:mainTabBarVC animated:true completion:nil];
}


-(void)callPhoneNumber
{
    NSString *phoneNumber = self.selectedUser.phoneNumber;
    NSString *phoneString = [NSString stringWithFormat:@"telprompt://%@",phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneString]];
}
- (IBAction)onPhoneButtonPressed:(UIButton *)sender
{

    [self callPhoneNumber];
}

- (IBAction)onDoneButtonPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
