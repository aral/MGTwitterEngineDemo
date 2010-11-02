//
//  MGTwitterEngineDemoViewController.h
//  MGTwitterEngineDemo
//
//  Created by Aral Balkan on 28/02/2010.
//  Copyright Naklab 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGTwitterEngineDelegate.h"
#import "OAToken.h"

//
// ************************
// IMPORTANT NOTE: 
// ************************
//
// You _must_ ask Twitter to activate xAuth support for your app by emailing them at api@twitter.com
// 
// For more information on xAuth in general, please see Isaiah's Five Things You Didn't Know About XAuth:
// http://yourhead.tumblr.com/post/428643811/five-things-you-didnt-know-about-xauth
//
// ************************
//

#define kOAuthConsumerKey		@""		// Replace these with your consumer key 
#define	kOAuthConsumerSecret	@""		// and consumer secret from 
										// http://twitter.com/oauth_clients/details/<your app id>

#define kTokenKey			@"tokenKey"
#define kHaveCachedToken	@"haveCachedToken"

#define kMGTwitterEngineDemoServiceName		@"MGTwitterEngineDemoService"

@class MGTwitterEngine;

@interface MGTwitterEngineDemoViewController : UIViewController <MGTwitterEngineDelegate> {
	IBOutlet UITextField *usernameTextField;
	IBOutlet UITextField *passwordTextField;
	IBOutlet UIButton *sendTweetButton;
	
	MGTwitterEngine *twitterEngine;
}

@property (nonatomic, retain) UITextField *usernameTextField, *passwordTextField;
@property (nonatomic, retain) UIButton *sendTweetButton;
@property (nonatomic, retain) MGTwitterEngine *twitterEngine;

- (IBAction)xAuthAccessTokenRequestButtonTouchUpInside;
- (IBAction)sendTestTweetButtonTouchUpInside;

@end

