//
//  MGTwitterEngineDemoViewController.m
//  MGTwitterEngineDemo
//
//  Created by Aral Balkan on 28/02/2010.
//  Copyright Naklab 2010. All rights reserved.
//


#import "MGTwitterEngineDemoViewController.h"
#import "MGTwitterEngine.h"
#import "SFHFKeychainUtils.h"
#import "UIAlertView+Helper.h"
#import "OAToken.h"

@implementation MGTwitterEngineDemoViewController

@synthesize usernameTextField, passwordTextField, twitterEngine, sendTweetButton;

#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload {
	self.usernameTextField = nil;
	self.passwordTextField = nil;
	self.sendTweetButton = nil;
}


- (void)dealloc {
	
	[usernameTextField release];
	[passwordTextField release];
	[sendTweetButton release];
	[twitterEngine release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Life-cycle methods

-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		// Custom initialization.
		self.twitterEngine = [[[MGTwitterEngine alloc] initWithDelegate:self] autorelease];
	}
	return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
		

	// Sanity check
	if ([kOAuthConsumerKey isEqualToString:@""] || [kOAuthConsumerSecret isEqualToString:@""])
	{
		NSString *message = @"Please add your Consumer Key and Consumer Secret from http://twitter.com/oauth_clients/details/<your app id> to the XAuthTwitterEngineDemoViewController.h before running the app. Thank you!";
		UIAlertViewQuick(@"Missing oAuth details", message, @"OK");
	}
	else 
	{
		[self.twitterEngine setConsumerKey:kOAuthConsumerKey secret:kOAuthConsumerSecret];
	}
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if ([userDefaults boolForKey:kHaveCachedToken])
	{
		// Get the cached (saved) token.
		NSString *tokenKey = [userDefaults objectForKey:kTokenKey];

		NSError *error = nil;
		NSString *tokenSecret = [SFHFKeychainUtils getPasswordForUsername:tokenKey andServiceName:kMGTwitterEngineDemoServiceName sharedKeychainAccessGroupName:nil error:&error];
		if (error)
		{
			//
			// Boo! Error loading oAuth token from keychain. :(
			//
			NSString *errorMessage = [NSString stringWithFormat:@"Error loading token", @"I couldn't load the oAuth token from the keychain. %d: %@", [error code], [error localizedDescription]];
			UIAlertViewQuick(@"Error loading token", errorMessage, @"OK");
		}
		else 
		{
			//
			// Yay! Loaded oAuth token from keychain. :) 
			//
			OAToken *token = [[OAToken alloc] initWithKey:tokenKey secret:tokenSecret];
			
			self.twitterEngine.accessToken = token;
			
			UIAlertViewQuick(@"Cached xAuth token found!", @"This app was previously authorized for a Twitter account so you can press the second button to send a tweet now.", @"OK");
			self.sendTweetButton.enabled = YES;	
		}		
	}

	// Set initial focus.
	[self.usernameTextField becomeFirstResponder];
}


#pragma mark -
#pragma mark Actions

- (IBAction)xAuthAccessTokenRequestButtonTouchUpInside
{
	NSString *username = self.usernameTextField.text;
	NSString *password = self.passwordTextField.text;
	
	NSLog(@"About to request an xAuth token exchange for username: ]%@[ password: ]%@[.",
		  username, password);
	
	[self.twitterEngine getXAuthAccessTokenForUsername:username password:password];
}

- (IBAction)sendTestTweetButtonTouchUpInside
{
	// Adding random number to the tweet to avoid Twitter's 403 "Status is a duplicate" error.
	NSString *tweetText = [NSString stringWithFormat:@"Testing xAuth from the MGTwitterEngineDemo by @aral! %d", arc4random()%144];
	
	NSLog(@"About to send test tweet: \"%@\"", tweetText);
	
	[self.twitterEngine sendUpdate:tweetText];
}

