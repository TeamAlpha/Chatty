//
//  composeMessage.m
//  Chatty
//
//  Created by Omar Thanawalla on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "composeConversation.h"
#import "KeychainItemWrapper.h"
#import "AFNetworking.h"
#import "AFChattyAPIClient.h"
#import "autoCompleteEngine.h"

@implementation composeConversation
@synthesize myTextView, characterCount;
@synthesize autoCompleteObject;
@synthesize viewOn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    //force the keyboard to open
    [myTextView becomeFirstResponder];
    myTextView.delegate = self;
    autoCompleteObject = [[autoCompleteEngine alloc] init]; //ready this object to be viewed on and off
    viewOn = NO;
    myTextView.scrollEnabled = YES; //Im not sure if this worked
}

-(void)viewDidDisappear:(BOOL)animated
{
    viewOn = NO;
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)cancelButton
{
    [self.presentingViewController dismissModalViewControllerAnimated:YES];   
}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView //calls this method because "becomeFirstResponder"
{
    //Simulate placeholder text
    myTextView.text = @"Direct your message to someone using the @ sign";
    myTextView.textColor = [UIColor lightGrayColor];
    myTextView.selectedRange = NSMakeRange(0, 0);
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView //calls this method when you put text in it
{
    //Clear placeholder
    if(myTextView.textColor == [UIColor lightGrayColor])
       {
           myTextView.textColor= [UIColor blackColor];
           NSRange clearMe = NSMakeRange(1, myTextView.text.length -1);     //grab the front rest of the string
           myTextView.text = [myTextView.text stringByReplacingCharactersInRange: clearMe withString:@""]; //clear that front rest
       }
    //counter
    int count = 140 - [myTextView.text length];
    [characterCount setTitle:[NSString stringWithFormat:@"%d", count]];
    
    
    
    int cursorPostion = [myTextView selectedRange].location;
    [self callAutoComplete:cursorPostion];
    
}

-(void) callAutoComplete:(int) cursorPosition   //handles the autoCompletion of @sign
{
  
        //dont do anything because theres no letter to the left
        if(cursorPosition == 0) 
        {
            //Corner Case: If user hits @ sign then backspaces leaving the cursor at position 0
            for (UIView *subView in self.view.subviews)
            {
                if (subView.tag == 1)               //autoCompleteObject tag is 1
                {
                    [subView removeFromSuperview];
                }
            }
            //Flip the viewOn "switch" to off
            viewOn = NO;
            
            //Return UITextView back to normal dimensions
            CGRect temp2 = myTextView.frame;
            temp2.size.height = 158;
            myTextView.frame = temp2;
            
            return;
        }
        //Begin Checking if we should be Turning on Autocomplete
        NSLog(@"cursorPostion %i",cursorPosition);
        while(cursorPosition != 0)
        {
                    //NSLog(@"the letter at cursor space is %c", [myTextView.text characterAtIndex:cursorPosition-1]);
                    char currentLetter = [myTextView.text characterAtIndex:cursorPosition-1];
                    if(currentLetter == ' ')
                    {
                        NSLog(@"We have a space to the left of the word.");
                        if (viewOn == YES)
                        {
                            //remove the subview from screen
                            for (UIView *subView in self.view.subviews)
                            {
                                if (subView.tag == 1)               //autoCompleteObject tag is 1
                                {
                                    [subView removeFromSuperview];
                                }
                            }
                            //Flip the viewOn "switch" to off
                            viewOn = NO;
                            
                            //Return UITextView back to normal dimensions
                            CGRect temp2 = myTextView.frame;
                            temp2.size.height = 158;
                            myTextView.frame = temp2;
                        }
                        return;
                    }
                    if(currentLetter == '@')
                    {
                        NSLog(@"we have an @  sign to the left of the word");
                        
                        //display autocompletion feature
                        if(viewOn == NO)
                        {
                            //Display a table view on screen
                            autoCompleteObject.view.tag = 1;
                            //Change the viewControlers frame
                            CGRect temp = autoCompleteObject.view.frame;
                            temp.origin.y = 85;
                            autoCompleteObject.view.frame = temp;
                            
                            [self.view addSubview:autoCompleteObject.view];
                            //Flip viewOn "switch" to on
                            viewOn = YES;
                            
                            //Shorten the UITextView Box
                            CGRect temp2 = myTextView.frame;
                            temp2.size.height = 40;
                            myTextView.frame = temp2;
                            //Scroll to the bottom of the UITextView Box because we assume curosor is as bottom of textview
                            NSRange myRange = NSMakeRange(myTextView.text.length-1 ,myTextView.text.length);
                            [myTextView scrollRangeToVisible:myRange];
                        }
                        //constantly update the viewcontroller with the new text
                        
                        return;
                    }
                    cursorPosition--;
        }
}

-(IBAction)sendButton
{

    //grab the text from textView
    NSString * messageContent = myTextView.text;
    
    if([messageContent rangeOfString:@"@"].location == NSNotFound || (myTextView.textColor ==[UIColor lightGrayColor]) )
    {
        //alert the user that he must direct the conversation towards someone
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"You must direct conversation towards someone with an @ sign to start a new convo."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];

    }
    else if ([myTextView.text length] > 140) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Message must be less than 140 characters"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    else
    {
        
        //submit the text to the server
        //were going to fake it and just add it to the array for the moment
        //grab credentials
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ChattyAppLoginData" accessGroup:nil];
        NSString * email = [keychain objectForKey:(__bridge id)kSecAttrAccount];
        NSString * password = [keychain objectForKey:(__bridge id)kSecValueData];
        
        //try connecting with credentials
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                email, @"email",
                                password, @"password",
                                messageContent, @"message",
                                nil];
        
        // NSURL *url = [NSURL URLWithString:@"http://localhost:3000"];
        // AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        //
        //    [httpClient getPath:@"/my_conversation" parameters:nil
        //     //if login works, log a message to the console
        //                success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //                    NSLog(@"Response: %@", responseObject);
        //                    [self.presentingViewController dismissModalViewControllerAnimated:YES];
        //
        //                }
        //                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //                    NSLog(@"Error from postPath: %@",[error localizedDescription]);
        //                    self.dialogue.text = @"Error in sending. Try again later beautiful.";
        //                    //else you cant connect, therefore push modalview login onto the stack
        //                    //[self performSegueWithIdentifier:@"loggedIn" sender:self];
        //                }];
        //
        //
        [[AFChattyAPIClient sharedClient] postPath:@"/message" parameters:params
         //if login works, log a message to the console
                                           success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                               NSLog(@"Response was good, here it is: %@", responseObject);
                                               [self.presentingViewController dismissModalViewControllerAnimated:YES];
                                               
                                           } 
                                           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                               NSLog(@"Error from postPath: %@",[error localizedDescription]);
                                               //else you cant connect, therefore push modalview login onto the stack
                                           }];
    }
}
@end
