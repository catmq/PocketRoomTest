//
//  ViewController.m
//  PRTest3
//
//  Created by Tsung-Yu Tsai on 2016/1/27.
//  Copyright © 2016年 Tsung-Yu Tsai. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
{
    // background from camera
    AVCaptureSession *CaptureSession;
    AVCaptureMovieFileOutput *MovieFileOutput;
    AVCaptureDeviceInput *VideoInputDevice;
}


@property (retain) AVCaptureVideoPreviewLayer *PreviewLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"ViewController viewDidLoad");
    
    
    ///
    NSLog(@"Setting up capture session");
    CaptureSession = [[AVCaptureSession alloc] init];
    
    //----- ADD INPUTS -----
    NSLog(@"Adding video input");
    
    //ADD VIDEO INPUT
    AVCaptureDevice *VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (VideoDevice)
    {
        NSError *error;
        VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
        if (!error)
        {
            if ([CaptureSession canAddInput:VideoInputDevice])
                [CaptureSession addInput:VideoInputDevice];
            else
                NSLog(@"Couldn't add video input");
        }
        else
        {
            NSLog(@"Couldn't create video input");
        }
    }
    else
    {
        NSLog(@"Couldn't create video capture device");
    }
    
    //----- ADD OUTPUTS -----
    
    //ADD VIDEO PREVIEW LAYER
    NSLog(@"Adding video preview layer");
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:CaptureSession]];
    
    self.PreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;		//<<SET ORIENTATION.  You can deliberatly set this wrong to flip the image and may actually need to set it wrong to get the right image
    
    [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //SET THE CONNECTION PROPERTIES (output properties)
    //[self CameraSetOutputProperties];			//(We call a method as it also has to be done after changing camera)
    
    
    /*
     //----- SET THE IMAGE QUALITY / RESOLUTION -----
     //Options:
     //	AVCaptureSessionPresetHigh - Highest recording quality (varies per device)
     //	AVCaptureSessionPresetMedium - Suitable for WiFi sharing (actual values may change)
     //	AVCaptureSessionPresetLow - Suitable for 3G sharing (actual values may change)
     //	AVCaptureSessionPreset640x480 - 640x480 VGA (check its supported before setting it)
     //	AVCaptureSessionPreset1280x720 - 1280x720 720p HD (check its supported before setting it)
     //	AVCaptureSessionPresetPhoto - Full photo resolution (not supported for video output)
     NSLog(@"Setting image quality");
     [CaptureSession setSessionPreset:AVCaptureSessionPresetMedium];
     if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480])		//Check size based configs are supported before setting them
     [CaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
     */
    
    //[self.view sendSubviewToBack:self.modelview];
    
    
    //----- DISPLAY THE PREVIEW LAYER -----
    //Display it full screen under out view controller existing controls
    NSLog(@"Display the preview layer");
    CGRect layerRect = [[[self view] layer] bounds];
    [[self PreviewLayer] setBounds:layerRect];
    [[self PreviewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                                 CGRectGetMidY(layerRect))];
    
    
    
    //[[[self view] layer] addSublayer:[[self CaptureManager] previewLayer]];
    //We use this instead so it goes on a layer behind our UI controls (avoids us having to manually bring each control to the front):
    UIView *CameraView = [[UIView alloc] init];
    //[self.view addSubview:CameraView  ];
    [self.view insertSubview:CameraView atIndex:0];
    [self.view sendSubviewToBack:CameraView];
    
    [[CameraView layer] addSublayer:[self PreviewLayer]];
    
    
    // add blur effect
    UIBlurEffect *blureffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    //UIBlurEffectStyleLight
    
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blureffect];
    effectView.frame = self.view.frame;

    [CameraView addSubview:effectView];
    
    //[[self.view layer] addSublayer:[self PreviewLayer]];
    
    
    
    
    //----- START THE CAPTURE SESSION RUNNING -----
    [CaptureSession startRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)gotoscanview:(id)sender
{
    /*
    UIStoryboard* _storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ScanViewController* SVcontroller = [_storyboard instantiateViewControllerWithIdentifier:@"ScanViewController"];
    
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:SVcontroller];
    */
    
    //AppDelegate * adele = [[UIApplication sharedApplication] delegate];
//    adele.window.rootViewController = SVcontroller;
//    [self presentViewController:SVcontroller animated:true completion:nil];
}
@end
