//
//  ViewController.h
//  GLModelExample
//
//  Created by Nick Lockwood on 20/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. 
//

#import <UIKit/UIKit.h>
#import "GLModelView.h"
#import <GLKit/GLKit.h>
#import <string.h>


@interface LoadViewController : UIViewController <UIActionSheetDelegate>
{
    NSArray *objFiles;
    NSArray *jpgFiles;
}

@property (strong, nonatomic) IBOutlet UINavigationBar *LoadNavBar;
@property (strong, nonatomic) IBOutlet GLModelView *LoadModelView;
@property (weak, nonatomic) IBOutlet UILabel *appStatusLabel;

@property (weak, nonatomic) IBOutlet UISlider *modelXSlider;
@property (weak, nonatomic) IBOutlet UISlider *modelYSlider;
@property (weak, nonatomic) IBOutlet UISlider *modelZSlider;

@property (weak, nonatomic) IBOutlet UISlider *ScaleSlider;

- (IBAction)selectLoadModel;

- (IBAction)ModelXSliderValueChanged:(id)sender;
- (IBAction)ModelYSliderValueChanged:(id)sender;
- (IBAction)ModelZSliderValueChanged:(id)sender;
- (IBAction)ScaleSliderValueChanged:(id)sender;

//- (void)showAppStatusMessage:(NSString *)msg;
- (void) hideAppStatus:(UILabel*)label;
- (void)showAppStatus:(UILabel*)label msg:(NSString *)msg;

- (GLKMatrix4)matrixFrom3DTransformation:(CATransform3D)transform;
- (CATransform3D)matrixFromGLKMatrix:(GLKMatrix4)transform;

@end
