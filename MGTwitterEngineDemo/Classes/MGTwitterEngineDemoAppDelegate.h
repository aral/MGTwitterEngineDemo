//
//  MGTwitterEngineDemoAppDelegate.h
//  MGTwitterEngineDemo
//
//  Created by Aral Balkan on 28/02/2010.
//  Copyright Naklab 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MGTwitterEngineDemoViewController;

@interface MGTwitterEngineDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MGTwitterEngineDemoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MGTwitterEngineDemoViewController *viewController;

@end

