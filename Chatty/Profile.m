//
//  Profile.m
//  Chatty
//
//  Created by Omar Thanawalla on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Profile.h"
#import "profileCustomCell.h"
#import "PendingRequestCell.h"

#import "FollowingUser.h"

#import "KeychainItemWrapper.h"
//import AFNetworking
#import "AFNetworking.h"
#import "AFChattyAPIClient.h"


@implementation Profile

@synthesize currentView;
@synthesize follows, follows2;
@synthesize firstName,lastName,userName,Bio;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.currentView = 0;
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self refresh];
      // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anyAction:) name:@"editProfile" object:nil];
}

-(void)anyAction:(NSNotification *)anote
{
    NSLog(@"anyAction method fired. presumably from editProfile button being hit");
    [self performSegueWithIdentifier:@"editProfileModal" sender:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //download user data
    [self downloadUserInfo];
}

-(void) downloadUserInfo
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ChattyAppLoginData" accessGroup:nil];
    NSString * email = [keychain objectForKey:(__bridge id)kSecAttrAccount];
    NSString * password = [keychain objectForKey:(__bridge id)kSecValueData];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            email, @"email",
                            password, @"password",
                            nil];
    [[AFChattyAPIClient sharedClient] getPath:@"/updateUserInfo/" parameters:params
     //if login works, log a message to the console
                                      success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         //NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         NSLog(@"Response: %@", responseObject);
         //rmr: responseObject is an array where each element is a diciontary
         //set the instance variables and call reload table
         NSDictionary *userJSON = responseObject;
         self.firstName = [userJSON objectForKey:@"first_name"];
         self.lastName = [userJSON objectForKey:@"last_name"];
         self.userName = [userJSON objectForKey:@"userName"];
         self.Bio = [userJSON objectForKey:@"Bio"];
         [self.tableView reloadData];
     }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error from postPath: %@",[error localizedDescription]);
         //else you cant connect, therefore push modalview login onto the stack
     }
     ];
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // profile segment
    if (self.currentView == 0) {
        return 2;
    }
    else //other segmented control
    {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.currentView == 0) {
        if(section == 0)
        {
            return 1;
        }
        else
        {
            return [follows count];
        }
    }
    //
    else
    {
        return [follows2 count];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *CellIdentifier = @"Cell";
   
    //profile SEGMENT
    if (self.currentView == 0)
    {
                    //configure User SECTION
                    if (indexPath.section == 0) {

                        static NSString *CellIdentifier = @"CellIdentifier";
                        static BOOL nibsRegistered = NO;
                        if(!nibsRegistered)
                        {
                            UINib *nib = [UINib nibWithNibName: @"profileCustomCell" bundle:nil];
                            [tableView registerNib:nib forCellReuseIdentifier:CellIdentifier];
                            nibsRegistered = YES;
                        }
                        
                        profileCustomCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                        
                        cell.NameText.text = self.firstName;
                        cell.userName.text = self.userName;
                        cell.BioText.text = self.Bio;
                        [cell.BioText sizeThatFits:CGSizeMake(40, 196)];
                        
                        //this prevents the cell from being hightlighted but still lets me hit the edit profile UIButton
                        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                        return cell;
                    }
                    else // you are in the pendingRequestsSection
                    {
                        NSLog(@"This is section 1");
                        static NSString *CellIdentifier = @"PendingCell";
                        static BOOL nibsRegistered = NO;
                        if(!nibsRegistered)
                        {
                            UINib *nib = [UINib nibWithNibName: @"PendingRequestCell" bundle:nil];
                            [tableView registerNib:nib forCellReuseIdentifier:CellIdentifier];
                            nibsRegistered = YES;
                        }
                        
                        PendingRequestCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                        
                        NSDictionary *user = [follows objectAtIndex:indexPath.row];
                        
                        //set UIImage with link to Profile Pic
                        
                        
                        cell.fullName.text = [user objectForKey:@"fullName"];
                        //reset the labelFrame because the cell could be dequed
                        CGRect labelFrame = CGRectMake(62.0f, 27.0f, 166.0f, 34.0f);
                        cell.bio.frame = labelFrame;
                        cell.bio.text = [user objectForKey:@"bio"];
                        cell.bio.numberOfLines = 0;
                        [cell.bio sizeToFit];
                        
                        cell.userName.text = [user objectForKey:@"userName"];
                        cell.userID = [user objectForKey:@"userID"];
                        cell.profilePic = [user objectForKey:@"pictureURL"];
                        UIImage *btnImage = [UIImage imageNamed:@"PENDING_Stamp1.png"];
                        [cell.cnfmButton setImage:btnImage forState:UIControlStateNormal];
                        
                        
                        
                        
                        
                        //this prevents the cell from being hightlighted but still lets me hit the edit profile UIButton
                        [tableView setAllowsSelection:NO];
                        return cell;
                    }
        
    }
    //Following Section
    else{
        
        NSLog(@"This is section 1");
        static NSString *CellIdentifier = @"followingUser";
        static BOOL nibsRegistered = NO;
        if(!nibsRegistered)
        {
            UINib *nib = [UINib nibWithNibName: @"FollowingUser" bundle:nil];
            [tableView registerNib:nib forCellReuseIdentifier:CellIdentifier];
            nibsRegistered = YES;
        }
        
        FollowingUser * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        //reset the picture on the unfollow button because the cell could be dequeued
        UIImage *btnImage = [UIImage imageNamed:@"unfollow.jpeg"];
        [cell.unfollowButton setImage:btnImage forState:UIControlStateNormal];
        
        NSDictionary *user = [follows2 objectAtIndex:indexPath.row];
        cell.fullName.text = [user objectForKey:@"fullName"];
        
        //set profile pic
        NSString *picURL = [user objectForKey: @"profilePic"];
        [cell.profilePic setImageWithURL:[NSURL URLWithString:picURL]];
        

        
        //reset the labelFrame because the cell could be dequed
        CGRect labelFrame = CGRectMake(63.0f, 29.0f, 150.0f, 21.0f);
        cell.bio.frame = labelFrame;
        cell.bio.text = [user objectForKey:@"bio"];
        cell.bio.numberOfLines = 0;
        [cell.bio sizeToFit];
        
        cell.userName.text = [user objectForKey:@"userName"];
        cell.userID = [user objectForKey:@"userID"];
        //this prevents the cell from being hightlighted but still lets me hit the edit profile UIButton
        [tableView setAllowsSelection:NO];
        return cell;
    }
    


}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)toggleView:(id)sender {
    
    if([sender selectedSegmentIndex] == 1)
    {
        self.currentView = 1;
        [self.tableView reloadData]; 
    } else {
        self.currentView = 0;
        [self.tableView reloadData]; 
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(currentView == 0)
    {
        if (indexPath.section == 0)
        {
            return 120.0;
        }
        else
        {
        return 90.0;
        }
    }
    else
    {
        return 90.0;
    }
} 

-(IBAction) logout
{
    //i just had the modal view for login pop up, this way the only way to get back in is to successfully login instead of loggin out
    
//    NSLog(@"logout function called");
//    //clear key chain
//    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ChattyAppLoginData" accessGroup:nil];
//    [keychain setObject:@"" forKey:(__bridge id) kSecAttrAccount];
//    [keychain setObject:@"" forKey:(__bridge id)kSecValueData];
//    
//    //send it to the community tab 
//    [self.tabBarController setSelectedIndex:0];
    
}

-(IBAction)refresh
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ChattyAppLoginData" accessGroup:nil];
    NSString * email = [keychain objectForKey:(__bridge id)kSecAttrAccount];
    NSString * password = [keychain objectForKey:(__bridge id)kSecValueData];
    
    if (currentView == 0)
    {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            email, @"email",
                            password, @"password",
                            nil];

    [[AFChattyAPIClient sharedClient] getPath:@"/follower/" parameters:params
     //if login works, log a message to the console
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          //NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                                          NSLog(@"Response: %@", responseObject);
                                   
                                          follows = responseObject;
                                          [self.tableView reloadData];
                                          
                                          
                                      }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          NSLog(@"Error from postPath: %@",[error localizedDescription]);
                                          //else you cant connect, therefore push modalview login onto the stack
                                      }];

    }
    else // your in following segment
    {
        NSLog(@"youve pushed the refresh button while on following segment");
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                email, @"email",
                                password, @"password",
                                nil];
        
        [[AFChattyAPIClient sharedClient] getPath:@"/follow/" parameters:params
         //if login works, log a message to the console
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              //NSString *text = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                                              NSLog(@"Response: %@", responseObject);
                                              
                                              follows2 = responseObject;
                                              [self.tableView reloadData];
                                              
                                              
                                          }
                                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              NSLog(@"Error from postPath: %@",[error localizedDescription]);
                                              //else you cant connect, therefore push modalview login onto the stack
                                          }];
    }
}

@end
