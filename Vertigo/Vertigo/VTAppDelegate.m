//
//  AppDelegate.m
//  Vertigo
//
//  Created by Evan Long on 1/6/17.
//
//

#import "VTAppDelegate.h"

#import "VTMainViewController.h"

@interface VTAppDelegate ()

@end

@implementation VTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    VTMainViewController *mainVC = [[VTMainViewController alloc] init];
    self.window.rootViewController = mainVC;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
