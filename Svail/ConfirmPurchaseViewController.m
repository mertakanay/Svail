//
//  ConfirmPurchaseViewController.m
//  Svail
//
//  Created by zhenduo zhu on 4/22/15.
//  Copyright (c) 2015 Svail. All rights reserved.
//

#import "ConfirmPurchaseViewController.h"
#import "PTKView.h"
#import "Stripe+ApplePay.h"
#import <Parse/Parse.h>


@interface ConfirmPurchaseViewController () <PTKViewDelegate, PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic) PTKView *paymentView;
@property NSNumber *amount;
@property NSString *titled;


@end

@implementation ConfirmPurchaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [super viewDidLoad];

    self.amount = @5;
    self.titled = @"Cooking for you";
    //set the navigationbar title to the price.
    self.navigationItem.title = [NSString stringWithFormat:@"Total: $%@", self.serviceToPurchase.price];

    //set the paymentviewform.
    self.paymentView = [[PTKView alloc] initWithFrame:CGRectMake(15,20,290,55)];
    self.paymentView.center = CGPointMake(160, 150) ;
    self.paymentView.delegate = self;
    [self.view addSubview:self.paymentView];

}

//When pay button is tapped - we create a token and make a call to our server to run the cloud code that does the processing of payment.

- (IBAction)onPayButtonTapped:(id)sender
{
    STPCard *card = [[STPCard alloc] init];
    card.number = self.paymentView.card.number;
    card.expMonth = self.paymentView.card.expMonth;
    card.expYear = self.paymentView.card.expYear;
    card.cvc = self.paymentView.card.cvc;

    [[STPAPIClient sharedClient] createTokenWithCard:card
          completion:^(STPToken *token, NSError *error) {

          if (error) {
              NSLog(@"%@",error);

              [[[UIAlertView alloc] initWithTitle:@"Error"
                                                   message:error.localizedDescription                                                                      delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil] show];

          } else {
              NSString *myVal = token.tokenId;
              NSLog(@"%@",token);
              [PFCloud callFunctionInBackground:@"stripeCharge" withParameters:@{@"token":myVal, @"amount":self.serviceToPurchase.price}
                                          block:^(NSString *result, NSError *error) {
                                              if (!error) {
                                                  NSLog(@"from Cloud Code Res: %@",result);

                                                  //adding user to participants

                                                  [self.serviceToPurchase.participants addObject:[User currentUser]];
                                                  [self.serviceToPurchase saveInBackground];
                                                  // Create our Installation query
                                                  PFQuery *pushQuery = [PFInstallation query];
                                                  [pushQuery whereKey:@"deviceType" equalTo:@"ios"];

                                                  // Send push notification to query
                                                  [PFPush sendPushMessageToQueryInBackground:pushQuery 
                                                                                 withMessage:@"Service has been requested"];

                                                  [self paymentSucceeded];

                                                   [self performSegueWithIdentifier:@"toServiceHistoryNavVC" sender:self];

                                              }
                                              else{
                                                  NSLog(@"from Cloud Code: %@",error);
                                                  [self presentError:error];
                                              }

                                          }];
                                        };
                                    }];


}
- (IBAction)purchaseWithApplePayButton:(UIButton *)sender {


    //create a payment request.

    PKPaymentRequest *request = [Stripe
                                 paymentRequestWithMerchantIdentifier:@"merchant.com.Svail.Svail"];

    //TO-DO - NEED TO SET THE TITLE OF SERVICE HERE.
    NSString *label = [NSString stringWithFormat:@"for %@", self.serviceToPurchase.title]; //This text will be displayed in the Apple Pay authentication view after the word "Pay"

    //change the ammount to be displayed to the user of the item he/she is purchasing.
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:self.serviceToPurchase.price]; //Can change to any amount

    request.paymentSummaryItems = @[
                                    [PKPaymentSummaryItem summaryItemWithLabel:label
                                                                        amount:amount]
                                    ];
    //if the request is valid, then present the actionsheet for apple pay.

    if ([Stripe canSubmitPaymentRequest:request]) {
        PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
        auth.delegate = self;

        [self presentViewController:auth animated:YES completion:nil];
    }

}


//delegate method for apple pay that handles payment authorization.

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion {
[[STPAPIClient sharedClient] createTokenWithPayment:payment
                                         completion:^(STPToken *token, NSError *error) {
                                             if (error) {
                                                 completion(PKPaymentAuthorizationStatusFailure);


                                                 return;
                                             }
                                             /*
                                              We'll implement this below in "Sending the token to your server".
                                              Notice that we're passing the completion block through.
                                              See the above comment in didAuthorizePayment to learn why.

                                              */
                                             NSString *someToken = [NSString stringWithFormat:@"%@",token.tokenId];
                                             NSDictionary *chargeParams = @{@"token": someToken, @"amount": self.serviceToPurchase.price};

                                             [PFCloud callFunctionInBackground:@"applePayCharge"
                                                                withParameters:chargeParams
                                                                         block:^(id object, NSError *error) {
                                                                             if (!error) {
                                                                                 NSLog(@"%@", object);

                                                                 completion(PKPaymentAuthorizationStatusSuccess);


                                                                             }

                                                                         }];



                                         }];


}
//Payment Authorization handler.

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {

    /*
     We'll implement this method below in 'Creating a single-use token'.
     Note that we've also been given a block that takes a
     PKPaymentAuthorizationStatus. We'll call this function with either
     PKPaymentAuthorizationStatusSuccess or PKPaymentAuthorizationStatusFailure
     after all of our asynchronous code is finished executing. This is how the
     PKPaymentAuthorizationViewController knows when and how to update its UI.

     */

    //save the participants to the service.
    
    [self.serviceToPurchase.participants addObject:[User currentUser]];
    [self.serviceToPurchase saveInBackground];


    //Create our Installation query
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"deviceType" equalTo:@"ios"];

    // Send push notification to query
    [PFPush sendPushMessageToQueryInBackground:pushQuery
                                   withMessage:@"Service has been requested"];

    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
    //after sending the push notification - segue to the service history vc.

    [self performSegueWithIdentifier:@"toServiceHistoryNavVC" sender:self];

}
//payment authorization vc delegate method - dismisses payment vc.

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)presentError:(NSError *)error {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                      message:[error localizedDescription]
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                            otherButtonTitles:nil];
    [message show];
}
- (void)paymentSucceeded {
    [[[UIAlertView alloc] initWithTitle:@"Success!"
                                message:@"Payment was successful - Thank you!"
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}


@end