#pragma mark -
#pragma mark MGTwitterEngineDelegate methods

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
	// Since we're just sending a tweet in this example, we can assume that's the tweet that's returned
	// and use this as a success handler.
	UIAlertViewQuick(@"Tweet sent!", @"The tweet was successfully sent. Everything works!", @"OK");
}

- (void)accessTokenReceived:(OAToken *)token forRequest:(NSString *)connectionIdentifier
{
	//
	// We've got an oAuth access token from Twitter. Let's save it.
	//
	NSString *tokenKey = token.key;
	NSString *tokenSecret = token.secret;
	
	// Save the token securely in the keychain. 
	// (Note: this SFHFKeychainUtils method doesn't return a value.)
	NSError *error = nil;
	[SFHFKeychainUtils storeUsername:tokenKey andPassword:tokenSecret forServiceName:kMGTwitterEngineDemoServiceName sharedKeychainAccessGroupName:nil updateExisting:YES error:&error];
	if (error)
	{
		NSString *errorMessage = [NSString stringWithFormat:@"Error saving token", @"I couldn't save the oAuth token to the keychain. %d: %@", [error code], [error localizedDescription]];
		UIAlertViewQuick(@"Error saving token", errorMessage, @"OK");
	}
	else 
	{
		// Save the token key and flag that we have a cached token.
		NSLog(@"Got the oAuth token and about to save it.");
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:tokenKey forKey:kTokenKey];
		[userDefaults setBool:YES forKey:kHaveCachedToken];
		[userDefaults synchronize];
	}

	// Set the access token on the twitter engine
	// (Why doesn't MGTwitterEngine do this automatically?)
	self.twitterEngine.accessToken = token;
	
	// Enable the send tweet button.
	self.sendTweetButton.enabled = YES;
	
}

- (void)requestSucceeded:(NSString *)connectionIdentifier
{
	NSLog(@"Twitter request succeeded: %@", connectionIdentifier);
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
	NSLog(@"Twitter request failed: %@ with error:%@", connectionIdentifier, error);
		
	if ([[error domain] isEqualToString: @"HTTP"])
	{
		switch ([error code]) {
				
			case 401:
			{
				// Unauthorized. The user's credentials failed to verify.
				UIAlertViewQuick(@"Oops!", @"Your username and password could not be verified. Double check that you entered them correctly and try again.", @"OK");	
				break;				
			}
				
			case 502:
			{
				// Bad gateway: twitter is down or being upgraded.
				UIAlertViewQuick(@"Fail whale!", @"Looks like Twitter is down or being updated. Please wait a few seconds and try again.", @"OK");	
				break;				
			}
				
			case 503:
			{
				// Service unavailable
				UIAlertViewQuick(@"Hold your taps!", @"Looks like Twitter is overloaded. Please wait a few seconds and try again.", @"OK");	
				break;								
			}
				
			default:
			{
				NSString *errorMessage = [[NSString alloc] initWithFormat: @"%d %@", [error	code], [error localizedDescription]];
				UIAlertViewQuick(@"Twitter error!", errorMessage, @"OK");	
				[errorMessage release];
				break;				
			}
		}
		
	}
	else 
	{
		switch ([error code]) {
				
			case -1009:
			{
				UIAlertViewQuick(@"You're offline!", @"Sorry, it looks like you lost your Internet connection. Please reconnect and try again.", @"OK");					
				break;				
			}
				
			case -1200:
			{
				UIAlertViewQuick(@"Secure connection failed", @"I couldn't connect to Twitter. This is most likely a temporary issue, please try again.", @"OK");					
				break;								
			}
				
			default:
			{				
				NSString *errorMessage = [[NSString alloc] initWithFormat:@"%@ xx %d: %@", [error domain], [error code], [error localizedDescription]];
				UIAlertViewQuick(@"Network Error!", errorMessage , @"OK");
				[errorMessage release];
			}
		}
	}
	
}


@end
