//
//  ViewController.h
//  GLModelExample
//
//  Created by Nick Lockwood on 20/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. 
//

#import <UIKit/UIKit.h>
#import "GLModelView.h"

@interface LoadViewController : UIViewController <UIActionSheetDelegate>
{
    NSArray *objFiles;
}

@property (strong, nonatomic) IBOutlet UINavigationBar *LoadNavBar;
@property (strong, nonatomic) IBOutlet GLModelView *LoadModelView;

- (IBAction)selectLoadModel;

@end
