//
//  AppDelegate.m
//  Vertigo
//
//  Created by Evan Long on 1/6/17.
//
//

#import "VTAppDelegate.h"

#import "VTMainViewController.h"
#import "VTRootViewController.h"

@interface VTAppDelegate ()

@end

@implementation VTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
#if 0
    VTMainViewController *mainVC = [[VTMainViewController alloc] init];
#else
    VTRootViewController *mainVC = [[VTRootViewController alloc] init];
#endif
    self.window.rootViewController = mainVC;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
