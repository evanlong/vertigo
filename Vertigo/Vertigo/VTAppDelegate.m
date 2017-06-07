//
//  AppDelegate.m
//  Vertigo
//
//  Created by Evan Long on 1/6/17.
//
//

#import "VTAppDelegate.h"

#import <HockeySDK/HockeySDK.h>

#import "VTAnalytics.h"
#import "VTMainViewController.h"
#import "VTRootViewController.h"

@interface VTAppDelegate ()

@end

@implementation VTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !DEBUG
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"395411f1ab4040c4946d4e3c63687d5c"];
    // Do some additional configuration if needed here
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#endif

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
#if 0
    VTMainViewController *mainVC = [[VTMainViewController alloc] init];
#else
    VTRootViewController *mainVC = [[VTRootViewController alloc] init];
#endif
    self.window.rootViewController = mainVC;
    [self.window makeKeyAndVisible];
    
    VTAnalyticsTrackEvent(VTAnalyticsAppDidLaunchEvent);
    
    return YES;
}

@end
