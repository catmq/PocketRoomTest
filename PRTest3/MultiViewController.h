//
//  ViewController.h
//  PRTest3
//
//  Created by Tsung-Yu Tsai on 2016/1/27.
//  Copyright © 2016年 Tsung-Yu Tsai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadViewController.h"
#import "ObjViewController.h"
#import "ViewController.h"
// used for the multiview controller container

@interface MultiViewController : UIViewController

@property (nonatomic) LoadViewController *root;
@property (nonatomic) ObjViewController *overlap;
//@property (nonatomic) ViewController *tmpview;
@property (strong, nonatomic) IBOutlet UIButton *backbutton;
@property (strong, nonatomic) IBOutlet UIButton *nextbutton;



- (IBAction)gotoBackView:(id)sender;
- (IBAction)gotoNextView:(id)sender;

@end
