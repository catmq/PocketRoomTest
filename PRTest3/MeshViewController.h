/*
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
*/

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Structure/StructureSLAM.h>
#import "EAGLView.h"


@protocol MeshViewDelegate <NSObject>
- (void)meshViewWillDismiss;
- (void)meshViewDidDismiss;
- (void)meshViewDidRequestRegularMesh;
- (void)meshViewDidRequestHoleFilling;
@end

@interface MeshViewController : UIViewController <UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, assign) id<MeshViewDelegate> delegate;

@property (nonatomic) BOOL needsDisplay; // force the view to redraw.

@property (weak, nonatomic) IBOutlet UIView *modelview;
@property (weak, nonatomic) IBOutlet UISlider *modelOpacitySlider;


@property (weak, nonatomic) IBOutlet UILabel *meshViewerMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *measurementGuideLabel;

@property (weak, nonatomic) IBOutlet UISwitch *topViewSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *XRaySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *holeFillingSwitch;
@property (weak, nonatomic) IBOutlet UIButton *measurementButton;

@property (weak, nonatomic) IBOutlet UIButton *savemodelButton;
@property (weak, nonatomic) IBOutlet UIButton *sendmailButton;

- (IBAction)ModelOpacitySliderValueChanged:(id)sender;
- (IBAction)savemodelButtonPressed:(id)sender;
- (IBAction)sendmailButtonPressed:(id)sender;

- (IBAction)measurementButtonClicked:(id)sender;

- (IBAction)topViewSwitchChanged:(id)sender;
- (IBAction)holeFillingSwitchChanged:(id)sender;
- (IBAction)XRaySwitchChanged:(id)sender;

- (void)initMeshView;
- (void)showMeshViewerMessage:(UILabel*)label msg:(NSString *)msg;
- (void)hideMeshViewerMessage:(UILabel*)label;

- (void)uploadMesh:(STMesh *)meshRef;

- (void)setHorizontalFieldOfView:(float)fovXRadians aspectRatio:(float)aspectRatio;
- (void)setCameraPose:(GLKMatrix4)pose;

//for background from camera
//- (void) CameraSetOutputProperties;
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position;

@end
