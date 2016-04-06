//
//  AppDelegate.m
//  PRTest3
//
//  Created by Tsung-Yu Tsai on 2016/1/27.
//  Copyright © 2016年 Tsung-Yu Tsai. All rights reserved.
//

#import "AppDelegate.h"
#import "ScanViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [NSThread sleepForTimeInterval:2.0];
    // STWirelessLog is very helpful for debugging while your Structure Sensor is plugged in.
    // See SDK documentation for how to start a listener on your computer.
    NSError* error = nil;
    NSString *remoteLogHost = @"192.168.39.6"; //EA
    //NSString *remoteLogHost = @"192.168.0.19"; // home
    [STWirelessLog broadcastLogsToWirelessConsoleAtAddress:remoteLogHost usingPort:4999 error:&error];
    if (error)
        NSLog(@"Oh no! Can't start wireless log: %@", [error localizedDescription]);
    
    UIStoryboard* _storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    self.viewController = [_storyboard instantiateViewControllerWithIdentifier:@"StartViewController"];
    //[_storyboard instantiateInitialViewController];
    self.window.rootViewController = self.viewController;
    
    
    /// set data folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    self.appDataDirectoryPath = [documentsDirectory stringByAppendingPathComponent:@"/ModelFolder"];
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.appDataDirectoryPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:self.appDataDirectoryPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    

    NSLog(@"====> set data folder: %@", self.appDataDirectoryPath);
    
    return YES;

}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)apphahaDidBecomeActive
{
    /*
    UIStoryboard* _storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    self.viewController = [_storyboard instantiateViewControllerWithIdentifier:@"StartViewController"];
    //[_storyboard instantiateInitialViewController];
    self.window.rootViewController = self.viewController;
    */
}

@end
